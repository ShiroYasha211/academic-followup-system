package com.mohammed.moeen.moeen_student_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.KeyguardManager
import android.content.Context
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.view.MotionEvent
import android.view.WindowManager

class MainActivity : FlutterActivity() {
    private var securityChannel: MethodChannel? = null
    private var quizSecurityEnabled = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "moeen/review_overlay")
            .setMethodCallHandler { call, result -> ReviewOverlayBridge.handle(this, call, result) }

        securityChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "moeen/security")
        securityChannel?.setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecureScreen" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        runOnUiThread {
                            ReviewOverlayBridge.blockQuiz(enabled)
                            quizSecurityEnabled = enabled
                            if (enabled) {
                                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            } else {
                                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            }
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                window.setHideOverlayWindows(enabled)
                            }
                            window.decorView.filterTouchesWhenObscured = enabled
                        }
                        result.success(null)
                    }
                    "getAndroidId" -> {
                        val androidId = Settings.Secure.getString(
                            contentResolver,
                            Settings.Secure.ANDROID_ID
                        )
                        result.success(androidId)
                    }
                    "isScreenLockedOrOff" -> {
                        val keyguardManager =
                            getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                        val powerManager =
                            getSystemService(Context.POWER_SERVICE) as PowerManager
                        val locked = keyguardManager.isKeyguardLocked
                        val screenOff = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT_WATCH) {
                            !powerManager.isInteractive
                        } else {
                            @Suppress("DEPRECATION")
                            !powerManager.isScreenOn
                        }
                        result.success(locked || screenOff)
                    }
                    "isInMultiWindowMode" -> {
                        val inMultiWindow =
                            Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && isInMultiWindowMode
                        result.success(inMultiWindow)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onStart() {
        super.onStart()
        ReviewOverlayBridge.appVisible = true
        FloatingReviewService.instance?.hideQuestion()
    }

    override fun onStop() {
        ReviewOverlayBridge.appVisible = false
        super.onStop()
    }

    override fun dispatchTouchEvent(event: MotionEvent): Boolean {
        if (quizSecurityEnabled && isTouchObscured(event)) {
            notifyOverlayDetected()
            return true
        }

        return super.dispatchTouchEvent(event)
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)

        if (quizSecurityEnabled && !hasFocus) {
            notifyWindowFocusLost()
        }
    }

    private fun isTouchObscured(event: MotionEvent): Boolean {
        val obscured = (event.flags and MotionEvent.FLAG_WINDOW_IS_OBSCURED) != 0
        val partiallyObscured =
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
                (event.flags and MotionEvent.FLAG_WINDOW_IS_PARTIALLY_OBSCURED) != 0

        return obscured || partiallyObscured
    }

    private fun notifyOverlayDetected() {
        securityChannel?.invokeMethod("onOverlayDetected", null)
    }

    private fun notifyWindowFocusLost() {
        securityChannel?.invokeMethod("onWindowFocusLost", null)
    }
}
