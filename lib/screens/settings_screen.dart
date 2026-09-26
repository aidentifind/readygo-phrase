import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ads/ads_service.dart';
import '../ads/banner_ad_slot.dart';
import '../config/ad_config.dart';
import '../config/app_config.dart';
import '../data/study_settings.dart';
import '../theme/app_colors.dart';

/// 設定画面(readygo-speak-api docs/HANDOVER.md 2.5章)。
/// 項目は「意味表示までの秒数」のみが【決定】。あとはreadygo-speakの設定画面に倣い、
/// 「このアプリについて」を添えている。
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      // バナーは画面下部(CLAUDE.md 8章)。広告が無いときは高さ0になる。
      bottomNavigationBar: BannerAdSlot(adUnitId: AdConfig.bottomBanner),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            const _SectionTitle('意味表示までの秒数'),
            const SizedBox(height: 4),
            const Text(
              'カードを表示してから、意味が表示されるまでの時間',
              style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<int>(
              valueListenable: StudySettings.revealSeconds,
              builder: (context, seconds, _) => Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: seconds.toDouble(),
                      min: StudySettings.revealSecondsMin.toDouble(),
                      max: StudySettings.revealSecondsMax.toDouble(),
                      divisions:
                          StudySettings.revealSecondsMax - StudySettings.revealSecondsMin,
                      label: '$seconds秒',
                      onChanged: (value) =>
                          StudySettings.setRevealSeconds(value.round()),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '$seconds秒',
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // EEA・英国など、広告の同意を後から変更できる入口が必要な地域でだけ出す
            // (UMPの要件。CLAUDE.md 8章、readygo-speakと同じ)。
            ValueListenableBuilder<bool>(
              valueListenable: AdsService.privacyOptionsRequired,
              builder: (context, required, _) => required
                  ? const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.privacy_tip_outlined),
                      title: Text('広告のプライバシー設定'),
                      onTap: AdsService.showPrivacyOptions,
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 32),
            const _SectionTitle('このアプリについて'),
            const SizedBox(height: 4),
            const _LinkTile(
              icon: Icons.public_rounded,
              title: '公式サイト',
              url: AppConfig.siteUrl,
            ),
            if (AppConfig.privacyPolicyUrl case final url?)
              _LinkTile(
                icon: Icons.privacy_tip_outlined,
                title: 'プライバシーポリシー',
                url: url,
              ),
            const _LinkTile(
              icon: Icons.business_rounded,
              title: '運営者(${AppConfig.operatorName})',
              url: AppConfig.operatorUrl,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined),
              title: const Text('オープンソースライセンス'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showLicenses(context),
            ),
            const _VersionTile(),
            const SizedBox(height: 24),
            Center(
              child: Text(
                '© ${DateTime.now().year} ${AppConfig.operatorName}',
                style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _showLicenses(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    showLicensePage(
      context: context,
      applicationName: 'ReadyGo Phrase',
      applicationVersion: info.version,
      applicationLegalese: '© ${DateTime.now().year} ${AppConfig.operatorName}',
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String url;

  const _LinkTile({required this.icon, required this.title, required this.url});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.open_in_new_rounded, size: 20),
      onTap: () => _open(context),
    );
  }

  Future<void> _open(BuildContext context) async {
    bool opened;
    try {
      opened = await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ページを開けませんでした')));
    }
  }
}

class _VersionTile extends StatelessWidget {
  const _VersionTile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.info_outline_rounded),
          title: const Text('バージョン'),
          trailing: Text(
            info == null ? '' : '${info.version} (${info.buildNumber})',
            style: const TextStyle(color: AppColors.inkMuted),
          ),
        );
      },
    );
  }
}
