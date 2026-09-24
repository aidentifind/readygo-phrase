import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/entry.dart';
import '../models/study_progress.dart';
import 'api_client.dart';
import 'study_repository.dart';

/// 履歴画面の状態。
sealed class ProgressState {
  const ProgressState();
}

/// まだ一度も読み込んでいない(履歴画面を開く前)。
class ProgressIdle extends ProgressState {
  const ProgressIdle();
}

class ProgressLoading extends ProgressState {
  const ProgressLoading();
}

class ProgressLoaded extends ProgressState {
  final List<LevelProgress> levels;
  final List<StudySessionSummary> recentSessions;
  const ProgressLoaded(this.levels, this.recentSessions);
}

class ProgressFailed extends ProgressState {
  const ProgressFailed();
}

/// 履歴画面の集計(GET /api/v1/phrase/progress)。履歴画面を開くたびに [refresh] する。
class ProgressRepository {
  ProgressRepository({ApiClient? api}) : _apiOverride = api;

  static ProgressRepository instance = ProgressRepository();

  final ApiClient? _apiOverride;
  ApiClient get _api => _apiOverride ?? ApiClient.instance;

  final ValueNotifier<ProgressState> state = ValueNotifier(const ProgressIdle());

  Future<void> refresh() async {
    // 前回の表示があれば残したまま読み込む(開くたびに点滅させない)。
    if (state.value is! ProgressLoaded) state.value = const ProgressLoading();
    try {
      // 直前の学習のフリップを送り切ってから集計する。
      await StudyRepository.instance.flush();
      final response = await _api.get('/api/v1/phrase/progress');
      if (response.statusCode != 200) {
        throw ApiException('HTTP ${response.statusCode}');
      }
      final body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final byLabel = {
        for (final row in body['levels'] as List<dynamic>)
          (row as Map<String, dynamic>)['level'] as String: row,
      };
      state.value = ProgressLoaded(
        [
          for (final level in PhraseLevel.values)
            LevelProgress.fromJson(level, byLabel[level.apiValue]),
        ],
        [
          for (final row in body['recent_sessions'] as List<dynamic>)
            StudySessionSummary.fromJson(row as Map<String, dynamic>),
        ],
      );
    } catch (_) {
      if (state.value is! ProgressLoaded) {
        state.value = const ProgressFailed();
      }
    }
  }
}
