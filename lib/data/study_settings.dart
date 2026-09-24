import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/entry.dart';

/// 学習の設定(端末に保存。readygo-speak-api docs/HANDOVER.md 2.5章「意味表示までの秒数」)。
/// サーバー同期はしない(§6 未決事項6の回答: ログイン不要・匿名前提なのでローカル保存のみで十分)。
class StudySettings {
  StudySettings._();

  static const revealSecondsMin = 1;
  static const revealSecondsMax = 10;
  static const defaultRevealSeconds = 3;

  static const _revealSecondsKey = 'reveal_seconds';
  static const _lastLevelKey = 'last_level';

  /// 画面表示から意味を見せるまでの秒数。
  static final ValueNotifier<int> revealSeconds = ValueNotifier(
    defaultRevealSeconds,
  );

  /// 前回選択したレベル。レベル選択画面は毎回表示するが(§2.1)、これをデフォルトで
  /// ハイライトしておくと選び直しの手間が減る(【提案】)。
  static PhraseLevel? lastLevel;

  static SharedPreferences? _prefs;

  /// runApp の前に一度だけ呼ぶ。呼ばない場合(テスト)は既定値のまま。
  static Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final savedSeconds = _prefs!.getInt(_revealSecondsKey);
    if (savedSeconds != null &&
        savedSeconds >= revealSecondsMin &&
        savedSeconds <= revealSecondsMax) {
      revealSeconds.value = savedSeconds;
    }

    final savedLevel = _prefs!.getString(_lastLevelKey);
    for (final level in PhraseLevel.values) {
      if (level.apiValue == savedLevel) {
        lastLevel = level;
        break;
      }
    }
  }

  static Future<void> setRevealSeconds(int seconds) async {
    assert(seconds >= revealSecondsMin && seconds <= revealSecondsMax);
    revealSeconds.value = seconds;
    await _prefs?.setInt(_revealSecondsKey, seconds);
  }

  static Future<void> setLastLevel(PhraseLevel level) async {
    lastLevel = level;
    await _prefs?.setString(_lastLevelKey, level.apiValue);
  }
}
