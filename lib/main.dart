import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';

import 'ads/ads_service.dart';
import 'data/api_client.dart';
import 'data/remote_config_repository.dart';
import 'data/study_repository.dart';
import 'data/study_settings.dart';
import 'screens/level_select_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/app_gate_overlay.dart';
import 'widgets/network_activity_indicator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StudySettings.load();
  // 発音の再生(card_screen.dart)が使うAVAudioSessionのカテゴリ設定。これをしないと
  // iOSでは既定の ambient カテゴリのままになり、音量が小さく消音スイッチの影響も受ける
  // (readygo-speakのAudioSessionConfiguration.speech()と同じ設定)。
  await AudioSession.instance.then((s) => s.configure(const AudioSessionConfiguration.speech()));
  // 前回取れた設定で先に判定しておく(オフラインで起動した古い版も止められるように)。
  await RemoteConfigRepository.instance.init();
  runApp(const ReadyGoPhraseApp());
  // 強制アップデート・メンテナンスの判定。取れなくても学習は止めない。
  unawaited(RemoteConfigRepository.instance.refresh());
  // 同意フォームの表示に画面が要るため runApp の後。起動は待たせない。
  unawaited(AdsService.init());
  // 匿名ユーザーを先に発行しておき、前回送れなかったフリップがあれば送る。
  unawaited(ApiClient.instance.warmUp().then((_) => StudyRepository.instance.flush()));
}

class ReadyGoPhraseApp extends StatelessWidget {
  const ReadyGoPhraseApp({super.key});

  static final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'ReadyGo Phrase',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // レベル選択画面は毎回表示する(readygo-speak-api docs/HANDOVER.md 2.1章)。
      home: const LevelSelectScreen(),
      // 強制アップデート・メンテナンス中は全面を覆う。
      // API と通信している間は、どの画面でも右上に「通信中」を出す。
      builder: (context, child) => Stack(
        children: [
          child ?? const SizedBox.shrink(),
          AppGateOverlay(navigatorKey: _navigatorKey),
          const NetworkActivityIndicator(),
        ],
      ),
    );
  }
}
