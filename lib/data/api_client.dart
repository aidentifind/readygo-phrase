import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'network_activity.dart';

/// readygo-speak-api の、ユーザーごとのデータを扱うAPI(study_sessions・review_queue・progress)の呼び出し。
///
/// 初回に匿名ユーザーを発行し(POST /api/v1/users、ReadyGo Speakと共通のエンドポイント)、
/// 返ってきたトークンを端末に保存して、以降は `Authorization: Bearer` で送る。
/// トークンは発行時にしか返らない。
///
/// サーバー側でユーザーが見つからない(401)ときは、トークンを捨てて発行し直す。
/// その場合、それまでの学習記録は引き継げない。
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// テストでは `ApiClient.instance = ApiClient(client: MockClient(...))` で差し替える。
  static ApiClient instance = ApiClient();

  static const _tokenKey = 'api_token';
  static const _timeout = Duration(seconds: 10);

  final http.Client _client;
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

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_tokenKey);
    if (saved != null) return _token = saved;

    // 同時に複数の呼び出しが来ても、発行は1回だけにする。
    return _registering ??= _register().whenComplete(() => _registering = null);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    return _token = token;
  }

  Future<void> _forgetToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
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
