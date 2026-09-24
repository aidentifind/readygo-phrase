import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/entry.dart';
import 'network_activity.dart';

/// コンテンツ(句動詞・熟語)を readygo-speak-api から取得するリポジトリ。
/// 認証は不要(レベル選択画面はユーザー発行より前に出るため)、ReadyGo Speakの
/// SentenceRepositoryと同じくETag(If-None-Match)で差分だけ受け取り、通信できないときは
/// 端末に保存してある分で学習できるようにする。
class EntryRepository {
  EntryRepository({http.Client? client}) : _client = client ?? http.Client();

  /// テストでは `EntryRepository.instance = EntryRepository(client: ...)` のように差し替える。
  static EntryRepository instance = EntryRepository();

  static const _timeout = Duration(seconds: 10);

  final http.Client _client;
  final Map<String, List<Entry>> _memory = {};

  /// [level] の全エントリ(公開済みのみ)。通信できず、端末にも保存が無ければ例外を投げる。
  Future<List<Entry>> fetch(PhraseLevel level) async {
    final key = 'entries_${level.apiValue}';
    final prefs = await SharedPreferences.getInstance();
    final cachedBody = prefs.getString('$key.body');
    final cachedEtag = prefs.getString('$key.etag');

    try {
      final uri = Uri.parse(
        '${AppConfig.apiBaseUrl}/api/v1/phrase/entries',
      ).replace(queryParameters: {'level': level.apiValue});
      final response = await NetworkActivity.track(
        () => _client
            .get(
              uri,
              headers: {
                if (cachedBody != null && cachedEtag != null)
                  'If-None-Match': cachedEtag,
              },
            )
            .timeout(_timeout),
      );

      if (response.statusCode == 304 && cachedBody != null) {
        return _memory[key] ??= _parse(cachedBody);
      }
      if (response.statusCode != 200) {
        throw HttpException('Failed to load entries: HTTP ${response.statusCode}');
      }

      final body = utf8.decode(response.bodyBytes);
      final entries = _parse(body);
      await prefs.setString('$key.body', body);
      final etag = response.headers['etag'];
      if (etag != null) {
        await prefs.setString('$key.etag', etag);
      } else {
        await prefs.remove('$key.etag');
      }
      return _memory[key] = entries;
    } catch (_) {
      final fallback =
          _memory[key] ?? (cachedBody != null ? _parse(cachedBody) : null);
      if (fallback != null) return fallback;
      rethrow;
    }
  }

  static List<Entry> _parse(String body) =>
      (jsonDecode(body) as List<dynamic>)
          .map((e) => Entry.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);

  @override
  String toString() => message;
}
