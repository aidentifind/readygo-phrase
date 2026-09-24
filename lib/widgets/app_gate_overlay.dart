import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../data/remote_config_repository.dart';
import '../theme/app_colors.dart';

/// サーバーの設定(GET /api/v1/phrase/app_config)に従って、アプリの上に重ねる画面。
/// ReadyGo Speakのwidgets/app_gate_overlay.dartと同じ仕組み(readygo-speak-api docs/app_config.md)。
///
/// - 強制アップデート・メンテナンス: 全面を覆って学習を止める。学習中ならカード画面を閉じる
/// - 任意アップデート: レベル選択画面にいるときに1回だけダイアログで案内する(版ごとに1回)
class AppGateOverlay extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const AppGateOverlay({super.key, required this.navigatorKey});

  @override
  State<AppGateOverlay> createState() => _AppGateOverlayState();
}

class _AppGateOverlayState extends State<AppGateOverlay> {
  static const _dismissedKey = 'update_prompt_dismissed_version';

  late final AppLifecycleListener _lifecycle;
  RemoteConfigRepository get _repo => RemoteConfigRepository.instance;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _repo.refresh);
    _repo.gate.addListener(_onGateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onGateChanged());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _repo.gate.removeListener(_onGateChanged);
    super.dispose();
  }

  void _onGateChanged() {
    switch (_repo.gate.value) {
      case AppGate.updateRequired || AppGate.maintenance:
        widget.navigatorKey.currentState?.popUntil((route) => route.isFirst);
      case AppGate.updateAvailable:
        _maybePromptUpdate();
      case AppGate.open:
        break;
    }
  }

  Future<void> _maybePromptUpdate() async {
    final latest = _repo.config.value.latestAppVersion;
    final navigator = widget.navigatorKey.currentState;
    if (latest == null || navigator == null || navigator.canPop()) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_dismissedKey) == latest) return;
    await prefs.setString(_dismissedKey, latest);

    final context = widget.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    final storeUrl = AppConfig.storeUrl;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新しいバージョンがあります'),
        content: Text(
          storeUrl == null
              ? 'App Store から最新版($latest)に更新できます。'
              : '最新版($latest)に更新できます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('あとで'),
          ),
          if (storeUrl != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openStore(storeUrl);
              },
              child: const Text('アップデート'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppGate>(
      valueListenable: _repo.gate,
      builder: (context, gate, _) => switch (gate) {
        AppGate.updateRequired => _BlockingScreen(
          title: 'アップデートしてください',
          message: AppConfig.storeUrl == null
              ? 'このバージョンは使えなくなりました。App Store から最新版に更新してください。'
              : 'このバージョンは使えなくなりました。最新版に更新してください。',
          actionLabel: AppConfig.storeUrl == null ? null : 'アップデート',
          onAction: () => _openStore(AppConfig.storeUrl!),
        ),
        AppGate.maintenance => _BlockingScreen(
          title: 'メンテナンス中です',
          message:
              _repo.config.value.maintenanceMessage ?? 'しばらくしてからもう一度お試しください。',
          actionLabel: 'もう一度試す',
          onAction: () => _repo.refresh(force: true),
        ),
        AppGate.open || AppGate.updateAvailable => const SizedBox.shrink(),
      },
    );
  }

  static Future<void> _openStore(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      // ストアを開けない端末。画面はそのまま(もう一度押せる)。
    }
  }
}

/// 学習を止めるときの全面の画面。下の画面は触れない。
class _BlockingScreen extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback onAction;

  const _BlockingScreen({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    return Material(
      color: AppColors.paper,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ReadyGo Phrase専用のロゴ素材はまだ無いため、アイコンで代用している
                // (readygo-speakのブランド刷新と同じ「Speak A」マークはSpeak専用の意匠)。
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.style_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    height: 1.6,
                  ),
                ),
                if (label != null) ...[
                  const SizedBox(height: 32),
                  FilledButton(onPressed: onAction, child: Text(label)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
