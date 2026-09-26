import 'package:flutter/material.dart';

import '../data/entry_repository.dart';
import '../data/study_repository.dart';
import '../models/entry.dart';
import '../theme/app_colors.dart';
import 'card_screen.dart';

/// モード選択画面(readygo-speak-api docs/HANDOVER.md 2.2章)。
/// 学習モード: 選択したレベルの全件。復習モード: 過去に「わからない」判定になったものだけ
/// (レベル内限定、§6未決事項2の回答)。
class ModeSelectScreen extends StatefulWidget {
  final PhraseLevel level;

  const ModeSelectScreen({super.key, required this.level});

  @override
  State<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends State<ModeSelectScreen> {
  late Future<(int, int)> _counts;

  @override
  void initState() {
    super.initState();
    _counts = _loadCounts();
  }

  Future<(int, int)> _loadCounts() async {
    final entries = await EntryRepository.instance.fetch(widget.level);
    final unknownIds = await StudyRepository.instance.fetchReviewCandidates(widget.level);
    return (entries.length, unknownIds.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.level.label)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${widget.level.toeicRange}が目安',
                style: const TextStyle(color: AppColors.inkMuted),
              ),
              const SizedBox(height: 24),
              FutureBuilder<(int, int)>(
                future: _counts,
                builder: (context, snapshot) {
                  final total = snapshot.data?.$1;
                  final review = snapshot.data?.$2;
                  return Column(
                    children: [
                      _ModeCard(
                        icon: Icons.school_rounded,
                        title: StudyMode.study.actionLabel,
                        subtitle: null,
                        enabled: total == null || total > 0,
                        onTap: () => _start(StudyMode.study),
                      ),
                      const SizedBox(height: 20),
                      _ModeCard(
                        icon: Icons.refresh_rounded,
                        title: StudyMode.review.actionLabel,
                        subtitle: review == null
                            ? '読み込み中…'
                            : (review == 0 ? '「わからない」の項目はありません' : '$review件'),
                        enabled: (review ?? 0) > 0,
                        onTap: () => _start(StudyMode.review),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _start(StudyMode mode) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CardScreen(level: widget.level, mode: mode),
      ),
    );
    // 学習・復習から戻ってきたら「わからない」件数が変わっている可能性があるので、
    // 復習ボタンの有効/件数表示を最新化する(2026-09-26、戻っても反映されない不具合の修正)。
    if (mounted) setState(() => _counts = _loadCounts());
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool enabled;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle!, style: const TextStyle(color: AppColors.inkMuted)),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
