import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/config.dart';
import '../app_navigator.dart';

/// Razón de un intersticial obligatorio (sin recompensa).
enum MandatoryInterstitialReason { bet, dailyRewardAfterCoins, foregroundTime }

/// Intersticial obligatorio: tiempo en primer plano, cooldown y [no_ads].
class MandatoryInterstitialService {
  MandatoryInterstitialService._();
  static final MandatoryInterstitialService instance = MandatoryInterstitialService._();

  static const _prefLastShownMs = 'mandatory_interstitial_last_shown_ms';
  static const _prefForegroundMsBank = 'mandatory_ad_foreground_ms_bank';
  static const _prefForegroundMinutes = 'cfg_mandatory_ad_foreground_minutes';
  static const _prefCooldownSec = 'cfg_mandatory_ad_cooldown_sec';

  InterstitialAd? _loaded;
  bool _loading = false;
  bool _showInProgress = false;
  _ForegroundLifecycleObserver? _foregroundObserver;

  /// POST anónimo a la API; guarda umbrales en SharedPreferences.
  Future<void> refreshRemoteConfig() async {
    try {
      final url = Uri.https(Config.publicDomain, '/api/Info/ClientRuntimeConfig');
      final res = await http.post(
        url,
        headers: const {'Content-Type': 'application/json'},
        body: '{}',
      );
      if (res.statusCode != 200) return;
      final body = jsonDecode(res.body);
      if (body is! Map) return;
      final prefs = await SharedPreferences.getInstance();
      final minutes = (body['mandatoryAdForegroundMinutes'] as num?)?.toInt() ?? 10;
      final cd = (body['mandatoryAdCooldownSeconds'] as num?)?.toInt() ?? 300;
      await prefs.setInt(_prefForegroundMinutes, minutes.clamp(1, 480));
      await prefs.setInt(_prefCooldownSec, cd.clamp(30, 86400));
      final eur = (body['noAdsPriceEur'] as num?)?.toDouble() ?? 4.99;
      final usd = (body['noAdsPriceUsd'] as num?)?.toDouble() ?? 4.99;
      await prefs.setDouble('cfg_no_ads_price_eur', eur);
      await prefs.setDouble('cfg_no_ads_price_usd', usd);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MandatoryInterstitial] refreshRemoteConfig: $e');
      }
    }
  }

  /// Llamar desde [MainMenuPage] al entrar al menú principal (sesión autenticada).
  void startForegroundUsageTracking() {
    _foregroundObserver ??= _ForegroundLifecycleObserver(this);
    WidgetsBinding.instance.addObserver(_foregroundObserver!);
    _foregroundObserver!.beginSession();
  }

  /// Llamar al salir del menú principal (logout / dispose).
  void stopForegroundUsageTracking() {
    if (_foregroundObserver != null) {
      _foregroundObserver!.endSession();
      WidgetsBinding.instance.removeObserver(_foregroundObserver!);
      _foregroundObserver!.dispose();
      _foregroundObserver = null;
    }
  }

  Future<bool> _userHasNoAds() async {
    const storage = FlutterSecureStorage();
    final v = await storage.read(key: 'no_ads');
    return v == 'true';
  }

  Future<int> _cooldownSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefCooldownSec) ?? 300;
  }

  Future<int> _foregroundThresholdMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefForegroundMinutes) ?? 10;
  }

  Future<bool> _inCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_prefLastShownMs) ?? 0;
    if (last <= 0) return false;
    final cd = await _cooldownSeconds();
    final elapsed = DateTime.now().millisecondsSinceEpoch - last;
    return elapsed < cd * 1000;
  }

  Future<void> _markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefLastShownMs, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _flushForegroundMilliseconds(int ms) async {
    if (ms <= 0) return;
    if (_showInProgress) return;
    if (await _userHasNoAds()) return;

    final prefs = await SharedPreferences.getInstance();
    final thresholdMin = await _foregroundThresholdMinutes();
    final thresholdMs = thresholdMin * 60 * 1000;
    if (thresholdMs <= 0) return;

    var bank = prefs.getInt(_prefForegroundMsBank) ?? 0;
    bank += ms;

    while (bank >= thresholdMs) {
      if (await _userHasNoAds()) break;
      if (await _inCooldown()) break;
      if (_showInProgress) break;

      final shown = await requestShow(MandatoryInterstitialReason.foregroundTime);
      if (!shown) break;

      bank -= thresholdMs;
      await prefs.setInt(_prefForegroundMsBank, bank);
    }

    await prefs.setInt(_prefForegroundMsBank, bank);
  }

  void _onForegroundTick() {
    unawaited(_foregroundObserver?.sliceSegmentToService() ?? Future<void>.value());
  }

  /// Devuelve [true] si el anuncio se mostró y cerró (o timeout de cierre).
  Future<bool> requestShow(MandatoryInterstitialReason reason) async {
    if (await _userHasNoAds()) return false;
    if (await _inCooldown()) return false;
    if (_showInProgress) return false;

    final ctx = navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return false;

    _showInProgress = true;
    try {
      InterstitialAd? ad = _loaded;
      _loaded = null;
      ad ??= await _loadOnce();
      if (ad == null || !ctx.mounted) return false;

      final dismissed = Completer<void>();
      var sawAdImpression = false;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (_) {
          sawAdImpression = true;
        },
        onAdDismissedFullScreenContent: (a) {
          a.dispose();
          if (!dismissed.isCompleted) dismissed.complete();
        },
        onAdFailedToShowFullScreenContent: (a, err) {
          a.dispose();
          if (!dismissed.isCompleted) dismissed.complete();
          if (kDebugMode) {
            debugPrint('[MandatoryInterstitial] show failed: $err');
          }
        },
      );

      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      try {
        await ad.show();
        await dismissed.future.timeout(const Duration(seconds: 120), onTimeout: () {});
        if (sawAdImpression) {
          await _markShown();
          return true;
        }
        return false;
      } finally {
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: [SystemUiOverlay.top],
        );
      }
    } finally {
      _showInProgress = false;
      unawaited(_preload());
    }
  }

  Future<InterstitialAd?> _loadOnce() async {
    if (_loading) return null;
    _loading = true;
    final c = Completer<InterstitialAd?>();
    InterstitialAd.load(
      adUnitId: Config.admobInterstitialMandatoryId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          if (!c.isCompleted) c.complete(ad);
        },
        onAdFailedToLoad: (err) {
          _loading = false;
          if (kDebugMode) {
            debugPrint('[MandatoryInterstitial] load failed: $err');
          }
          if (!c.isCompleted) c.complete(null);
        },
      ),
    );
    return c.future.timeout(const Duration(seconds: 15), onTimeout: () {
      _loading = false;
      return null;
    });
  }

  Future<void> _preload() async {
    if (_loaded != null || _loading) return;
    final ad = await _loadOnce();
    _loaded = ad;
  }

  void schedulePreload() {
    unawaited(_preload());
  }
}

/// Acumula tiempo con la app en primer plano mientras el usuario está en el menú principal.
class _ForegroundLifecycleObserver with WidgetsBindingObserver {
  _ForegroundLifecycleObserver(this._service);

  final MandatoryInterstitialService _service;
  DateTime? _segmentStart;
  Timer? _tick;

  void beginSession() {
    _segmentStart = DateTime.now();
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => _service._onForegroundTick());
  }

  void endSession() {
    _tick?.cancel();
    _tick = null;
    if (_segmentStart != null) {
      final ms = DateTime.now().difference(_segmentStart!).inMilliseconds;
      _segmentStart = null;
      unawaited(_service._flushForegroundMilliseconds(ms));
    }
  }

  void dispose() {
    endSession();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _segmentStart = DateTime.now();
      _tick?.cancel();
      _tick = Timer.periodic(const Duration(seconds: 30), (_) => _service._onForegroundTick());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _tick?.cancel();
      _tick = null;
      if (_segmentStart != null) {
        final ms = DateTime.now().difference(_segmentStart!).inMilliseconds;
        _segmentStart = null;
        unawaited(_service._flushForegroundMilliseconds(ms));
      }
    }
  }

  Future<void> sliceSegmentToService() async {
    if (_segmentStart == null) return;
    final now = DateTime.now();
    final ms = now.difference(_segmentStart!).inMilliseconds;
    _segmentStart = now;
    await _service._flushForegroundMilliseconds(ms);
  }
}
