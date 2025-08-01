package com.betstrading.betrader
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.android.gms.ads.*
import com.google.android.gms.ads.rewarded.*
import com.google.android.gms.ads.rewarded.ServerSideVerificationOptions

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "custom_rewarded_ad"
    private var rewardedAd: RewardedAd? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MobileAds.initialize(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "loadRewarded" -> {
                        val adUnitId = call.argument<String>("adUnitId")!!
                        val userId = call.argument<String>("userId")!!

                        val adRequest = AdRequest.Builder().build()

                        RewardedAd.load(this, adUnitId, adRequest, object : RewardedAdLoadCallback() {
                            override fun onAdLoaded(ad: RewardedAd) {
                                rewardedAd = ad

                                val options = ServerSideVerificationOptions.Builder()
                                    .setCustomData(userId)
                                    .build()
                                ad.setServerSideVerificationOptions(options)

                                result.success("loaded")
                            }

                            override fun onAdFailedToLoad(error: LoadAdError) {
                                rewardedAd = null
                                result.error("load_failed", error.message, null)
                            }
                        })
                    }
                    "showRewarded" -> {
                        rewardedAd?.show(this) { rewardItem ->
                            result.success(rewardItem.amount)
                        } ?: result.error("not_loaded", "Ad not loaded", null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
