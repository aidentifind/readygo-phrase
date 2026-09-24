import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:readygo_phrase/data/api_client.dart';
import 'package:readygo_phrase/data/study_repository.dart';
import 'package:readygo_phrase/models/entry.dart';

/// POST /api/v1/users には常にダミートークンを返し、それ以外は [respond] に渡す。
ApiClient _apiWith(
  http.Response Function(http.Request request) respond, {
  List<http.Request>? requests,
}) {
  return ApiClient(
    client: MockClient((request) async {
      requests?.add(request);
      if (request.url.path == '/api/v1/users') {
        return http.Response(jsonEncode({'id': 'u1', 'token': 't'}), 201);
      }
      return respond(request);
    }),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('startSession はクライアント発行のUUIDと level/mode を送る', () async {
    final requests = <http.Request>[];
    final api = _apiWith(
      (request) => http.Response(jsonEncode({'id': 42}), 201),
      requests: requests,
    );
    final repo = StudyRepository(api: api);

    final session = await repo.startSession(
      level: PhraseLevel.toeicLt600,
      mode: StudyMode.study,
    );

    expect(session.id, 42);
    final sessionRequest = requests.firstWhere(
      (r) => r.url.path == '/api/v1/phrase/study_sessions',
    );
    final body = jsonDecode(sessionRequest.body) as Map<String, dynamic>;
    expect(body['level'], 'toeic_lt600');
    expect(body['mode'], 'study');
    expect(body['client_session_uuid'], isA<String>());
    expect((body['client_session_uuid'] as String).length, 36);
  });

  test('submitFlip は端末に保存してから送り、成功すると保存分を消す', () async {
    final requests = <http.Request>[];
    final api = _apiWith((request) => http.Response('{}', 201), requests: requests);
    final repo = StudyRepository(api: api);

    await repo.submitFlip(
      sessionId: 1,
      entryId: 'pick_up_01',
      result: StudyResult.known,
      revealedBeforeFlip: false,
      elapsedMs: 1200,
    );
    await repo.flush();

    final flipRequest = requests.firstWhere(
      (r) => r.url.path == '/api/v1/phrase/study_sessions/1/flips',
    );
    final body = jsonDecode(flipRequest.body) as Map<String, dynamic>;
    expect(body['entry_id'], 'pick_up_01');
    expect(body['result'], 'known');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('pending_flips'), isEmpty);
  });

  test('5xxや通信不可のときはキューに残り、次のflushで送り直す', () async {
    var attempt = 0;
    final api = _apiWith((request) {
      attempt++;
      return attempt == 1 ? http.Response('', 500) : http.Response('{}', 201);
    });
    final repo = StudyRepository(api: api);

    await repo.submitFlip(
      sessionId: 1,
      entryId: 'pick_up_01',
      result: StudyResult.unknown,
      revealedBeforeFlip: true,
      elapsedMs: 500,
    );
    // submitFlip自身もバックグラウンドでflush()を1回試みる(unawaited)。ここで明示的に
    // 待つことで、そのバックグラウンド分(1回目・500失敗)を確実に完了させてから検証する
    // (待たずに次のflush()を呼ぶと、進行中の1回目と合流して2回目が実質発生しないことがある)。
    await repo.flush();

    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('pending_flips'), hasLength(1));

    await repo.flush();
    prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('pending_flips'), isEmpty);
  });

  test('fetchReviewCandidates は保留分を送ってから復習対象のIDを返す', () async {
    final requests = <http.Request>[];
    final api = _apiWith((request) {
      if (request.url.path.endsWith('/flips')) return http.Response('{}', 201);
      return http.Response(
        jsonEncode({
          'unknown_entry_ids': ['pick_up_01'],
        }),
        200,
      );
    }, requests: requests);
    final repo = StudyRepository(api: api);

    await repo.submitFlip(
      sessionId: 1,
      entryId: 'give_up_01',
      result: StudyResult.unknown,
      revealedBeforeFlip: true,
      elapsedMs: 100,
    );

    final ids = await repo.fetchReviewCandidates(PhraseLevel.toeicLt600);

    expect(ids, ['pick_up_01']);
    expect(requests.any((r) => r.url.path.endsWith('/flips')), isTrue);
    final queueRequest = requests.firstWhere(
      (r) => r.url.path == '/api/v1/phrase/review_queue',
    );
    expect(queueRequest.url.queryParameters['level'], 'toeic_lt600');
  });
}
