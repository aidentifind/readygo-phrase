import 'dart:async';

import 'package:flutter/foundation.dart';

/// API との通信中かどうか。画面上部の「通信中」表示([NetworkActivityIndicator])が見る。
///
/// 通信中は必ず利用者に見える形で示す方針(readygo-speakのCLAUDE.md 3章を踏襲)。
/// readygo-speak-api への通信は、すべて [track] を通すこと(ApiClient・EntryRepository等)。
class NetworkActivity {
  NetworkActivity._();

  static final ValueNotifier<bool> busy = ValueNotifier(false);
  static int _running = 0;
  static Timer? _hideTimer;

  /// ローカル環境のように通信が数十msで終わると、フェードイン(120ms)より先に
  /// 消えてしまい利用者に見えない(2026-09-26 フィードバック)。表示したら最低この時間は保つ。
  static const _minVisible = Duration(milliseconds: 500);

  static Future<T> track<T>(Future<T> Function() request) async {
    _running++;
    _hideTimer?.cancel();
    busy.value = true;
    try {
      return await request();
    } finally {
      _running--;
      if (_running == 0) {
        _hideTimer = Timer(_minVisible, () {
          if (_running == 0) busy.value = false;
        });
      }
    }
  }
}
