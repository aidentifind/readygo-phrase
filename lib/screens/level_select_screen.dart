import 'package:flutter/material.dart';

import '../data/progress_repository.dart';
import '../data/study_settings.dart';
import '../models/entry.dart';
import '../theme/app_colors.dart';
import '../widgets/network_activity_indicator.dart';
import 'history_screen.dart';
import 'mode_select_screen.dart';
import 'settings_screen.dart';

/// レベル選択画面(readygo-speak-api docs/HANDOVER.md 2.1章)。
/// アプリ起動時、**毎回**表示する(前回選択の記憶とスキップは別物、混同しない)。
/// 前回選択したレベルはデフォルトでハイライトしておく(【提案】、選び直しの手間を減らす)。
class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReadyGo Phrase'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: '履歴',
            onPressed: () {
              ProgressRepository.instance.refresh();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '設定',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: NetworkActivityIndicator.reservedWidth - 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'レベルを選んでください',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'TOEICのスコア目安で選べます',
                style: TextStyle(color: AppColors.inkMuted),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: PhraseLevel.values.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final level = PhraseLevel.values[index];
                    return _LevelCard(
                      level: level,
                      highlighted: StudySettings.lastLevel == level,
                      onTap: () {
                        StudySettings.setLastLevel(level);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ModeSelectScreen(level: level),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final PhraseLevel level;
  final bool highlighted;
  final VoidCallback onTap;

  const _LevelCard({
    required this.level,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: highlighted ? 2 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: highlighted ? AppColors.brandEnd : Colors.transparent,
              width: 2,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  level.label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (highlighted)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.check_circle_rounded, color: AppColors.brandEnd, size: 20),
                ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
