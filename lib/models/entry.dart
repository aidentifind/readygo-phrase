import '../config/app_config.dart';
import '../data/remote_config_repository.dart';

/// readygo-speak-api docs/HANDOVER.md 3.1章のコンテンツ(句動詞・熟語)。
/// GET /api/v1/phrase/entries から取得する。
class Entry {
  final String id;
  final String expression;
  final EntryKind kind;
  final int senseNo;
  final PhraseLevel level;
  final String meaningJa;
  final bool? separable;
  final String? register;
  final String? region;
  final List<EntryExample> examples;

  const Entry({
    required this.id,
    required this.expression,
    required this.kind,
    required this.senseNo,
    required this.level,
    required this.meaningJa,
    required this.separable,
    required this.register,
    required this.region,
    required this.examples,
  });

  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
      id: json['id'] as String,
      expression: json['expression'] as String,
      kind: EntryKindApi.fromApi(json['kind'] as String),
      senseNo: json['sense_no'] as int,
      level: PhraseLevelApi.fromApi(json['level'] as String),
      meaningJa: json['meaning_ja'] as String,
      separable: json['separable'] as bool?,
      register: json['register'] as String?,
      region: json['region'] as String?,
      examples: (json['examples'] as List<dynamic>)
          .map((e) => EntryExample.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// CDN上の発音音声のURL(readygo-speak-api の `Audio::PhraseGenerator` が生成する
  /// `{id}_expression.mp3` / `{id}_example_N.mp3`)。配信元はサーバーの設定
  /// (app_config の audio_base_url)で差し替えられる。無ければアプリに書いた値。
  Uri audioUrl(String suffix) {
    final base = const bool.hasEnvironment('CDN_BASE_URL')
        ? AppConfig.cdnBaseUrl
        : RemoteConfigRepository.instance.config.value.audioBaseUrl ??
            AppConfig.cdnBaseUrl;
    return Uri.parse('$base/${id}_$suffix.mp3');
  }

  Uri get expressionAudioUrl => audioUrl('expression');
}

/// 1エントリにつき例文3件程度(readygo-speak-api docs/HANDOVER.md 2.4章)。
class EntryExample {
  final String enText;
  final String jaText;
  final int position;

  const EntryExample({
    required this.enText,
    required this.jaText,
    required this.position,
  });

  factory EntryExample.fromJson(Map<String, dynamic> json) {
    return EntryExample(
      enText: json['en_text'] as String,
      jaText: json['ja_text'] as String,
      position: json['position'] as int,
    );
  }
}

enum EntryKind { phrasalVerb, idiom }

extension EntryKindApi on EntryKind {
  String get apiValue => switch (this) {
    EntryKind.phrasalVerb => 'phrasal_verb',
    EntryKind.idiom => 'idiom',
  };

  String get label => switch (this) {
    EntryKind.phrasalVerb => '句動詞',
    EntryKind.idiom => '熟語',
  };

  static EntryKind fromApi(String value) =>
      value == 'idiom' ? EntryKind.idiom : EntryKind.phrasalVerb;
}

/// レベル定義(readygo-speak-api docs/HANDOVER.md 2.1章、TOEIC換算3段階)。
enum PhraseLevel { toeicLt600, toeic600700, toeic800900 }

extension PhraseLevelApi on PhraseLevel {
  String get apiValue => switch (this) {
    PhraseLevel.toeicLt600 => 'toeic_lt600',
    PhraseLevel.toeic600700 => 'toeic_600_700',
    PhraseLevel.toeic800900 => 'toeic_800_900',
  };

  String get label => switch (this) {
    PhraseLevel.toeicLt600 => 'TOEIC 600点未満',
    PhraseLevel.toeic600700 => 'TOEIC 600〜700点',
    PhraseLevel.toeic800900 => 'TOEIC 800〜900点',
  };

  static PhraseLevel fromApi(String value) => switch (value) {
    'toeic_600_700' => PhraseLevel.toeic600700,
    'toeic_800_900' => PhraseLevel.toeic800900,
    _ => PhraseLevel.toeicLt600,
  };
}

/// 学習モード(readygo-speak-api docs/HANDOVER.md 2.2章)。
enum StudyMode { study, review }

extension StudyModeApi on StudyMode {
  String get apiValue => name;

  String get label => switch (this) {
    StudyMode.study => '学習',
    StudyMode.review => '復習',
  };
}

/// フリップの判定(左=覚えている/右=わからない)。
enum StudyResult { known, unknown }

extension StudyResultApi on StudyResult {
  String get apiValue => name;
}
