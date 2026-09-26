import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../data/remote_config_repository.dart';
import 'ads_service.dart';

/// 画面幅に合わせたアンカー型アダプティブバナー(CLAUDE.md 8章、readygo-speakと同じ)。
///
/// 広告SDKの準備([AdsService.ready])ができるまで、また読み込みに失敗したときは
/// 何も表示しない(高さ0)。広告が無いことで画面の操作を妨げないため。
/// サーバーの設定(app_config の ads.enabled)が false の間も読み込まない。
class BannerAdSlot extends StatefulWidget {
  final String adUnitId;

  const BannerAdSlot({super.key, required this.adUnitId});

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  /// 読み込みに失敗したときの再試行(通信が一時的に不安定なときなど)。
  static const _retryDelay = Duration(seconds: 30);
  static const _maxRetries = 3;

  BannerAd? _ad;
  bool _loaded = false;
  int? _requestedWidth;
  int _retries = 0;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    AdsService.ready.addListener(_maybeLoad);
    RemoteConfigRepository.instance.config.addListener(_onConfigChanged);
  }

  bool get _enabled => RemoteConfigRepository.instance.config.value.adsEnabled;

  void _onConfigChanged() {
    if (!mounted) return;
    if (_enabled) {
      _maybeLoad();
    } else {
      _ad?.dispose();
      setState(() {
        _ad = null;
        _loaded = false;
        _requestedWidth = null; // 再びONになったら読み込み直す
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 画面幅が変わったとき(回転など)は、その幅で読み込み直す。
    _maybeLoad();
  }

  Future<void> _maybeLoad() async {
    if (!mounted || !AdsService.ready.value || !_enabled) return;
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width == _requestedWidth) return;
    _requestedWidth = width;

    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null || width != _requestedWidth) return;

    await _ad?.dispose();
    _ad = BannerAd(
      adUnitId: widget.adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _ad = null;
            _loaded = false;
          });
          if (_retries < _maxRetries) {
            _retries++;
            _retryTimer = Timer(_retryDelay, () {
              _requestedWidth = null; // 同じ幅でも読み込み直す
              _maybeLoad();
            });
          }
        },
      ),
    )..load();
    setState(() => _loaded = false);
  }

  @override
  void dispose() {
    AdsService.ready.removeListener(_maybeLoad);
    RemoteConfigRepository.instance.config.removeListener(_onConfigChanged);
    _retryTimer?.cancel();
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null || !_loaded) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
