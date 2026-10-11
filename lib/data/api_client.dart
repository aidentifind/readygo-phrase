import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'credential_storage.dart';
import 'network_activity.dart';

/// readygo-speak-api の、ユーザーごとのデータを扱うAPI(study_sessions・review_queue・progress)の呼び出し。
///
/// 初回に匿名ユーザーを発行し(POST /api/v1/users、ReadyGo Speakと共通のエンドポイント)、
/// 返ってきたトークンを端末に保存して、以降は `Authorization: Bearer` で送る。
/// トークンは発行時にしか返らない。
///
/// サーバー側でユーザーが見つからない(401)ときは、トークンを捨てて発行し直す。
/// その場合、それまでの学習記録は引き継げない。
///
/// トークンは iOS Keychain / Android Keystore(flutter_secure_storage)に保存する
/// (Security issue #3)。旧版(SharedPreferences平文保存)からは初回アクセス時に移行し、
/// 移行後は旧値を削除する。
class ApiClient {
  ApiClient({http.Client? client, TokenStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? const SecureTokenStorage();

  /// テストでは `ApiClient.instance = ApiClient(client: MockClient(...))` で差し替える。
  static ApiClient instance = ApiClient();

  static const _legacyTokenKey = 'api_token';
  static const _timeout = Duration(seconds: 10);

  final http.Client _client;
  final TokenStorage _storage;
  String? _token;
  Future<String>? _registering;

  Future<http.Response> get(String path, {Map<String, dynamic>? query}) =>
      _send((headers) => _client.get(_uri(path, query), headers: headers));

  Future<http.Response> post(String path, Map<String, dynamic> body) => _send(
    (headers) => _client.post(
      _uri(path, null),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ),
  );

  /// アプリ起動時に呼んでおくと、初回の学習でユーザー発行を待たずに済む。
  Future<void> warmUp() => _ensureToken().then((_) {}, onError: (_) {});

  Future<http.Response> _send(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    for (var attempt = 0; ; attempt++) {
      final token = await _ensureToken();
      final response = await NetworkActivity.track(
        () => request({'Authorization': 'Bearer $token'}).timeout(_timeout),
      );
      if (response.statusCode == 401 && attempt == 0) {
        await _forgetToken();
        continue;
      }
      return response;
    }
  }

  Future<String> _ensureToken() async {
    final cached = _token;
    if (cached != null) return cached;

    final saved = await _storage.read();
    if (saved != null) {
      // 前回、安全な保存先への書き込み後に旧版の削除まで完了しなかった場合に備えて
      // 毎回削除を試みる(無ければ何もしない)。
      await _deleteLegacyToken();
      return _token = saved;
    }

    final migrated = await _migrateLegacyToken();
    if (migrated != null) return _token = migrated;

    // 同時に複数の呼び出しが来ても、発行は1回だけにする。
    return _registering ??= _register().whenComplete(() => _registering = null);
  }

  Future<void> _deleteLegacyToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyTokenKey);
  }

  // 旧版(SharedPreferences平文保存)のトークンを見つけたら安全な保存先に移し、
  // 旧版の値は削除する。
  Future<String?> _migrateLegacyToken() async {
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_legacyTokenKey);
    if (legacy == null) return null;

    await _storage.write(legacy);
    await prefs.remove(_legacyTokenKey);
    return legacy;
  }

  Future<String> _register() async {
    final response = await NetworkActivity.track(
      () => _client.post(_uri('/api/v1/users', null)).timeout(_timeout),
    );
    if (response.statusCode != 201) {
      throw ApiException('Failed to register: HTTP ${response.statusCode}');
    }
    final token =
        (jsonDecode(response.body) as Map<String, dynamic>)['token'] as String;
    await _storage.write(token);
    return _token = token;
  }

  Future<void> _forgetToken() async {
    _token = null;
    await _storage.delete();
  }

  static Uri _uri(String path, Map<String, dynamic>? query) =>
      Uri.parse('${AppConfig.apiBaseUrl}$path').replace(queryParameters: query);
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
