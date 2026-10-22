package com.mohammed.moeen.moeen_student_app

import android.app.KeyguardManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.graphics.PixelFormat
import android.graphics.Rect
import android.animation.ValueAnimator
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.view.WindowInsets
import android.view.ViewConfiguration
import android.view.animation.DecelerateInterpolator
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.io.FileDescriptor
import java.io.PrintWriter
import java.time.LocalDate
import java.time.OffsetDateTime
import java.util.UUID
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

class FloatingReviewService : Service() {
    companion object {
        @Volatile internal var instance: FloatingReviewService? = null
            private set
        private const val CHANNEL = "moeen_floating_review"
        private const val READY_CHANNEL = "moeen_review_ready"
        private const val NOTIFICATION = 64030
        private const val REMINDER = 64031
        private const val STOP = "moeen.review.STOP"
    }

    private val handler = Handler(Looper.getMainLooper())
    private val worker = Executors.newSingleThreadScheduledExecutor()
    private lateinit var windows: WindowManager
    private var window: View? = null
    private var bubble: FloatingReviewBubbleView? = null
    private var currentItem = 0
    private var currentAnswered = false
    private var snapshot: JSONObject? = null
    @Volatile private var connection: HttpURLConnection? = null
    @Volatile private var stopped = false
    @Volatile private var lastFetch = 0L
    @Volatile private var nextPrompt = 0L
    private var receiverRegistered = false
    private var ownerAccount: String? = null
    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) { hideQuestion() }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        ownerAccount = ReviewOverlayBridge.session?.account
        nextPrompt = ReviewOverlayBridge.prefs(this).getLong("snooze_${ownerAccount}", 0L)
        ReviewOverlayBridge.starting = false
        windows = getSystemService(WINDOW_SERVICE) as WindowManager
        val notifications = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        notifications.createNotificationChannel(NotificationChannel(CHANNEL, "المراجعة العائمة", NotificationManager.IMPORTANCE_LOW))
        notifications.createNotificationChannel(NotificationChannel(READY_CHANNEL, "بطاقات جاهزة للمراجعة", NotificationManager.IMPORTANCE_DEFAULT))
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(NOTIFICATION, sessionNotification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIFICATION, sessionNotification())
        }
        val filter = IntentFilter(Intent.ACTION_SCREEN_OFF)
        if (Build.VERSION.SDK_INT >= 33) registerReceiver(screenReceiver, filter, RECEIVER_NOT_EXPORTED)
        else registerReceiver(screenReceiver, filter)
        receiverRegistered = true
        worker.scheduleWithFixedDelay({ refresh() }, 0, 20, TimeUnit.SECONDS)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == STOP) {
            ownerAccount?.let { ReviewOverlayBridge.disableAutoStart(this, it) }
            ReviewOverlayBridge.starting = false
            stopSelf()
        } else if (ReviewOverlayBridge.session == null) stopSelf()
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun dump(fd: FileDescriptor, writer: PrintWriter, args: Array<out String>) {
        writer.println("Floating review: visible=${ReviewOverlayBridge.appVisible}, exam=${ReviewOverlayBridge.quizBlocked}, inApp=${ReviewOverlayBridge.inAppPrompt}, window=${window != null}")
        writer.println("Session: configured=${ReviewOverlayBridge.session != null}, ownerMatches=${ReviewOverlayBridge.session?.account == ownerAccount}, stopped=$stopped, snoozed=${isSnoozed()}")
        writer.println("Automatic: enabled=${ReviewOverlayBridge.autoStart(this)}")
        writer.println("Bubble: visible=${bubble != null}, due=${ReviewOverlayBridge.session?.let { dueItems(it).size } ?: 0}, answered=$currentAnswered")
        val queue = snapshot?.optJSONArray("queue")
        writer.println("Queue: count=${queue?.length() ?: 0}, lastFetch=$lastFetch, permission=${Settings.canDrawOverlays(this)}")
        writer.println("Settings: enabled=${snapshot?.optJSONObject("settings")?.optBoolean("smart_review_enabled", true)}")
        if (queue != null) for (index in 0 until minOf(queue.length(), 10)) {
            val item = queue.optJSONObject(index) ?: continue
            writer.println("Item $index: type=${item.optString("item_type")}, options=${item.optJSONArray("options")?.length()}, correct=${item.optInt("correct_option", -1)}, at=${item.optString("scheduled_at")}")
        }
    }

    private fun sessionNotification(): Notification {
        val stop = PendingIntent.getService(this, 0, Intent(this, FloatingReviewService::class.java).setAction(STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        return Notification.Builder(this, CHANNEL)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("جلسة المراجعة العائمة")
            .setContentText("نشطة خارج معين، وتتوقف أثناء الاختبارات والقفل")
            .setContentIntent(openApp())
            .setOngoing(true)
            .addAction(Notification.Action.Builder(null, "إيقاف", stop).build())
            .build()
    }

    private fun openApp(): PendingIntent = PendingIntent.getActivity(this, 0,
        Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

    private fun refresh() {
        val session = ReviewOverlayBridge.session ?: return
        if (stopped || session.account != ownerAccount) return
        try {
            flushAnswers(session)
            if (System.currentTimeMillis() - lastFetch >= TimeUnit.MINUTES.toMillis(5)) {
                val (code, response) = request(session, "/student/flashcards/daily-queue")
                if (code == 401 || code == 403) {
                    ReviewOverlayBridge.message = "انتهت صلاحية الجلسة. افتح معين وسجّل الدخول مجدداً."
                    handler.post { stopSelf() }
                    return
                }
                if (code !in 200..299) error("Review queue HTTP $code")
                if (ReviewOverlayBridge.session != session || stopped) return
                val next = response.getJSONObject("data")
                require(next.optJSONArray("queue") != null && next.optJSONObject("settings") != null) { "Invalid review queue" }
                snapshot = next
                ReviewOverlayBridge.prefs(this).edit().putString("queue_${session.account}", snapshot.toString()).apply()
                lastFetch = System.currentTimeMillis()
                ReviewOverlayBridge.message = ""
            }
        } catch (error: Exception) {
            if (!stopped) {
                ReviewOverlayBridge.message = "تعذر الاتصال. تُحفظ الإجابات وتُعاد مزامنتها تلقائياً."
                Log.w("MoeenReview", "Review refresh failed: ${error.javaClass.simpleName}")
            }
        }
        try {
            if (snapshot == null) {
                val cached = ReviewOverlayBridge.prefs(this).getString("queue_${session.account}", null)
                if (cached != null) snapshot = JSONObject(cached)
            }
        } catch (error: Exception) {
            Log.w("MoeenReview", "Cannot read cached review: ${error.javaClass.simpleName}")
        }
        handler.post {
            if (!stopped && ReviewOverlayBridge.session == session) evaluate(session)
        }
    }

    private fun flushAnswers(session: ReviewSession) {
        val pending = ReviewOverlayBridge.pending(this, session.account)
        for (index in 0 until minOf(pending.length(), 10)) {
            if (stopped || ReviewOverlayBridge.session != session) return
            val answer = pending.getJSONObject(index)
            val (code, _) = request(session, "/student/flashcards/progress", answer)
            if (code !in 200..299) error("Review answer HTTP $code")
            ReviewOverlayBridge.acknowledge(this, session.account, answer.getString("client_event_id"))
            lastFetch = 0
        }
    }

    private fun request(session: ReviewSession, path: String, body: JSONObject? = null): Pair<Int, JSONObject> {
        if (stopped || ReviewOverlayBridge.session != session) error("Session changed")
        val client = URL(session.baseUrl + path).openConnection() as HttpURLConnection
        connection = client
        try {
            client.instanceFollowRedirects = false
            client.connectTimeout = 10000
            client.readTimeout = 10000
            client.setRequestProperty("Accept", "application/json")
            client.setRequestProperty("Authorization", "Bearer ${session.token}")
            if (body != null) {
                client.requestMethod = "POST"
                client.doOutput = true
                client.setRequestProperty("Content-Type", "application/json")
                client.outputStream.use { it.write(body.toString().toByteArray(Charsets.UTF_8)) }
            }
            val code = client.responseCode
            val stream = if (code in 200..299) client.inputStream else client.errorStream
            val text = stream?.bufferedReader(Charsets.UTF_8)?.use { reader ->
                val buffer = CharArray(8192)
                val content = StringBuilder()
                var count = reader.read(buffer)
                while (count >= 0) {
                    require(content.length + count <= 2 * 1024 * 1024) { "Review response too large" }
                    content.append(buffer, 0, count)
                    count = reader.read(buffer)
                }
                content.toString()
            } ?: "{}"
            return code to (if (text.isBlank()) JSONObject() else JSONObject(text))
        } finally {
            client.disconnect()
            connection = null
        }
    }

    private fun evaluate(session: ReviewSession) {
        if (!canDisplay(session)) { hideQuestion(); return }
        val due = dueItems(session)
        if (due.isEmpty()) {
            hideBubble()
            (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).cancel(REMINDER)
            if (!currentAnswered) removeCard()
            else (window as? FloatingReviewCardView)?.showCompletion(0) { openNext(session) }
            return
        }
        if (System.currentTimeMillis() < nextPrompt) { hideQuestion(); return }
        if (!Settings.canDrawOverlays(this)) {
            hideQuestion()
            announceReady(session, due, fallback = true)
            return
        }
        if (window != null) {
            if (currentAnswered) {
                (window as? FloatingReviewCardView)?.showCompletion(due.size) { openNext(session) }
                return
            }
            if (due.any { it.optInt("item_id") == currentItem }) return
            removeCard()
        }
        showBubble(session, due.size)
        announceReady(session, due)
    }

    private fun canDisplay(session: ReviewSession): Boolean {
        if (stopped || session != ReviewOverlayBridge.session || session.account != ownerAccount) return false
        val power = getSystemService(POWER_SERVICE) as PowerManager
        val locked = (getSystemService(KEYGUARD_SERVICE) as KeyguardManager).isKeyguardLocked
        val settings = snapshot?.optJSONObject("settings") ?: return false
        if (!settings.optBoolean("smart_review_enabled", true)) return false
        val anchor = snapshot?.optJSONArray("queue")?.optJSONObject(0)?.optString("scheduled_at")
        val now = try { OffsetDateTime.now(OffsetDateTime.parse(anchor).offset) } catch (_: Exception) { OffsetDateTime.now() }
        return allowedTime(settings, now.hour * 60 + now.minute) &&
            !ReviewOverlayBridge.appVisible && !ReviewOverlayBridge.quizBlocked &&
            !ReviewOverlayBridge.inAppPrompt && !locked && power.isInteractive
    }

    private fun dueItems(session: ReviewSession): List<JSONObject> {
        val data = snapshot ?: return emptyList()
        val settings = data.optJSONObject("settings") ?: return emptyList()
        if (!settings.optBoolean("smart_review_enabled", true)) return emptyList()
        val queue = data.optJSONArray("queue") ?: return emptyList()
        val seen = ReviewOverlayBridge.seen(this, session.account).toSet()
        val due = linkedMapOf<Int, JSONObject>()
        for (index in 0 until queue.length()) {
            val item = queue.optJSONObject(index) ?: continue
            if (item.optInt("item_id") <= 0 || item.optString("front_content").isBlank()) continue
            if (item.optString("item_type") != "mcq" || item.optInt("item_id") in seen) continue
            val options = item.optJSONArray("options") ?: continue
            if (options.length() !in 2..6 || item.optInt("correct_option", -1) !in 0 until options.length()) continue
            val at = try { OffsetDateTime.parse(item.optString("scheduled_at")) } catch (_: Exception) { continue }
            val now = OffsetDateTime.now(at.offset)
            if (at.toLocalDate() != now.toLocalDate() || at.isAfter(now) || !allowedTime(settings, now.hour * 60 + now.minute)) continue
            due.putIfAbsent(item.getInt("item_id"), item)
        }
        return due.values.toList()
    }

    private fun openNext(session: ReviewSession) {
        if (!canDisplay(session) || !Settings.canDrawOverlays(this)) { hideQuestion(); return }
        val item = dueItems(session).firstOrNull()
        hideQuestion()
        if (item != null) showQuestion(session, item, snapshot?.optJSONObject("settings") ?: JSONObject())
        else (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).cancel(REMINDER)
    }

    private fun minute(value: String): Int? {
        val parts = value.split(':')
        val hour = parts.getOrNull(0)?.toIntOrNull() ?: return null
        val min = parts.getOrNull(1)?.toIntOrNull() ?: return null
        return if (hour in 0..23 && min in 0..59) hour * 60 + min else null
    }

    private fun inWindow(value: Int, start: Int, end: Int) = if (start <= end) value in start..end else value >= start || value <= end

    private fun allowedTime(settings: JSONObject, current: Int): Boolean {
        val start = minute(settings.optString("active_from_time"))
        val end = minute(settings.optString("active_to_time"))
        if ((start != null || end != null) && !inWindow(current, start ?: 0, end ?: 1439)) return false
        val quietStart = minute(settings.optString("quiet_start"))
        val quietEnd = minute(settings.optString("quiet_end"))
        return quietStart == null || quietEnd == null || !inWindow(current, quietStart, quietEnd)
    }

    private fun defer(settings: JSONObject) {
        nextPrompt = System.currentTimeMillis() + TimeUnit.MINUTES.toMillis(settings.optLong("smart_review_frequency_minutes", 30).coerceIn(1, 1440))
        ownerAccount?.let { ReviewOverlayBridge.prefs(this).edit().putLong("snooze_$it", nextPrompt).apply() }
    }

    private fun announceReady(session: ReviewSession, due: List<JSONObject>, fallback: Boolean = false) {
        val notifications = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (!notifications.areNotificationsEnabled()) return
        val prefs = ReviewOverlayBridge.prefs(this)
        val day = LocalDate.now().toString()
        val previous = if (prefs.getString("notice_day_${session.account}", "") == day)
            prefs.getStringSet("notice_ids_${session.account}", emptySet()).orEmpty() else emptySet()
        val ids = due.map { it.getInt("item_id").toString() }.toSet()
        if (ids.all { it in previous }) {
            val existing = notifications.activeNotifications.firstOrNull { it.id == REMINDER } ?: return
            if (existing.notification.number == due.size) return
        }
        if (fallback) ReviewOverlayBridge.message = "إذن الظهور غير متاح؛ تُستخدم تذكيرات عادية."
        val notice = Notification.Builder(this, READY_CHANNEL).setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("لديك كرت جاهز للمراجعة")
            .setContentText(if (due.size == 1) "بطاقة واحدة بانتظارك" else "${due.size} بطاقات بانتظارك")
            .setNumber(due.size).setOnlyAlertOnce(true).setContentIntent(openApp()).setAutoCancel(true).build()
        try {
            notifications.notify(REMINDER, notice)
            prefs.edit().putString("notice_day_${session.account}", day)
                .putStringSet("notice_ids_${session.account}", previous + ids).apply()
        } catch (error: SecurityException) { Log.w("MoeenReview", "Review notification permission unavailable") }
    }

    private fun fallback() {
        ReviewOverlayBridge.message = "إذن الظهور غير متاح؛ تُستخدم تذكيرات عادية."
        val notice = Notification.Builder(this, CHANNEL).setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("حان وقت المراجعة")
            .setContentText("افتح معين للإجابة عن سؤال المراجعة")
            .setContentIntent(openApp()).setAutoCancel(true).build()
        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).notify(REMINDER, notice)
    }

    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()

    private fun safeArea(): Rect {
        if (Build.VERSION.SDK_INT >= 30) {
            val metrics = windows.currentWindowMetrics
            val insets = metrics.windowInsets.getInsetsIgnoringVisibility(WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout())
            return Rect(insets.left, insets.top, metrics.bounds.width() - insets.right, metrics.bounds.height() - insets.bottom)
        }
        val statusId = resources.getIdentifier("status_bar_height", "dimen", "android")
        val top = if (statusId != 0) resources.getDimensionPixelSize(statusId) else dp(24)
        return Rect(0, top, resources.displayMetrics.widthPixels, resources.displayMetrics.heightPixels)
    }

    private fun showBubble(session: ReviewSession, count: Int) {
        bubble?.let { it.updateCount(count); return }
        val settings = snapshot?.optJSONObject("settings") ?: return
        val view = FloatingReviewBubbleView(this, onOpen = { openNext(session) }, onSnooze = { defer(settings); hideQuestion() })
        view.updateCount(count)
        val area = safeArea()
        val size = dp(76)
        val left = area.left + dp(4)
        val right = maxOf(left, area.right - size - dp(4))
        val top = area.top + dp(4)
        val bottom = maxOf(top, area.bottom - size - dp(4))
        val prefs = ReviewOverlayBridge.prefs(this)
        val params = WindowManager.LayoutParams(size, size, WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT).apply {
            gravity = Gravity.TOP or Gravity.LEFT
            x = left + ((right - left) * prefs.getFloat("bubble_x_${session.account}", 1f).coerceIn(0f, 1f)).toInt()
            y = top + ((bottom - top) * prefs.getFloat("bubble_y_${session.account}", 0f).coerceIn(0f, 1f)).toInt()
        }
        var downX = 0f; var downY = 0f; var originX = 0; var originY = 0
        var dragging = false; var longPressed = false
        val longPress = Runnable { if (!dragging && bubble === view) { longPressed = true; view.showActions() } }
        view.setOnTouchListener { _, event ->
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    view.animate().cancel(); view.translationX = 0f
                    downX = event.rawX; downY = event.rawY; originX = params.x; originY = params.y
                    dragging = false; longPressed = false
                    handler.postDelayed(longPress, ViewConfiguration.getLongPressTimeout().toLong())
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - downX; val dy = event.rawY - downY
                    if (kotlin.math.abs(dx) + kotlin.math.abs(dy) > ViewConfiguration.get(this).scaledTouchSlop) {
                        dragging = true
                        handler.removeCallbacks(longPress)
                    }
                    if (dragging && bubble === view) {
                        params.x = (originX + dx.toInt()).coerceIn(left, right)
                        params.y = (originY + dy.toInt()).coerceIn(top, bottom)
                        try { windows.updateViewLayout(view, params) }
                        catch (error: IllegalArgumentException) { hideBubble() }
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    handler.removeCallbacks(longPress)
                    if (dragging) prefs.edit()
                        .putFloat("bubble_x_${session.account}", if (right > left) (params.x - left).toFloat() / (right - left) else 0f)
                        .putFloat("bubble_y_${session.account}", if (bottom > top) (params.y - top).toFloat() / (bottom - top) else 0f).apply()
                    else if (!longPressed) view.performClick()
                    true
                }
                MotionEvent.ACTION_CANCEL -> { handler.removeCallbacks(longPress); true }
                else -> false
            }
        }
        try {
            windows.addView(view, params)
            bubble = view
            if (ValueAnimator.areAnimatorsEnabled()) {
                view.translationX = size.toFloat()
                view.animate().translationX(0f).setDuration(450).setInterpolator(DecelerateInterpolator()).start()
            }
        } catch (error: RuntimeException) {
            Log.w("MoeenReview", "Bubble unavailable: ${error.javaClass.simpleName}")
            defer(settings)
        }
    }

    private fun hideBubble() {
        bubble?.let {
            it.animate().cancel()
            try { windows.removeView(it) }
            catch (error: IllegalArgumentException) { Log.w("MoeenReview", "Bubble already detached") }
        }
        bubble = null
    }

    private fun showQuestion(session: ReviewSession, item: JSONObject, settings: JSONObject) {
        val options = item.optJSONArray("options") ?: return
        val correct = item.optInt("correct_option", -1)
        if (options.length() !in 2..6 || correct !in 0 until options.length()) return
        val panel = FloatingReviewCardView(this, item,
            onClose = { removeCard(); evaluate(session) },
            onSnooze = { defer(settings); hideQuestion() })
        val choices = panel.choices
        for (index in 0 until options.length()) {
            val choice = choices[index]
            choice.setOnClickListener {
                if (!choice.isEnabled) return@setOnClickListener
                if (stopped || ReviewOverlayBridge.session != session || ReviewOverlayBridge.quizBlocked) { hideQuestion(); return@setOnClickListener }
                choices.forEach { it.isEnabled = false }
                try {
                    synchronized(ReviewOverlayBridge.journalLock) {
                        val pending = ReviewOverlayBridge.pending(this, session.account)
                        pending.put(JSONObject().put("client_event_id", UUID.randomUUID().toString())
                            .put("item_id", item.getInt("item_id"))
                            .put("response_level", if (index == correct) "easy" else "hard"))
                        val ids = (ReviewOverlayBridge.seen(this, session.account) + item.getInt("item_id")).distinct()
                        check(ReviewOverlayBridge.prefs(this).edit()
                            .putString("answers_${session.account}", pending.toString())
                            .putString("seen_day_${session.account}", LocalDate.now().toString())
                            .putString("seen_${session.account}", JSONArray(ids).toString()).commit())
                    }
                    panel.showAnswer(index, index == correct,
                        if (index == correct) "إجابة صحيحة · حُفظت للمزامنة" else "الإجابة الصحيحة: ${options.getString(correct)} · حُفظت للمزامنة")
                    currentAnswered = true
                    val remaining = dueItems(session).size
                    panel.showCompletion(remaining) { openNext(session) }
                    lastFetch = 0
                    worker.execute { refresh() }
                    if (remaining == 0) handler.postDelayed({
                        if (currentItem == item.optInt("item_id") && currentAnswered) { removeCard(); evaluate(session) }
                    }, 3000)
                } catch (error: Exception) {
                    Log.e("MoeenReview", "Cannot persist answer", error)
                    panel.showError("تعذر حفظ الإجابة. حاول مجدداً.")
                    choices.forEach { it.isEnabled = true }
                }
            }
        }
        val width = minOf(dp(360), resources.displayMetrics.widthPixels - dp(24))
        val params = WindowManager.LayoutParams(width, -2, WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT).apply { gravity = Gravity.TOP or Gravity.START; x = dp(12); y = dp(80) }
        var startX = 0; var startY = 0; var touchX = 0f; var touchY = 0f
        panel.dragHandle.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> { startX = params.x; startY = params.y; touchX = event.rawX; touchY = event.rawY; true }
                MotionEvent.ACTION_MOVE -> {
                    params.x = (startX + event.rawX.toInt() - touchX.toInt()).coerceIn(0, maxOf(0, resources.displayMetrics.widthPixels - width))
                    params.y = (startY + event.rawY.toInt() - touchY.toInt()).coerceIn(0, maxOf(0, resources.displayMetrics.heightPixels - panel.height))
                    if (window != null) {
                        try { windows.updateViewLayout(panel, params) }
                        catch (error: IllegalArgumentException) { Log.w("MoeenReview", "Overlay detached while moving"); hideQuestion() }
                    }
                    true
                }
                else -> false
            }
        }
        try {
            windows.addView(panel, params)
            window = panel
            currentItem = item.getInt("item_id")
            currentAnswered = false
            (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).cancel(REMINDER)
        } catch (error: RuntimeException) {
            Log.w("MoeenReview", "Overlay unavailable: ${error.javaClass.simpleName}")
            fallback()
            defer(settings)
        }
    }

    internal fun hideQuestion() {
        if (Looper.myLooper() != Looper.getMainLooper()) { handler.post { hideQuestion() }; return }
        hideBubble()
        removeCard()
    }

    private fun removeCard() {
        window?.let {
            try { windows.removeView(it) }
            catch (error: IllegalArgumentException) { Log.w("MoeenReview", "Overlay already detached") }
        }
        window = null
        currentItem = 0
        currentAnswered = false
    }

    override fun onConfigurationChanged(newConfig: android.content.res.Configuration) {
        super.onConfigurationChanged(newConfig)
        hideQuestion()
        ReviewOverlayBridge.session?.let { evaluate(it) }
    }

    internal fun holdUntilNextReview() {
        defer(snapshot?.optJSONObject("settings") ?: JSONObject())
        hideQuestion()
    }

    internal fun isSnoozed() = System.currentTimeMillis() < nextPrompt

    override fun onDestroy() {
        stopped = true
        connection?.disconnect()
        worker.shutdownNow()
        handler.removeCallbacksAndMessages(null)
        hideQuestion()
        if (receiverRegistered) unregisterReceiver(screenReceiver)
        if (instance === this) instance = null
        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).cancel(REMINDER)
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }
}
