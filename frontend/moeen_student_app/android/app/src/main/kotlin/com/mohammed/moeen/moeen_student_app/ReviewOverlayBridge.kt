package com.mohammed.moeen.moeen_student_app

import android.app.Activity
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import java.time.LocalDate
import java.util.UUID

internal data class ReviewSession(val account: String, val token: String, val baseUrl: String)

internal object ReviewOverlayBridge {
    @Volatile var session: ReviewSession? = null
        private set
    @Volatile var appVisible = true
    @Volatile var quizBlocked = false
    @Volatile var inAppPrompt = false
    private var promptLease: String? = null
    @Volatile var message = ""
    @Volatile var starting = false
    val journalLock = Any()

    fun prefs(context: Context) = context.getSharedPreferences("moeen_review_overlay", Context.MODE_PRIVATE)
    fun mode(context: Context) = session?.let { prefs(context).getString("mode_${it.account}", "inApp") } ?: "inApp"
    fun autoStart(context: Context) = session?.let { prefs(context).getBoolean("auto_start_${it.account}", false) } ?: false

    fun disableAutoStart(context: Context, account: String) {
        check(prefs(context).edit().putBoolean("auto_start_$account", false).commit())
    }

    private fun start(activity: Activity) {
        check(Build.VERSION.SDK_INT >= 26 && appVisible && !quizBlocked && !activity.isFinishing && !activity.isDestroyed) {
            "Open the app outside an exam to start"
        }
        check(session != null && mode(activity) == "floating") { "Select floating mode first" }
        check(Settings.canDrawOverlays(activity)) { "Overlay permission is required" }
        check((activity.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).areNotificationsEnabled()) {
            "Notification permission is required"
        }
        if (starting || FloatingReviewService.instance != null) return
        starting = true
        try {
            activity.startForegroundService(Intent(activity, FloatingReviewService::class.java))
            message = ""
        } catch (error: Exception) {
            starting = false
            throw error
        }
    }

    private fun resumeIfEnabled(activity: Activity) {
        if (!autoStart(activity) || mode(activity) != "floating" || !appVisible || quizBlocked ||
            activity.isFinishing || activity.isDestroyed) return
        if (!Settings.canDrawOverlays(activity)) {
            message = "يلزم السماح بالظهور فوق التطبيقات لاستئناف المراجعة."
            return
        }
        if (!(activity.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).areNotificationsEnabled()) {
            message = "يلزم السماح بالإشعارات لاستئناف المراجعة."
            return
        }
        try {
            start(activity)
        } catch (error: Exception) {
            Log.w("MoeenReview", "Automatic resume unavailable: ${error.javaClass.simpleName}")
            message = "تعذر استئناف المراجعة العائمة. حاول تشغيلها من الإعدادات."
        }
    }

    fun status(context: Context): Map<String, Any> {
        val current = session
        val seen = current?.let { seen(context, it.account) } ?: emptyList()
        val pending = current?.let { pending(context, it.account).length() } ?: 0
        return mapOf(
            "supported" to (Build.VERSION.SDK_INT >= 26),
            "permission" to Settings.canDrawOverlays(context),
            "mode" to (mode(context) ?: "inApp"),
            "running" to (starting || FloatingReviewService.instance != null),
            "auto_start" to autoStart(context),
            "pending" to pending,
            "message" to message,
            "seen_ids" to seen,
        )
    }

    fun pending(context: Context, account: String): JSONArray = synchronized(journalLock) {
        JSONArray(prefs(context).getString("answers_$account", "[]"))
    }

    fun seen(context: Context, account: String): List<Int> = synchronized(journalLock) {
        if (prefs(context).getString("seen_day_$account", "") != LocalDate.now().toString()) return@synchronized emptyList()
        val values = JSONArray(prefs(context).getString("seen_$account", "[]"))
        (0 until values.length()).map { values.getInt(it) }
    }

    fun completed(context: Context, account: String, item: Int) = synchronized(journalLock) {
        val ids = (seen(context, account) + item).distinct()
        check(prefs(context).edit().putString("seen_day_$account", LocalDate.now().toString())
            .putString("seen_$account", JSONArray(ids).toString()).commit()) { "Cannot persist review state" }
    }

    fun acknowledge(context: Context, account: String, eventId: String) = synchronized(journalLock) {
        val values = pending(context, account)
        val retained = JSONArray()
        for (index in 0 until values.length()) {
            val entry = values.getJSONObject(index)
            if (entry.getString("client_event_id") != eventId) retained.put(entry)
        }
        check(prefs(context).edit().putString("answers_$account", retained.toString()).commit())
    }

    fun blockQuiz(value: Boolean) {
        quizBlocked = value
        if (value) FloatingReviewService.instance?.hideQuestion()
    }

    fun handle(activity: Activity, call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "configure" -> {
                    val account = call.argument<String>("account") ?: error("Missing account")
                    val token = call.argument<String>("token") ?: error("Missing token")
                    val baseUrl = call.argument<String>("base_url") ?: error("Missing server URL")
                    val uri = Uri.parse(baseUrl)
                    require(uri.scheme == "https" && !uri.host.isNullOrBlank() && uri.userInfo == null) { "HTTPS is required" }
                    if (session?.account != account) {
                        activity.stopService(Intent(activity, FloatingReviewService::class.java))
                        inAppPrompt = false
                        message = ""
                    }
                    session = ReviewSession(account, token, baseUrl.trimEnd('/'))
                    // Allow an old account's service to finish stopping before resuming.
                    activity.window.decorView.post {
                        if (session?.account == account) resumeIfEnabled(activity)
                    }
                    result.success(null)
                }
                "status" -> result.success(status(activity))
                "setMode" -> {
                    val current = session ?: error("Sign in first")
                    val mode = call.arguments as? String
                    require(mode in listOf("inApp", "floating", "notificationOnly"))
                    check(prefs(activity).edit().putString("mode_${current.account}", mode).commit())
                    if (mode != "floating") {
                        starting = false
                        activity.stopService(Intent(activity, FloatingReviewService::class.java))
                    } else {
                        resumeIfEnabled(activity)
                    }
                    result.success(null)
                }
                "setAutoStart" -> {
                    val current = session ?: error("Sign in first")
                    val enabled = call.arguments as? Boolean ?: error("Missing automatic review setting")
                    check(prefs(activity).edit().putBoolean("auto_start_${current.account}", enabled).commit())
                    if (enabled) resumeIfEnabled(activity)
                    else {
                        starting = false
                        activity.stopService(Intent(activity, FloatingReviewService::class.java))
                    }
                    result.success(null)
                }
                "permission" -> {
                    activity.startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:${activity.packageName}")))
                    result.success(null)
                }
                "start" -> {
                    start(activity)
                    result.success(null)
                }
                "stop" -> {
                    starting = false
                    activity.stopService(Intent(activity, FloatingReviewService::class.java))
                    session = null
                    inAppPrompt = false
                    result.success(null)
                }
                "endSession" -> {
                    session?.let { disableAutoStart(activity, it.account) }
                    starting = false
                    activity.stopService(Intent(activity, FloatingReviewService::class.java))
                    result.success(null)
                }
                "answers" -> {
                    val current = session ?: error("Sign in first")
                    require(call.argument<String>("account") == current.account)
                    val entries = pending(activity, current.account)
                    result.success((0 until entries.length()).map { index ->
                        val entry = entries.getJSONObject(index)
                        mapOf("client_event_id" to entry.getString("client_event_id"),
                            "item_id" to entry.getInt("item_id"), "response_level" to entry.getString("response_level"))
                    })
                }
                "acknowledge" -> {
                    val current = session ?: error("Sign in first")
                    require(call.argument<String>("account") == current.account)
                    acknowledge(activity, current.account, call.argument<String>("event_id") ?: error("Missing event"))
                    result.success(null)
                }
                "beginInApp" -> {
                    val force = call.argument<Boolean>("force") == true
                    val allowed = !quizBlocked && !inAppPrompt && (force ||
                        (mode(activity) != "notificationOnly" && FloatingReviewService.instance?.isSnoozed() != true))
                    if (allowed) {
                        inAppPrompt = true
                        promptLease = UUID.randomUUID().toString()
                        FloatingReviewService.instance?.hideQuestion()
                    }
                    result.success(if (allowed) promptLease else null)
                }
                "endInApp" -> {
                    if (call.arguments == promptLease) { inAppPrompt = false; promptLease = null }
                    result.success(null)
                }
                "completed" -> {
                    val item = (call.arguments as? Number)?.toInt() ?: error("Missing item")
                    session?.let { completed(activity, it.account, item) }
                    FloatingReviewService.instance?.holdUntilNextReview()
                    result.success(null)
                }
                "snooze" -> { FloatingReviewService.instance?.holdUntilNextReview(); result.success(null) }
                else -> result.notImplemented()
            }
        } catch (error: Exception) {
            if (call.method == "start") starting = false
            result.error("review_overlay", error.message ?: "Floating review is unavailable", null)
        }
    }
}
