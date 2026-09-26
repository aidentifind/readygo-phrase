import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob の初期化と、プライバシーに関する同意(UMP)の管理(CLAUDE.md 8章、readygo-speakと同じ)。
///
/// 同意フォームは UMP が必要と判断した地域(EEA・英国など)でだけ出る。
/// 同意の取得が終わり canRequestAds() が true になってから広告SDKを初期化し、
/// [ready] を立てる。バナー([BannerAdSlot])はこれを見て読み込みを始める。
///
/// 起動をブロックしないよう、main() では runApp の後に await せず呼ぶ。
/// テストやWebでは呼ばれないので、[ready] は false のまま(バナーは出ない)。
class AdsService {
  AdsService._();

  static final ValueNotifier<bool> ready = ValueNotifier(false);

  /// 同意を後から変更する入口を設定画面に出す必要があるか(EEA・英国など)。
  static final ValueNotifier<bool> privacyOptionsRequired = ValueNotifier(false);

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> init() async {
    if (!_supported) return;

    final updated = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        // 必要な地域でだけフォームが出る。閉じられるまで待つ。
        await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
        updated.complete();
      },
      // 通信できない等で更新に失敗しても、前回の同意状態で続ける。
      (_) => updated.complete(),
    );
    await updated.future;

    privacyOptionsRequired.value =
        await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;

    if (await ConsentInformation.instance.canRequestAds()) {
      await MobileAds.instance.initialize();
      ready.value = true;
    }
  }

  /// 設定画面の「広告のプライバシー設定」から呼ぶ。
  static void showPrivacyOptions() {
    unawaited(ConsentForm.showPrivacyOptionsForm((_) {}));
  }
}
