import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// خدمة إدارة إعلانات AdMob
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // معرفات AdMob
  static const String _appId = 'ca-app-pub-2071490114166839~4635451759';
  
  // معرف الإعلان البيني (Interstitial)
  static String get _interstitialAdUnitId {
    if (kReleaseMode) {
      return 'ca-app-pub-2071490114166839/5757155254'; // الإنتاج
    }
    if (kIsWeb) {
      return ''; // Web لا يدعم الإعلانات
    }
    return Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/1033173712' // تجريبي Android
        : 'ca-app-pub-3940256099942544/4411468910'; // تجريبي iOS
  }

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  int _navigationAttempts = 0; // عداد محاولات التنقل

  /// تهيئة AdMob
  static Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('⚠️ AdMob غير مدعوم على الويب');
      return;
    }
    
    try {
      await MobileAds.instance.initialize();
      debugPrint('✅ تم تهيئة AdMob بنجاح');
    } catch (e) {
      debugPrint('❌ فشل تهيئة AdMob: $e');
    }
  }

  /// تحميل إعلان بيني (Interstitial)
  Future<void> loadInterstitialAd() async {
    if (kIsWeb) return;

    try {
      await InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialAdReady = true;
            debugPrint('✅ تم تحميل الإعلان البيني');

            // تعيين callbacks للإعلان
            _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('📱 تم إغلاق الإعلان');
                ad.dispose();
                _isInterstitialAdReady = false;
                // تحميل إعلان جديد
                loadInterstitialAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('❌ فشل عرض الإعلان: $error');
                ad.dispose();
                _isInterstitialAdReady = false;
                loadInterstitialAd();
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('❌ فشل تحميل الإعلان: $error');
            _isInterstitialAdReady = false;
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الإعلان: $e');
    }
  }

  /// عرض إعلان بيني قبل التنقل
  /// يعرض الإعلان كل 3 مرات (أو حسب frequency)
  Future<bool> showInterstitialAdIfReady({
    required VoidCallback onAdClosed,
    int frequency = 3, // عرض الإعلان كل 3 محاولات
  }) async {
    if (kIsWeb) {
      onAdClosed();
      return false;
    }

    _navigationAttempts++;

    // عرض الإعلان فقط كل X مرات
    if (_navigationAttempts % frequency != 0) {
      debugPrint('⏭️ تخطي الإعلان - المحاولة $_navigationAttempts');
      onAdClosed();
      return false;
    }

    if (_isInterstitialAdReady && _interstitialAd != null) {
      try {
        await _interstitialAd!.show();
        debugPrint('📺 عرض الإعلان البيني');
        
        // سيتم استدعاء onAdClosed من خلال callback
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _isInterstitialAdReady = false;
            loadInterstitialAd();
            onAdClosed();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _isInterstitialAdReady = false;
            loadInterstitialAd();
            onAdClosed();
          },
        );
        
        return true;
      } catch (e) {
        debugPrint('❌ خطأ في عرض الإعلان: $e');
        onAdClosed();
        return false;
      }
    } else {
      debugPrint('⚠️ الإعلان غير جاهز');
      onAdClosed();
      return false;
    }
  }

  /// التخلص من الموارد
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdReady = false;
  }

  /// إعادة تعيين العداد (اختياري)
  void resetAttempts() {
    _navigationAttempts = 0;
  }

  /// الحصول على حالة جاهزية الإعلان
  bool get isAdReady => _isInterstitialAdReady;
}
