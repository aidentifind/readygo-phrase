import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kReleaseMode;

/// AdMobの広告ユニット(CLAUDE.md 8章: バナーのみ、readygo-speakと同じ方針)。
///
/// リリースビルド以外は必ずGoogleのテスト用IDを使う。開発中に本番の広告を
/// 表示・タップすると無効なトラフィックと判定され、アカウント停止の対象になるため。
/// アプリID(`~`区切り)は AndroidManifest.xml / Info.plist に書いてある。
class AdConfig {
  AdConfig._();

  /// カード画面(学習・復習)の上部。下部に「覚えている/わからない」ボタンがあり、
  /// 近くに置くと誤タップ誘発でAdMobポリシー違反になりやすいため上に置く。
  static String get studyTopBanner => _pick(
    android: 'ca-app-pub-5922624949407858/1804857011',
    ios: 'ca-app-pub-5922624949407858/5568842204',
  );

  /// レベル選択・モード選択・履歴・設定の下部。
  static String get bottomBanner => _pick(
    android: 'ca-app-pub-5922624949407858/3105581966',
    ios: 'ca-app-pub-5922624949407858/8087369347',
  );

  // https://developers.google.com/admob/android/test-ads#demo_ad_units
  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/9214589741';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2435281174';

  /// [android]/[ios] を渡さなければ常にテスト用ID。渡した場合もリリースビルドでしか使わない
  /// (Info.plist の GADApplicationIdentifier も本番IDにしてあること)。
  static String _pick({String? android, String? ios}) {
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final release = isIos ? ios : android;
    if (kReleaseMode && release != null) return release;
    return isIos ? _testBannerIos : _testBannerAndroid;
  }
}
