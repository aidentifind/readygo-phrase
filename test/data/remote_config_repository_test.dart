import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:readygo_phrase/data/remote_config_repository.dart';

void main() {
  late Object? response; // Map ならその本文で200、int ならそのステータス、null なら通信失敗

  RemoteConfigRepository repository() => RemoteConfigRepository(
    client: MockClient((request) async {
      final r = response;
      if (r == null) throw http.ClientException('offline');
      if (r is int) return http.Response('', r);
      return http.Response.bytes(utf8.encode(jsonEncode(r)), 200);
    }),
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'ReadyGo Phrase',
      packageName: 'space.readygo_english.phrase',
      version: '1.2.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  test('バージョンはドット区切りの数字として比べる', () {
    expect(compareVersions('1.9.0', '1.10.0'), lessThan(0));
    expect(compareVersions('1.10.0', '1.9.0'), greaterThan(0));
    expect(compareVersions('1.0', '1.0.0'), 0);
  });

  test('強制アップデート > メンテナンス > 任意アップデートの順に判定する', () {
    AppGate gate(RemoteConfig c) => RemoteConfigRepository.gateFor(c, '1.2.0');

    expect(gate(const RemoteConfig()), AppGate.open);
    expect(
      gate(const RemoteConfig(latestAppVersion: '1.3.0')),
      AppGate.updateAvailable,
    );
    expect(
      gate(const RemoteConfig(latestAppVersion: '1.3.0', maintenance: true)),
      AppGate.maintenance,
    );
    expect(
      gate(
        const RemoteConfig(minSupportedAppVersion: '1.10.0', maintenance: true),
      ),
      AppGate.updateRequired,
    );
  });

  test('サーバーの設定を読み、無いキーは制限なしとして扱う', () async {
    final repo = repository();
    await repo.init();
    response = {
      'min_supported_app_version': '1.0.0',
      'latest_app_version': '1.3.0',
      'maintenance': {'enabled': false, 'message': null},
      'ads': {'enabled': false},
      'audio_base_url': 'https://cdn.example.com/',
    };
    await repo.refresh();

    expect(repo.gate.value, AppGate.updateAvailable);
    expect(repo.config.value.adsEnabled, isFalse);
    expect(repo.config.value.audioBaseUrl, 'https://cdn.example.com');
  });

  test('取れないときは前回の値のまま。次の起動でも保存した値で判定する', () async {
    response = {
      'min_supported_app_version': '2.0.0',
      'maintenance': {'enabled': true, 'message': 'メンテナンス中'},
    };
    final first = repository();
    await first.init();
    await first.refresh();
    expect(first.gate.value, AppGate.updateRequired);

    // 次の起動(オフライン)。古い版は止めたままにするが、メンテナンスは持ち越さない。
    response = null;
    final next = repository();
    await next.init();
    await next.refresh();
    expect(next.gate.value, AppGate.updateRequired);
    expect(next.config.value.maintenance, isFalse);
  });

  test('http の配信元は受け取らない', () {
    final config = RemoteConfig.fromJson({
      'audio_base_url': 'http://cdn.example.com',
    });
    expect(config.audioBaseUrl, isNull);
  });
}
