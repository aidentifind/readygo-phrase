import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'network_activity.dart';

/// サーバーから配る実行時設定(GET /api/v1/phrase/app_config)。
/// アプリを出し直さずに、強制アップデート・メンテナンス・広告のON/OFFなどを切り替える
/// (readygo-speak-api docs/app_config.md、ReadyGo Speakと同じ仕組み)。
///
/// 返ってこなかったキーは「制限なし」として扱う(古いサーバーや設定の入れ忘れで止めない)。
@immutable
class RemoteConfig {
  final String? minSupportedAppVersion;
  final String? latestAppVersion;
  final bool maintenance;
  final String? maintenanceMessage;
  final bool adsEnabled;
  final String? audioBaseUrl;

  const RemoteConfig({
    this.minSupportedAppVersion,
    this.latestAppVersion,
    this.maintenance = false,
    this.maintenanceMessage,
    this.adsEnabled = true,
    this.audioBaseUrl,
  });

  factory RemoteConfig.fromJson(Map<String, dynamic> json) {
    T? read<T>(Object? value) => value is T ? value : null;
    final maintenance = read<Map<String, dynamic>>(json['maintenance']);
    final ads = read<Map<String, dynamic>>(json['ads']);
    final audioBaseUrl = read<String>(json['audio_base_url']);
    return RemoteConfig(
      minSupportedAppVersion: read<String>(json['min_supported_app_version']),
      latestAppVersion: read<String>(json['latest_app_version']),
      maintenance: read<bool>(maintenance?['enabled']) ?? false,
      maintenanceMessage: read<String>(maintenance?['message']),
      adsEnabled: read<bool>(ads?['enabled']) ?? true,
      audioBaseUrl: audioBaseUrl != null && audioBaseUrl.startsWith('https://')
          ? audioBaseUrl.replaceFirst(RegExp(r'/+$'), '')
          : null,
    );
  }
}

/// 設定から決まる、アプリを使わせてよいかどうか。
enum AppGate {
  /// そのまま使える。
  open,

  /// 新しい版がある(案内するだけで、使い続けられる)。
  updateAvailable,

  /// この版はもう使えない。ストアで更新してもらう。
  updateRequired,

  /// メンテナンス中。
  maintenance,
}

/// 起動時と、アプリが前面に戻ったときに設定を取り直す。
///
/// 取れなかったとき(オフライン・タイムアウト・5xx)は学習を止めない。前回取れた値を
/// 端末に保存しておき、それで判定する。ただしメンテナンスだけは保存した値を使わない。
class RemoteConfigRepository {
  RemoteConfigRepository({http.Client? client})
    : _client = client ?? http.Client();

  static RemoteConfigRepository instance = RemoteConfigRepository();

  static const _cacheKey = 'remote_config.body';
  static const _timeout = Duration(seconds: 10);

  /// サーバー側のキャッシュ(max-age=60)と同じ。これより短い間隔で前面に戻っても取り直さない。
  static const _minInterval = Duration(seconds: 60);

  final http.Client _client;
  String? _appVersion;
  DateTime? _fetchedAt;

  final ValueNotifier<RemoteConfig> config = ValueNotifier(
    const RemoteConfig(),
  );
  final ValueNotifier<AppGate> gate = ValueNotifier(AppGate.open);

  /// 起動時に1回。端末に保存した前回の設定を読み込む(通信はしない)。
  Future<void> init() async {
    _appVersion ??= (await PackageInfo.fromPlatform()).version;
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached == null) return;
    try {
      final saved = RemoteConfig.fromJson(
        jsonDecode(cached) as Map<String, dynamic>,
      );
      _apply(
        RemoteConfig(
          minSupportedAppVersion: saved.minSupportedAppVersion,
          latestAppVersion: saved.latestAppVersion,
          adsEnabled: saved.adsEnabled,
          audioBaseUrl: saved.audioBaseUrl,
        ),
      );
    } catch (_) {
      await prefs.remove(_cacheKey); // 壊れた保存は捨てる
    }
  }

  /// サーバーから取り直す。[force] が false なら、直前に取ったばかりのときは何もしない。
  Future<void> refresh({bool force = false}) async {
    final last = _fetchedAt;
    if (!force &&
        last != null &&
        DateTime.now().difference(last) < _minInterval) {
      return;
    }
    try {
      final response = await NetworkActivity.track(
        () => _client
            .get(Uri.parse('${AppConfig.apiBaseUrl}/api/v1/phrase/app_config'))
            .timeout(_timeout),
      );
      if (response.statusCode != 200) return;
      final body = utf8.decode(response.bodyBytes);
      _apply(RemoteConfig.fromJson(jsonDecode(body) as Map<String, dynamic>));
      _fetchedAt = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, body);
    } catch (_) {
      // 取れなければ今の値のまま続ける。
    }
  }

  void _apply(RemoteConfig value) {
    config.value = value;
    gate.value = gateFor(value, _appVersion);
  }

  @visibleForTesting
  set appVersion(String version) => _appVersion = version;

  static AppGate gateFor(RemoteConfig config, String? appVersion) {
    bool olderThan(String? required) =>
        appVersion != null &&
        required != null &&
        compareVersions(appVersion, required) < 0;

    if (olderThan(config.minSupportedAppVersion)) return AppGate.updateRequired;
    if (config.maintenance) return AppGate.maintenance;
    if (olderThan(config.latestAppVersion)) return AppGate.updateAvailable;
    return AppGate.open;
  }
}

/// ドット区切りの数字として比べる("1.9.0" < "1.10.0")。足りない桁は0とみなす。
int compareVersions(String a, String b) {
  List<int> parts(String v) => [
    for (final p in v.split('.'))
      int.tryParse(RegExp(r'^\d+').stringMatch(p) ?? '') ?? 0,
  ];
  final x = parts(a);
  final y = parts(b);
  for (var i = 0; i < x.length || i < y.length; i++) {
    final d = (i < x.length ? x[i] : 0).compareTo(i < y.length ? y[i] : 0);
    if (d != 0) return d;
  }
  return 0;
}
