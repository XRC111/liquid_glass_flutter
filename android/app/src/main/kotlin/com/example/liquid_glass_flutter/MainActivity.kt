package com.example.liquid_glass_flutter

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "com.example.liquid_glass/device"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "getDeviceInfo") {
                    val isLowRam = isLowRamDevice()
                    result.success(
                        mapOf(
                            "sdkInt" to Build.VERSION.SDK_INT,
                            "isLowRam" to isLowRam,
                            "release" to Build.VERSION.RELEASE,
                        )
                    )
                } else {
                    result.notImplemented()
                }
            }
    }

    /** 判断系统是否将本设备标记为低内存设备（API 19+）。 */
    private fun isLowRamDevice(): Boolean {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
            ?: return false
        return try {
            am.isLowRamDevice
        } catch (e: Exception) {
            false
        }
    }
}
