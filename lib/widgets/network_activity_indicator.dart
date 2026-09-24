import 'package:flutter/material.dart';

import '../data/network_activity.dart';
import '../theme/app_colors.dart';

/// API との通信中に、画面右上へ「通信中」を出す(すべての画面の上に重ねる)。
/// 操作は妨げない。通信が終わるとフェードアウトする。
class NetworkActivityIndicator extends StatelessWidget {
  const NetworkActivityIndicator({super.key});

  /// 右上に重なる表示の幅(右の余白を含む)。AppBarの右端に見出しなどを置く画面は、
  /// actions にこの幅の空きを入れて、見出しが隠れないようにする。
  static const double reservedWidth = 96;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, right: 12),
            child: ValueListenableBuilder<bool>(
              valueListenable: NetworkActivity.busy,
              builder: (context, busy, _) => AnimatedOpacity(
                opacity: busy ? 1 : 0,
                duration: Duration(milliseconds: busy ? 120 : 400),
                child: TickerMode(enabled: busy, child: const _Pill()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(999),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.brandEnd),
              ),
            ),
            SizedBox(width: 8),
            Text(
              '通信中',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.ink,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
