package uz.mysafar.mysafar_sdk_example

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Diagnostika: engine'ning back kanali loglarini yoqadi (faqat debug
        // build'da ta'sir qiladi). `adb logcat -s BackGestureChannel:V
        // PlatformPlugin:V` — back bosilganda "Sending message to start back
        // gesture" chiqsa, tizim callback'i ro'yxatdan o'tgan va event
        // Flutter'ga uzatilyapti.
        io.flutter.Log.setLogLevel(Log.VERBOSE)
        super.onCreate(savedInstanceState)
    }
}
