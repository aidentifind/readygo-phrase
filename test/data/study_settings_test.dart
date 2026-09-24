import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:readygo_phrase/data/study_settings.dart';
import 'package:readygo_phrase/models/entry.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // revealSeconds/lastLevel はアプリ全体で共有するstatic状態(実機では1プロセス=1回の
    // load()なので問題にならないが、テストでは前のテストの値が残るのでここで戻す)。
    StudySettings.revealSeconds.value = StudySettings.defaultRevealSeconds;
    StudySettings.lastLevel = null;
  });

  test('load() は端末に保存した値を復元する', () async {
    SharedPreferences.setMockInitialValues({
      'reveal_seconds': 7,
      'last_level': PhraseLevel.toeic600700.apiValue,
    });

    await StudySettings.load();

    expect(StudySettings.revealSeconds.value, 7);
    expect(StudySettings.lastLevel, PhraseLevel.toeic600700);
  });

  test('保存が無ければ既定値のまま', () async {
    await StudySettings.load();

    expect(StudySettings.revealSeconds.value, StudySettings.defaultRevealSeconds);
    expect(StudySettings.lastLevel, isNull);
  });

  test('setRevealSeconds/setLastLevel は端末に保存する', () async {
    await StudySettings.load();

    await StudySettings.setRevealSeconds(5);
    await StudySettings.setLastLevel(PhraseLevel.toeic800900);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('reveal_seconds'), 5);
    expect(prefs.getString('last_level'), 'toeic_800_900');
  });
}
