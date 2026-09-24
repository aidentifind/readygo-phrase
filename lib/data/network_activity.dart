import 'package:flutter/foundation.dart';

/// API との通信中かどうか。画面上部の「通信中」表示([NetworkActivityIndicator])が見る。
///
/// 通信中は必ず利用者に見える形で示す方針(readygo-speakのCLAUDE.md 3章を踏襲)。
/// readygo-speak-api への通信は、すべて [track] を通すこと(ApiClient・EntryRepository等)。
class NetworkActivity {
  NetworkActivity._();

  static final ValueNotifier<bool> busy = ValueNotifier(false);
  static int _running = 0;

  static Future<T> track<T>(Future<T> Function() request) async {
    _running++;
    busy.value = true;
    try {
      return await request();
    } finally {
      _running--;
      if (_running == 0) busy.value = false;
    }
  }
}
