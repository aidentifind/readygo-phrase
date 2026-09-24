import 'entry.dart';

/// 履歴画面のレベル別集計(GET /api/v1/phrase/progress の levels の1要素)。
class LevelProgress {
  final PhraseLevel level;
  final int total;
  final int known;
  final int unknown;
  final int unstudied;

  const LevelProgress({
    required this.level,
    required this.total,
    required this.known,
    required this.unknown,
    required this.unstudied,
  });

  factory LevelProgress.fromJson(PhraseLevel level, Map<String, dynamic>? json) {
    return LevelProgress(
      level: level,
      total: (json?['total'] as int?) ?? 0,
      known: (json?['known'] as int?) ?? 0,
      unknown: (json?['unknown'] as int?) ?? 0,
      unstudied: (json?['unstudied'] as int?) ?? 0,
    );
  }
}

/// 履歴画面のセッション単位のサマリ(GET /api/v1/phrase/progress の recent_sessions の1要素)。
class StudySessionSummary {
  final int id;
  final PhraseLevel level;
  final StudyMode mode;
  final int itemCount;
  final int knownCount;
  final int unknownCount;
  final DateTime startedAt;
  final DateTime? finishedAt;

  const StudySessionSummary({
    required this.id,
    required this.level,
    required this.mode,
    required this.itemCount,
    required this.knownCount,
    required this.unknownCount,
    required this.startedAt,
    required this.finishedAt,
  });

  factory StudySessionSummary.fromJson(Map<String, dynamic> json) {
    return StudySessionSummary(
      id: json['id'] as int,
      level: PhraseLevelApi.fromApi(json['level'] as String),
      mode: (json['mode'] as String) == 'review' ? StudyMode.review : StudyMode.study,
      itemCount: json['item_count'] as int,
      knownCount: json['known_count'] as int,
      unknownCount: json['unknown_count'] as int,
      startedAt: DateTime.parse(json['started_at'] as String),
      finishedAt: json['finished_at'] == null
          ? null
          : DateTime.parse(json['finished_at'] as String),
    );
  }
}
