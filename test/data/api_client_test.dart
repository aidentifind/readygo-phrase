import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:readygo_phrase/data/api_client.dart';

import '../fake_credential_storage.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ApiClient client({
    required FakeCredentialStorage storage,
    required List<http.Request> requests,
    int userStatus = 201,
    String token = 't1',
  }) {
    return ApiClient(
      storage: storage,
      client: MockClient((request) async {
        requests.add(request);
        return switch (request.url.path) {
          '/api/v1/users' =>
            http.Response(jsonEncode({'token': token}), userStatus),
          _ => http.Response('{}', 200),
        };
      }),
    );
  }

  test('新規発行したトークンを安全な保存先に書き込む(SharedPreferencesには残さない)', () async {
    final storage = FakeCredentialStorage();
    final requests = <http.Request>[];
    final api = client(storage: storage, requests: requests);

    await api.get('/api/v1/phrase/progress');

    expect(requests.last.headers['Authorization'], 'Bearer t1');
    expect(await storage.read(), 't1');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('api_token'), isNull);
  });

  test('旧版(SharedPreferences)のトークンを安全な保存先に移行し、旧版からは削除する', () async {
    SharedPreferences.setMockInitialValues({'api_token': 'legacy-token'});
    final storage = FakeCredentialStorage();
    final requests = <http.Request>[];
    final api = client(storage: storage, requests: requests);

    await api.get('/api/v1/phrase/progress');

    expect(requests.single.headers['Authorization'], 'Bearer legacy-token');
    expect(requests.where((r) => r.url.path == '/api/v1/users'), isEmpty);
    expect(await storage.read(), 'legacy-token');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('api_token'), isNull);
  });

  test('移行が完了せず両方の保存先に値がある状態で起動しても、安全な保存先の値を使い旧版を削除する', () async {
    SharedPreferences.setMockInitialValues({'api_token': 'legacy-token'});
    final storage = FakeCredentialStorage();
    await storage.write('migrated-token');
    final requests = <http.Request>[];
    final api = client(storage: storage, requests: requests);

    await api.get('/api/v1/phrase/progress');

    expect(requests.single.headers['Authorization'], 'Bearer migrated-token');
    expect(requests.where((r) => r.url.path == '/api/v1/users'), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('api_token'), isNull);
  });

  test('401のときは保存先のトークンを捨てて再発行する', () async {
    final storage = FakeCredentialStorage();
    await storage.write('stale-token');
    final requests = <http.Request>[];
    var progressCalls = 0;
    final api = ApiClient(
      storage: storage,
      client: MockClient((request) async {
        requests.add(request);
        return switch (request.url.path) {
          '/api/v1/users' => http.Response(jsonEncode({'token': 'new-token'}), 201),
          '/api/v1/phrase/progress' => http.Response(
              '{}', (++progressCalls == 1) ? 401 : 200),
          _ => http.Response('{}', 200),
        };
      }),
    );

    final response = await api.get('/api/v1/phrase/progress');

    expect(response.statusCode, 200);
    expect(await storage.read(), 'new-token');
    expect(
      requests
          .where((r) => r.url.path == '/api/v1/phrase/progress')
          .map((r) => r.headers['Authorization']),
      ['Bearer stale-token', 'Bearer new-token'],
    );
  });
}
