import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:readygo_phrase/data/entry_repository.dart';
import 'package:readygo_phrase/data/network_activity.dart';
import 'package:readygo_phrase/models/entry.dart';

Map<String, dynamic> _json(String id, String expression) => {
  'id': id,
  'expression': expression,
  'kind': 'phrasal_verb',
  'sense_no': 1,
  'level': PhraseLevel.toeicLt600.apiValue,
  'meaning_ja': 'テスト',
  'separable': true,
  'register': 'neutral',
  'region': 'common',
  'examples': [
    {'en_text': 'Test.', 'ja_text': 'テスト。', 'position': 1},
  ],
};

/// 日本語を含む本文は、バイト列 + charset 指定で返す(文字列のままだと latin1 扱いで失敗する)。
http.Response _ok(String body, {Map<String, String> headers = const {}}) =>
    http.Response.bytes(
      utf8.encode(body),
      200,
      headers: {'content-type': 'application/json; charset=utf-8', ...headers},
    );

void main() {
  late List<http.Request> requests;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    requests = [];
  });

  EntryRepository repository(http.Response Function(http.Request request) respond) =>
      EntryRepository(
        client: MockClient((request) async {
          requests.add(request);
          return respond(request);
        }),
      );

  test('レベルで絞って取得し、次回は ETag で確かめる', () async {
    final body = jsonEncode([_json('pick_up_01', 'pick up')]);
    final repo = repository(
      (request) => request.headers['If-None-Match'] == '"v1"'
          ? http.Response('', 304)
          : _ok(body, headers: {'etag': '"v1"'}),
    );

    final first = await repo.fetch(PhraseLevel.toeicLt600);
    expect(first.single.id, 'pick_up_01');
    expect(requests.single.url.queryParameters, {'level': 'toeic_lt600'});

    // アプリを開き直した(メモリは空)想定でも、保存した本文と ETag で 304 を受ける。
    final reopened = repository(
      (request) => request.headers['If-None-Match'] == '"v1"'
          ? http.Response('', 304)
          : http.Response('[]', 200),
    );
    final second = await reopened.fetch(PhraseLevel.toeicLt600);
    expect(requests.last.headers['If-None-Match'], '"v1"');
    expect(second.single.expression, 'pick up');
    expect(second.single.examples.single.enText, 'Test.');
  });

  test('通信できないときは前に取った分を使い、それも無ければ例外', () async {
    final body = jsonEncode([_json('pick_up_01', 'pick up')]);
    await repository((_) => _ok(body)).fetch(PhraseLevel.toeicLt600);

    final offline = repository((_) => throw http.ClientException('offline'));
    expect(
      (await offline.fetch(PhraseLevel.toeicLt600)).single.id,
      'pick_up_01',
    );
    await expectLater(
      offline.fetch(PhraseLevel.toeic800900),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('取得中は「通信中」になり、終わると戻る', () async {
    final response = Completer<http.Response>();
    final repo = EntryRepository(client: MockClient((_) => response.future));

    final pending = repo.fetch(PhraseLevel.toeicLt600);
    await pumpEventQueue();
    expect(NetworkActivity.busy.value, isTrue);

    response.complete(_ok('[]'));
    await pending;
    // ローカル環境のような瞬時の通信でも利用者に見えるよう、消灯には最低表示時間を
    // 設けている(NetworkActivity._minVisible)。それを待ってから戻ったことを確認する。
    await Future.delayed(const Duration(milliseconds: 600));
    expect(NetworkActivity.busy.value, isFalse);
  });
}
