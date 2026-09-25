import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../data/entry_repository.dart';
import '../data/study_repository.dart';
import '../data/study_settings.dart';
import '../models/entry.dart';
import '../theme/app_colors.dart';

enum _CardScreenStatus { loading, ready, empty, failed, done }

/// カード画面(readygo-speak-api docs/HANDOVER.md 2.3章)。
///
/// 1画面に英語表現と意味を表示する構成。ただし意味は画面表示から[設定値]秒後
/// (既定3秒、StudySettings.revealSeconds)に表示され、待機中は「意味を考えて」を出す。
/// フリップ(左=覚えている/右=わからない)は、意味の表示タイミングに関係なくいつでも可能
/// (スワイプ・左右ボタンの両対応、実装方式は§6未決事項3のため両方受け付ける)。
class CardScreen extends StatefulWidget {
  final PhraseLevel level;
  final StudyMode mode;

  const CardScreen({super.key, required this.level, required this.mode});

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  _CardScreenStatus _status = _CardScreenStatus.loading;
  StudySession? _session;
  List<Entry> _queue = const [];
  int _index = 0;
  bool _revealed = false;
  int _remainingMs = 0;
  DateTime? _shownAt;
  int _knownCount = 0;
  int _unknownCount = 0;

  Timer? _timer;
  final _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _status = _CardScreenStatus.loading);
    try {
      final session = await StudyRepository.instance.startSession(
        level: widget.level,
        mode: widget.mode,
      );
      final entries = await EntryRepository.instance.fetch(widget.level);

      List<Entry> queue;
      if (widget.mode == StudyMode.review) {
        final unknownIds =
            (await StudyRepository.instance.fetchReviewCandidates(widget.level)).toSet();
        queue = entries.where((e) => unknownIds.contains(e.id)).toList();
      } else {
        queue = List.of(entries)..shuffle();
      }

      if (!mounted) return;
      if (queue.isEmpty) {
        setState(() => _status = _CardScreenStatus.empty);
        return;
      }

      setState(() {
        _session = session;
        _queue = queue;
        _index = 0;
        _knownCount = 0;
        _unknownCount = 0;
        _status = _CardScreenStatus.ready;
      });
      _showCard();
    } catch (_) {
      if (mounted) setState(() => _status = _CardScreenStatus.failed);
    }
  }

  Entry get _current => _queue[_index];

  void _showCard() {
    _timer?.cancel();
    _revealed = false;
    _shownAt = DateTime.now();
    _remainingMs = StudySettings.revealSeconds.value * 1000;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _remainingMs -= 100;
        if (_remainingMs <= 0) {
          _remainingMs = 0;
          _revealed = true;
          timer.cancel();
        }
      });
    });
    setState(() {});
  }

  Future<void> _play(Uri url) async {
    try {
      await _player.setUrl(url.toString());
      await _player.play();
    } catch (_) {
      // 発音が聞けなくても学習は続けられる(音声はあくまで補助)。
    }
  }

  void _flip(StudyResult result) {
    final session = _session;
    if (session == null) return;

    final elapsedMs = _shownAt == null
        ? 0
        : DateTime.now().difference(_shownAt!).inMilliseconds;
    unawaited(
      StudyRepository.instance.submitFlip(
        sessionId: session.id,
        entryId: _current.id,
        result: result,
        revealedBeforeFlip: _revealed,
        elapsedMs: elapsedMs,
      ),
    );

    _timer?.cancel();
    setState(() {
      if (result == StudyResult.known) {
        _knownCount++;
      } else {
        _unknownCount++;
      }
      if (_index + 1 >= _queue.length) {
        _status = _CardScreenStatus.done;
      } else {
        _index++;
      }
    });
    if (_status == _CardScreenStatus.ready) _showCard();
  }

  void _onSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 200) return;
    // 左スワイプ=覚えている、右スワイプ=わからない(readygo-speak-api docs/HANDOVER.md 2.3章)。
    _flip(velocity < 0 ? StudyResult.known : StudyResult.unknown);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titleFor(widget.mode, widget.level))),
      body: SafeArea(
        child: switch (_status) {
          _CardScreenStatus.loading => const Center(child: CircularProgressIndicator()),
          _CardScreenStatus.failed => _MessageView(
            message: '読み込めませんでした。通信状態を確認してもう一度お試しください。',
            actionLabel: 'もう一度試す',
            onAction: _load,
          ),
          _CardScreenStatus.empty => _MessageView(
            message: widget.mode == StudyMode.review
                ? '今のところ復習する項目はありません。'
                : 'このレベルにはまだ項目がありません。',
            actionLabel: '戻る',
            onAction: () => Navigator.of(context).pop(),
          ),
          _CardScreenStatus.ready => _buildCard(),
          _CardScreenStatus.done => _buildSummary(),
        },
      ),
    );
  }

  static String _titleFor(StudyMode mode, PhraseLevel level) =>
      '${mode.label} (${level.label})';

  Widget _buildCard() {
    final entry = _current;
    final total = _queue.length;
    return GestureDetector(
      onHorizontalDragEnd: _onSwipe,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: _index / total,
                minHeight: 6,
                backgroundColor: AppColors.brandEnd.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation(AppColors.brandEnd),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_index + 1} / $total',
                style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Chip(label: Text(entry.kind.label)),
                    const SizedBox(height: 20),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _play(entry.expressionAudioUrl),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                entry.expression,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.volume_up_rounded, color: AppColors.brandEnd),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (!_revealed)
                      Column(
                        children: [
                          const Text(
                            '意味を考えて…',
                            style: TextStyle(color: AppColors.inkMuted, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${(_remainingMs / 1000).ceil()}',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandEnd,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Text(
                            entry.meaningJa,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 28),
                          for (final example in entry.examples)
                            _ExampleTile(
                              example: example,
                              onPlay: () => _play(
                                entry.audioUrl('example_${example.position}'),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.known.withValues(alpha: 0.14),
                      foregroundColor: AppColors.known,
                    ),
                    onPressed: () => _flip(StudyResult.known),
                    child: const Text('覚えている'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.unknown.withValues(alpha: 0.14),
                      foregroundColor: AppColors.unknown,
                    ),
                    onPressed: () => _flip(StudyResult.unknown),
                    child: const Text('わからない'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.brandEnd, size: 56),
            const SizedBox(height: 16),
            const Text(
              'おつかれさまでした',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 12),
            Text(
              '覚えている: $_knownCount件 / わからない: $_unknownCount件',
              style: const TextStyle(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('戻る'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleTile extends StatelessWidget {
  final EntryExample example;
  final VoidCallback onPlay;

  const _ExampleTile({required this.example, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPlay,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.volume_up_outlined, size: 18, color: AppColors.inkMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(example.enText, style: const TextStyle(color: AppColors.ink)),
                    const SizedBox(height: 4),
                    Text(
                      example.jaText,
                      style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _MessageView({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
