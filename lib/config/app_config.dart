import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode;

/// アプリ全体で参照するエンドポイント設定。
/// readygo-speak-api を ReadyGo Speak と共有する(docs/HANDOVER.md、readygo-speak-api README参照)。
class AppConfig {
  AppConfig._();

  /// デバッグビルドはローカルのRails開発サーバー(readygo-speak-api、docker-compose、
  /// ホスト側ポート3001)を指す。ReadyGo Speakと同じAPIを共有しているため、
  /// ポート番号もSpeak側の設定(readygo-speak/lib/config/app_config.dart)と一致させること。
  /// - Web/macOS/iOSシミュレータ: `localhost` でホストマシンに到達できる
  /// - Androidエミュレータ: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3001`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultApiBaseUrl,
  );

  static const String _defaultApiBaseUrl =
      kDebugMode ? 'http://localhost:3001' : 'https://api.readygo-english.space';

  /// 発音音声のCDN配信元(readygo-speak-api docs/HANDOVER.md 3.1章 `audio_checksum`、
  /// readygo-speak-api README「音声(TTS)パイプライン」参照)。ReadyGo Speakと同じCDNを使う。
  static const String cdnBaseUrl = String.fromEnvironment(
    'CDN_BASE_URL',
    defaultValue: 'https://cdn.readygo-english.space',
  );

  /// 設定画面「このアプリについて」のリンク先。
  /// 【提案】readygo-english.space/phrase/ はReadyGo Speakの /speak/ に倣った想定パスで、
  /// サイト側(readygo-speak-api/site/)にまだ用意していない。実際に公開してから確定させること。
  static const String siteUrl = 'https://readygo-english.space/phrase/';
  static const String operatorName = 'aidentifind';
  static const String operatorUrl = 'https://aidentifind.jp';

  /// アップデートの案内(GET /api/v1/phrase/app_config)から開くストアのページ。
  /// 【提案】パッケージ名/Bundle IDはReadyGo Speak(space.readygo_english.speak /
  /// space.readygo-english.speak)の命名規則を踏襲した想定値。ストアにアプリを作るまでは仮。
  static String? get storeUrl => defaultTargetPlatform == TargetPlatform.iOS
      ? null
      : 'https://play.google.com/store/apps/details?id=space.readygo_english.phrase';

  /// プライバシーポリシーのURL。決まるまでは null(設定画面に項目を出さない)。
  static const String? privacyPolicyUrl = null;
}
