package uz.mysafar.mysafar_sdk

import android.app.Activity
import android.os.Build
import android.window.BackEvent
import android.window.OnBackAnimationCallback
import android.window.OnBackInvokedCallback
import android.window.OnBackInvokedDispatcher
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Android 16 (targetSdk 36) da tizim back'ini FAQAT `OnBackInvokedDispatcher`ga
 * ro'yxatdan o'tgan callback oladi — `Activity.onBackPressed()` chaqirilmaydi va
 * `KeyEvent.KEYCODE_BACK` yuborilmaydi.
 *
 * Flutter bu callback'ni faqat `FlutterActivity` ichida, Dart tomondan
 * `SystemNavigator.setFrameworkHandlesBack(true)` kelganda ro'yxatdan
 * o'tkazadi. Host app boshqa activity ishlatsa (`FlutterFragment`
 * `shouldAutomaticallyHandleOnBackPressed(false)` bilan, custom activity,
 * `onBackPressed()` override qilingan activity), hech kim ro'yxatdan o'tmaydi
 * va tizim back'ni o'zi ushlaydi — SDK ekrani ochiq bo'lsa ham task orqa
 * fonga suriladi. SDK host kodini o'zgartira olmaydi, shuning uchun embed
 * ochiq ekan o'z callback'ini o'zi ro'yxatdan o'tkazadi.
 *
 * Callback event'ni O'ZI qayta ishlamaydi: uni Dart tomonga uzatadi, u yerda
 * event `flutter/backgesture` kanaliga xuddi engine yuborgandek qayta
 * kiritiladi. Shu sababli Flutter'ning odatdagi back mexanizmi —
 * `PopScope`, `didPopRoute`, predictive back animatsiyalari — o'zgarishsiz
 * ishlaydi.
 */
class MySafarBackPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {

    private companion object {
        const val CHANNEL = "mysafar_sdk/android_back"

        /** `OnBackInvokedDispatcher.PRIORITY_OVERLAY` — API 33+ da mavjud. */
        const val PRIORITY_OVERLAY = 1_000_000
    }

    private var channel: MethodChannel? = null
    private var activity: Activity? = null

    /** Dart "embed ochiq" deganmi. */
    private var wanted = false
    private var callback: OnBackInvokedCallback? = null

    // ── FlutterPlugin ────────────────────────────────────────────────────────

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler(this@MySafarBackPlugin)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        unregister()
        channel?.setMethodCallHandler(null)
        channel = null
    }

    // ── ActivityAware ────────────────────────────────────────────────────────

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        sync()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        sync()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        unregister()
        activity = null
    }

    override fun onDetachedFromActivity() {
        unregister()
        activity = null
    }

    // ── MethodCallHandler ────────────────────────────────────────────────────

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "enable" -> {
                wanted = true
                sync()
                // Dart shu javobga qarab, native callback ishlamasa Flutter'ning
                // o'z yo'liga tayanishni davom ettiradi.
                result.success(callback != null)
            }
            "disable" -> {
                wanted = false
                sync()
                result.success(false)
            }
            else -> result.notImplemented()
        }
    }

    // ── Ro'yxatdan o'tish ────────────────────────────────────────────────────

    private fun sync() {
        if (wanted) register() else unregister()
    }

    private fun register() {
        if (callback != null) return
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        val host = activity ?: return
        val created = createCallback()
        try {
            host.onBackInvokedDispatcher
                .registerOnBackInvokedCallback(PRIORITY_OVERLAY, created)
            callback = created
        } catch (e: Throwable) {
            // Manifestda `enableOnBackInvokedCallback="false"` bo'lsa yoki
            // activity dispatcher bermasa — Flutter'ning o'z yo'liga qaytamiz.
            callback = null
        }
    }

    private fun unregister() {
        val current = callback ?: return
        callback = null
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        try {
            activity?.onBackInvokedDispatcher
                ?.unregisterOnBackInvokedCallback(current)
        } catch (e: Throwable) {
            // Activity allaqachon yo'q — e'tiborsiz qoldiramiz.
        }
    }

    private fun createCallback(): OnBackInvokedCallback {
        // API 34+ predictive back'ning to'liq gesture oqimini beradi; 33 da
        // faqat yakuniy "invoked" bor.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            return object : OnBackAnimationCallback {
                override fun onBackStarted(backEvent: BackEvent) {
                    send("startBackGesture", backEvent.toMap())
                }

                override fun onBackProgressed(backEvent: BackEvent) {
                    send("updateBackGestureProgress", backEvent.toMap())
                }

                override fun onBackInvoked() {
                    send("commitBackGesture", null)
                }

                override fun onBackCancelled() {
                    send("cancelBackGesture", null)
                }
            }
        }
        return OnBackInvokedCallback { send("commitBackGesture", null) }
    }

    private fun send(method: String, arguments: Any?) {
        channel?.invokeMethod(method, arguments)
    }

    /** `BackGestureChannel.backEventToJsonMap` bilan bir xil shakl. */
    private fun BackEvent.toMap(): Map<String, Any?> {
        val x = touchX
        val y = touchY
        return mapOf(
            "touchOffset" to if (x.isNaN() || y.isNaN()) null else listOf(x, y),
            "progress" to progress,
            "swipeEdge" to swipeEdge,
        )
    }
}
