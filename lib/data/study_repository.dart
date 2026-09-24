import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/entry.dart';
import 'api_client.dart';

/// サーバー側に作られた学習/復習セッション(POST /api/v1/phrase/study_sessions)。
class StudySession {
  final int id;
  final PhraseLevel level;
  final StudyMode mode;

  const StudySession({required this.id, required this.level, required this.mode});
}

/// セッションの開始(POST /api/v1/phrase/study_sessions)とフリップの送信
/// (POST /api/v1/phrase/study_sessions/:id/flips)、復習対象の取得
/// (GET /api/v1/phrase/review_queue)。
///
/// フリップの送信はReadyGo SpeakのReviewRepositoryと同じく、端末に保存してから
/// 順番に送る(通信できないときも消えず、次に送れるときに送り直す)。
/// セッションの開始はカード画面に進む前に必要な軽い呼び出しなので、こちらは
/// オフラインキューにせず、失敗したら呼び出し元でエラーとして扱う。
class StudyRepository {
  StudyRepository({ApiClient? api}) : _apiOverride = api;

  static StudyRepository instance = StudyRepository();

  static const _pendingKey = 'pending_flips';

  final ApiClient? _apiOverride;
  ApiClient get _api => _apiOverride ?? ApiClient.instance;

  Future<void>? _flushing;

  Future<StudySession> startSession({
    required PhraseLevel level,
    required StudyMode mode,
  }) async {
    final response = await _api.post('/api/v1/phrase/study_sessions', {
      'client_session_uuid': _generateUuid(),
      'level': level.apiValue,
      'mode': mode.apiValue,
    });
    if (response.statusCode != 201) {
      throw ApiException('Failed to start session: HTTP ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return StudySession(id: body['id'] as int, level: level, mode: mode);
  }

  Future<void> submitFlip({
    required int sessionId,
    required String entryId,
    required StudyResult result,
    required bool revealedBeforeFlip,
    required int elapsedMs,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_pendingKey) ?? [];
    pending.add(
      jsonEncode({
        'session_id': sessionId,
        'entry_id': entryId,
        'result': result.apiValue,
        'revealed_before_flip': revealedBeforeFlip,
        'elapsed_ms': elapsedMs,
      }),
    );
    await prefs.setStringList(_pendingKey, pending);
    unawaited(flush());
  }

  /// 保存してあるフリップを送る。送り終わる(または通信できずに止まる)と完了する。
  Future<void> flush() => _flushing ??= _flush().whenComplete(() {
    _flushing = null;
  });

  Future<void> _flush() async {
    final prefs = await SharedPreferences.getInstance();
    while (true) {
      final pending = prefs.getStringList(_pendingKey) ?? [];
      if (pending.isEmpty) return;

      final item = jsonDecode(pending.first) as Map<String, dynamic>;
      try {
        final response = await _api.post(
          '/api/v1/phrase/study_sessions/${item['session_id']}/flips',
          {
            'entry_id': item['entry_id'],
            'result': item['result'],
            'revealed_before_flip': item['revealed_before_flip'],
            'elapsed_ms': item['elapsed_ms'],
          },
        );
        // 5xx は一時的な失敗とみなして次回に回す。4xx(不正な値・セッションが無い等)は
        // 何度送っても通らないので捨てる(残すと後ろのフリップが永久に送れなくなる)。
        if (response.statusCode >= 500) return;
      } catch (_) {
        return; // 通信できない。次回に送る。
      }

      final latest = prefs.getStringList(_pendingKey) ?? [];
      await prefs.setStringList(_pendingKey, latest.skip(1).toList());
    }
  }

  /// [level] のうち、過去に「わからない」判定になったエントリのID(復習モードの対象、
  /// readygo-speak-api docs/HANDOVER.md 2.2章。レベル内限定)。
  Future<List<String>> fetchReviewCandidates(PhraseLevel level) async {
    await flush();
    final response = await _api.get(
      '/api/v1/phrase/review_queue',
      query: {'level': level.apiValue},
    );
    if (response.statusCode != 200) {
      throw ApiException('Failed to load review queue: HTTP ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['unknown_entry_ids'] as List<dynamic>).cast<String>();
  }

  static final _random = Random.secure();

  static String _generateUuid() {
    // RFC 4122 v4形式の簡易実装(冪等キーとして使うだけなので外部パッケージは足さない)。
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int start, int end) =>
        bytes.sublist(start, end).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }
}
