// レベル選択画面が起動し、モード選択画面に進めることを確認する最小限のスモークテスト。
//
// コンテンツ・学習記録はreadygo-speak-api(GET /api/v1/phrase/entries 等)から取得する
// 実装のため、実ネットワークには依存せず MockClient でAPIレスポンスを模擬する
// (readygo-speak/test/widget_test.dart と同じ方針)。

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:readygo_phrase/data/api_client.dart';
import 'package:readygo_phrase/data/entry_repository.dart';
import 'package:readygo_phrase/main.dart';
import 'package:readygo_phrase/models/entry.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// readygo-speak-api のユーザーごとのAPI(users・review_queue・study_sessions)の模擬。
http.Response _userApi(http.Request request) {
  if (request.url.path == '/api/v1/users') {
    return _json({'id': 'u1', 'token': 't1'}, 201);
  }
  if (request.url.path == '/api/v1/phrase/review_queue') {
    return _json({'unknown_entry_ids': []});
  }
  if (request.url.path == '/api/v1/phrase/study_sessions') {
    return _json({'id': 1}, 201);
  }
  if (request.url.path.endsWith('/flips')) {
    return _json({});
  }
  return http.Response('not found', 404);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.instance = ApiClient(client: MockClient((r) async => _userApi(r)));
    EntryRepository.instance = EntryRepository(
      client: MockClient(
        (request) async => _json([
          {
            'id': 'pick_up_01',
            'expression': 'pick up',
            'kind': 'phrasal_verb',
            'sense_no': 1,
            'level': request.url.queryParameters['level'],
            'meaning_ja': '拾い上げる',
            'separable': true,
            'register': 'neutral',
            'region': 'common',
            'examples': [
              {'en_text': 'Pick it up.', 'ja_text': 'それを拾って。', 'position': 1},
            ],
          },
        ]),
      ),
    );
  });

  testWidgets('レベル選択画面が起動時に表示される', (tester) async {
    await tester.pumpWidget(const ReadyGoPhraseApp());
    await tester.pump();

    expect(find.text('レベルを選んでください'), findsOneWidget);
    for (final level in PhraseLevel.values) {
      expect(find.text(level.label), findsOneWidget);
    }
  });

  testWidgets('レベルをタップするとモード選択画面に進む', (tester) async {
    await tester.pumpWidget(const ReadyGoPhraseApp());
    await tester.pump();

    await tester.tap(find.text(PhraseLevel.toeicLt600.label));
    await tester.pumpAndSettle();

    expect(find.text(StudyMode.study.actionLabel), findsOneWidget);
    expect(find.text(StudyMode.review.actionLabel), findsOneWidget);
  });
}
