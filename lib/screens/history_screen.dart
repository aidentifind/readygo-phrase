import 'package:flutter/material.dart';

import '../data/progress_repository.dart';
import '../models/entry.dart';
import '../models/study_progress.dart';
import '../theme/app_colors.dart';

/// 履歴画面(readygo-speak-api docs/HANDOVER.md 2.5章・§6未決事項5への回答)。
/// レベルごとの現在ステータス(覚えている/わからない/未学習)の内訳と、
/// 直近のセッションサマリの両方を出す。
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('履歴')),
      body: SafeArea(
        child: ValueListenableBuilder<ProgressState>(
          valueListenable: ProgressRepository.instance.state,
          builder: (context, state, _) => switch (state) {
            ProgressIdle() || ProgressLoading() =>
              const Center(child: CircularProgressIndicator()),
            ProgressFailed() => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '読み込めませんでした',
                      style: TextStyle(color: AppColors.inkMuted),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: ProgressRepository.instance.refresh,
                      child: const Text('もう一度試す'),
                    ),
                  ],
                ),
              ),
            ),
            ProgressLoaded(:final levels, :final recentSessions) => ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  'レベル別の状況',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                for (final level in levels) ...[
                  _LevelProgressCard(progress: level),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 20),
                const Text(
                  '最近の学習',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                if (recentSessions.isEmpty)
                  const Text('まだ学習の記録がありません', style: TextStyle(color: AppColors.inkMuted))
                else
                  for (final session in recentSessions) _SessionTile(session: session),
              ],
            ),
          },
        ),
      ),
    );
  }
}

class _LevelProgressCard extends StatelessWidget {
  final LevelProgress progress;

  const _LevelProgressCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final total = progress.total == 0 ? 1 : progress.total;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              progress.level.label,
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            const SizedBox(height: 4),
            Text(
              '覚えている ${progress.known} / わからない ${progress.unknown} / 未学習 ${progress.unstudied}'
              '(全${progress.total}件)',
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    for (final segment in [
                      (progress.known, AppColors.known),
                      (progress.unknown, AppColors.unknown),
                      (progress.unstudied, const Color(0xFFE7E3DC)),
                    ])
                      if (segment.$1 > 0)
                        Expanded(flex: segment.$1, child: Container(color: segment.$2)),
                    if (progress.known + progress.unknown + progress.unstudied == 0)
                      Expanded(flex: total, child: Container(color: const Color(0xFFE7E3DC))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final StudySessionSummary session;

  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final started = session.startedAt.toLocal();
    final dateLabel =
        '${started.month}/${started.day} ${started.hour.toString().padLeft(2, '0')}:'
        '${started.minute.toString().padLeft(2, '0')}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        session.mode == StudyMode.review ? Icons.refresh_rounded : Icons.school_rounded,
        color: AppColors.brandEnd,
      ),
      title: Text('${session.mode.label} ・ ${session.level.label}'),
      subtitle: Text('$dateLabel ・ 覚えている ${session.knownCount} / わからない ${session.unknownCount}'),
    );
  }
}
