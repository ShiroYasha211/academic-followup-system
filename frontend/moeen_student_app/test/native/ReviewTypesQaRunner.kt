package com.mohammed.moeen.moeen_student_app

import android.app.Instrumentation
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Bitmap
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.ScrollView
import android.widget.FrameLayout
import android.widget.TextView
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.time.OffsetDateTime

// Run only in the isolated native QA app, never in the production account.
class ReviewTypesQaRunner : Instrumentation() {
    private lateinit var activity: MainActivity
    private val account = "qa_review_types"
    private val report = StringBuilder()
    private var passed = 0

    override fun onCreate(arguments: Bundle?) {
        super.onCreate(arguments)
        start()
    }

    private fun main(action: () -> Unit) {
        var failure: Throwable? = null
        runOnMainSync { try { action() } catch (error: Throwable) { failure = error } }
        failure?.let { throw it }
        waitForIdleSync()
    }

    private fun call(method: String, arguments: Any?) = main {
        ReviewOverlayBridge.handle(activity, MethodCall(method, arguments), object : MethodChannel.Result {
            override fun success(result: Any?) = Unit
            override fun error(code: String, message: String?, details: Any?) = error("$code: $message")
            override fun notImplemented() = error("Not implemented: $method")
        })
    }

    private fun field(target: Any, name: String) = target.javaClass.getDeclaredField(name).apply { isAccessible = true }.get(target)
    private fun setField(target: Any, name: String, value: Any) = target.javaClass.getDeclaredField(name).apply { isAccessible = true }.set(target, value)
    private fun card() = field(FloatingReviewService.instance!!, "window") as? FloatingReviewCardView
    private fun bubble() = field(FloatingReviewService.instance!!, "bubble") as? FloatingReviewBubbleView
    private fun descendants(view: View): List<View> = listOf(view) + if (view is ViewGroup)
        (0 until view.childCount).flatMap { descendants(view.getChildAt(it)) } else emptyList()
    private fun label(view: View, value: String) = descendants(view).filterIsInstance<TextView>().single { it.text == value }
    private fun record(name: String, action: () -> Unit) {
        action()
        passed++
        report.append("PASS: $name\n")
        sendStatus(0, Bundle().apply { putString("stream", "PASS: $name\n") })
    }

    private fun waitUntil(label: String, condition: () -> Boolean) {
        val deadline = System.currentTimeMillis() + 6000
        while (System.currentTimeMillis() < deadline) {
            waitForIdleSync()
            if (condition()) return
            Thread.sleep(60)
        }
        check(condition()) { "Timeout: $label" }
    }

    private fun item(id: Int, type: String) = JSONObject().put("item_id", id).put("item_type", type)
        .put("review_key", "qa-types:$id").put("pack_title", "مراجعة محلية معزولة")
        .put("pack_color", "#406AB4").put("front_content", "ما الوظيفة الأساسية للقلب؟")
        .put("back_content", "ضخ الدم إلى أعضاء الجسم لتزويدها بالأكسجين والمواد الغذائية.")
        .put("options", if (type == "mcq") JSONArray(listOf("ضخ الدم", "هضم الطعام")) else JSONObject.NULL)
        .put("correct_option", if (type == "mcq") 0 else -1)
        .put("scheduled_at", OffsetDateTime.now().minusMinutes(1).toString())

    private fun evaluate(items: List<JSONObject>) = main {
        val service = FloatingReviewService.instance!!
        setField(service, "snapshot", JSONObject().put("queue", JSONArray(items))
            .put("settings", JSONObject().put("smart_review_enabled", true)))
        setField(service, "lastFetch", System.currentTimeMillis())
        service.javaClass.getDeclaredMethod("evaluate", ReviewSession::class.java).apply { isAccessible = true }
            .invoke(service, ReviewOverlayBridge.session)
    }

    private fun screenshot(filename: String) {
        val bitmap = uiAutomation.takeScreenshot() ?: error("Native window screenshot unavailable")
        File(targetContext.getExternalFilesDir(null), filename).outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
        bitmap.recycle()
    }

    override fun onStart() {
        var failure: Throwable? = null
        var isolated = false
        try {
            check(targetContext.packageName == "com.moeen.nativereviewqa") { "Isolated QA package required" }
            isolated = true
            check(ReviewOverlayBridge.prefs(targetContext).edit().clear().commit())
            activity = startActivitySync(Intent(targetContext, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) as MainActivity
            call("configure", mapOf("account" to account, "token" to "local-fixture-only", "base_url" to "https://127.0.0.1:1"))
            call("setMode", "floating")
            call("setAutoStart", true)
            waitUntil("foreground service start") { FloatingReviewService.instance != null }
            main { activity.startActivity(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
            waitUntil("activity background transition") { !ReviewOverlayBridge.appVisible }

            val qa = item(801, "qa")
            val flash = item(802, "flash_card")
            val mcq = item(803, "mcq")
            val queue = listOf(qa, flash, mcq)
            record("Mixed bubble includes QA, flashcards and MCQ, excludes invalid, duplicate and future entries") {
                evaluate(queue + listOf(qa, item(804, "qa").put("back_content", JSONObject.NULL),
                    item(805, "flash_card").put("back_content", ""), item(806, "mcq").put("correct_option", 9),
                    item(807, "qa").put("scheduled_at", OffsetDateTime.now().plusHours(1).toString()), item(808, "one_line")))
                check(bubble()!!.contentDescription.contains("3 بطاقة"))
                check(card() == null)
            }
            record("Closing QA and revealing its answer do not complete a review") {
                evaluate(queue)
                main { bubble()!!.performClick() }
                main {
                    val card = card()!!
                    check(card.choices.isEmpty() && !card.answerRevealed)
                    check(!label(card, qa.getString("back_content")).isShown)
                    card.ratings.getValue("easy").performClick()
                    check(ReviewOverlayBridge.pending(activity, account).length() == 0)
                    label(card, "إظهار الإجابة").performClick()
                }
                waitUntil("answer layout") { card()!!.width > 0 && card()!!.ratings.values.all { it.isShown } }
                uiAutomation.waitForIdle(200, 2000)
                screenshot("qa-answer.png")
                main {
                    check(card()!!.ratings.values.all { it.isShown })
                    check(ReviewOverlayBridge.pending(activity, account).length() == 0)
                    descendants(card()!!).single { it.contentDescription == "إغلاق السؤال" }.performClick()
                }
                check(card() == null && bubble()!!.contentDescription.contains("3 بطاقة"))
            }
            record("QA records the chosen medium rating exactly once and retains Next") {
                main {
                    bubble()!!.performClick()
                    check(!card()!!.answerRevealed)
                    label(card()!!, "إظهار الإجابة").performClick()
                    card()!!.ratings.getValue("medium").performClick()
                    card()!!.ratings.getValue("hard").performClick()
                    check(card()!!.ratings.values.none { it.isEnabled })
                    check((field(card()!!, "footer") as TextView).text.contains("التالي"))
                }
                val pending = ReviewOverlayBridge.pending(activity, account)
                check(pending.length() == 1 && pending.getJSONObject(0).getString("response_level") == "medium")
                check(pending.getJSONObject(0).getString("review_key") == qa.getString("review_key"))
            }
            record("Next opens the flashcard, which saves a hard rating only after revealing its back") {
                main {
                    (field(card()!!, "footer") as View).performClick()
                    check(card()!!.choices.isEmpty() && !card()!!.answerRevealed)
                    check(label(card()!!, "بطاقة تعليمية").isShown)
                    label(card()!!, "إظهار الإجابة").performClick()
                    card()!!.ratings.getValue("hard").performClick()
                }
                check(ReviewOverlayBridge.pending(activity, account).length() == 2)
                check(ReviewOverlayBridge.pending(activity, account).getJSONObject(1).getString("response_level") == "hard")
            }
            record("Existing MCQ selection still records once and completes the mixed queue") {
                main {
                    (field(card()!!, "footer") as View).performClick()
                    check(card()!!.ratings.isEmpty() && card()!!.choices.size == 2)
                    card()!!.choices[0].performClick()
                    card()!!.choices[1].performClick()
                    check(ReviewOverlayBridge.pending(activity, account).length() == 3)
                    (field(card()!!, "footer") as View).performClick()
                    check(card() == null && bubble() == null)
                }
            }
            record("QA and flashcards still respect foreground and exam suppression") {
                val next = listOf(item(809, "qa"))
                main { ReviewOverlayBridge.appVisible = true }
                evaluate(next); check(bubble() == null)
                main { ReviewOverlayBridge.appVisible = false }
                evaluate(next); check(bubble() != null)
                main { ReviewOverlayBridge.blockQuiz(true) }; check(bubble() == null && card() == null)
                main { ReviewOverlayBridge.blockQuiz(false) }
            }
            record("Long answers scroll at large Arabic text scale without hiding the ratings") {
                activity = startActivitySync(Intent(targetContext, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)) as MainActivity
                lateinit var view: FloatingReviewCardView
                lateinit var scroll: ScrollView
                main {
                    val context = activity.createConfigurationContext(Configuration(activity.resources.configuration).apply { fontScale = 1.6f })
                    view = FloatingReviewCardView(context, flash.put("back_content", "إجابة عربية مطولة للتحقق من قراءة المحتوى كاملاً والتنقل إلى أزرار التقييم. ".repeat(35)), {}, {})
                    val root = FrameLayout(activity).apply { setBackgroundColor(0xFFE6EDF4.toInt()) }
                    root.addView(view, FrameLayout.LayoutParams((320 * context.resources.displayMetrics.density).toInt(), -2, Gravity.CENTER))
                    activity.setContentView(root)
                    label(view, "إظهار الإجابة").performClick()
                    scroll = descendants(view).filterIsInstance<ScrollView>().single()
                }
                waitUntil("large-text window layout") { view.width > 0 && activity.hasWindowFocus() }
                main {
                    check(view.height <= (view.resources.displayMetrics.heightPixels * .79).toInt())
                    check(scroll.getChildAt(0).height > scroll.height)
                }
                uiAutomation.waitForIdle(500, 3000)
                val before = uiAutomation.takeScreenshot() ?: error("Native window screenshot unavailable")
                main {
                    scroll.isSmoothScrollingEnabled = false
                    scroll.fullScroll(View.FOCUS_DOWN)
                    check(scroll.scrollY > 0)
                    check(view.ratings.values.all { it.width > 0 && it.height >= (48 * view.resources.displayMetrics.density).toInt() })
                    check(view.ratings.values.all { it.lineCount == 1 })
                }
                Thread.sleep(250)
                val after = uiAutomation.takeScreenshot() ?: error("Native window screenshot unavailable")
                File(targetContext.getExternalFilesDir(null), "long-answer-before.png").outputStream().use { before.compress(Bitmap.CompressFormat.PNG, 100, it) }
                File(targetContext.getExternalFilesDir(null), "long-answer.png").outputStream().use { after.compress(Bitmap.CompressFormat.PNG, 100, it) }
                check(!before.sameAs(after)) { "Scrolling did not change the rendered answer" }
                val location = IntArray(2)
                main { view.getLocationOnScreen(location) }
                fun unchanged(top: Int, height: Int): Boolean {
                    val first = Bitmap.createBitmap(before, location[0], location[1] + top, view.width, height)
                    val second = Bitmap.createBitmap(after, location[0], location[1] + top, view.width, height)
                    val result = first.sameAs(second)
                    first.recycle(); second.recycle()
                    return result
                }
                check(unchanged(0, view.getChildAt(0).bottom)) { "Scrolling changed the fixed header" }
                val footer = view.getChildAt(view.childCount - 1)
                check(unchanged(footer.top, view.height - footer.top)) { "Scrolling changed the fixed footer" }
                before.recycle(); after.recycle()
            }
        } catch (error: Throwable) {
            failure = error
            report.append("FAIL: ${error.stackTraceToString()}\n")
        } finally {
            if (isolated) {
                main {
                    targetContext.stopService(Intent(targetContext, FloatingReviewService::class.java))
                    if (::activity.isInitialized) activity.finish()
                }
                File(targetContext.getExternalFilesDir(null), "types-report.txt").writeText(report.toString())
            }
            finish(if (failure == null) -1 else 0, Bundle().apply { putString("stream", "$passed passed\n$report") })
        }
    }
}
