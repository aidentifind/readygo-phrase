import 'package:flutter/material.dart';

import '../data/network_activity.dart';
import '../theme/app_colors.dart';

/// API との通信中に、AppBarの下へ「通信中」を出す(すべての画面の上に重ねる)。
/// 操作は妨げない。通信が終わるとフェードアウトする。
class NetworkActivityIndicator extends StatelessWidget {
  const NetworkActivityIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            // AppBar(kToolbarHeight)の下に出す。actions のアイコンと重ならないようにするため。
            padding: const EdgeInsets.only(top: kToolbarHeight + 8, right: 12),
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
