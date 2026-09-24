import 'package:flutter/material.dart';

/// readygo-speak の CLAUDE.md 2章「ブランド・デザインシステム」のカラートークンをそのまま流用。
/// "ReadyGo" をマスターブランドとする命名戦略(CLAUDE.md 1章)により、機能別サブアプリである
/// ReadyGo Phraseもコーラル×マゼンタの「Speak A」ブランドグラデーションを共有する。
/// 値を変更する場合は readygo-speak/CLAUDE.md の更新も必ず行うこと(トークンの正はそちら)。
class AppColors {
  AppColors._();

  /// ブランドグラデーション始点(左上) `#FF6A1F`
  static const Color brandStart = Color(0xFFFF6A1F);

  /// ブランドグラデーション終点(右下) `#FF1E88`
  static const Color brandEnd = Color(0xFFFF1E88);

  /// 135°、左上がbrandStart、右下がbrandEnd。角度・色順は変更しないこと。
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandStart, brandEnd],
  );

  static const Color accent = Color(0xFFFFD23F);
  static const Color ink = Color(0xFF16141F);
  static const Color paper = Color(0xFFF6F4F0);

  /// フリップの判定色。Speakの◯△✕とは評価軸が違う(known/unknownの2値)ため、
  /// 判定色もブランドカラーと分離しつつ独自に定義する(Speakの設計思想を継承)。
  static const Color known = Color(0xFF2AA876); // 覚えている
  static const Color unknown = Color(0xFFE4433D); // わからない

  static const Color inkMuted = Color(0xB316141F); // Ink 70%相当(補助テキスト用)
}
