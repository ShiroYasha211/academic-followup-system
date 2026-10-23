package com.mohammed.moeen.moeen_student_app

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.RippleDrawable
import android.os.Build
import android.content.res.ColorStateList
import android.text.TextUtils
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import org.json.JSONObject

internal class FloatingReviewCardView(
    context: Context,
    item: JSONObject,
    onClose: () -> Unit,
    onSnooze: () -> Unit,
) : LinearLayout(context) {
    companion object {
        private const val INK = 0xFF172B4D.toInt()
        private const val BLUE = 0xFF406AB4.toInt()
        private const val SECONDARY = 0xFF64748B.toInt()
        private const val BORDER = 0xFFCBD5E1.toInt()
        private const val MUTED = 0xFF94A3B8.toInt()
        private const val SURFACE = 0xFFF8FAFE.toInt()
        private const val SUCCESS = 0xFF10B981.toInt()
        private const val ERROR = 0xFFBE123C.toInt()
    }

    private val heavy = Typeface.createFromAsset(context.assets, "flutter_assets/assets/fonts/Cairo-Black.ttf")
    private val bold = Typeface.createFromAsset(context.assets, "flutter_assets/assets/fonts/Cairo-ExtraBold.ttf")
    private val regular = Typeface.createFromAsset(context.assets, "flutter_assets/assets/fonts/Cairo-SemiBold.ttf")
    private val symbols = Typeface.createFromAsset(context.assets, "flutter_assets/fonts/MaterialIcons-Regular.otf")
    private val choiceLabels = mutableListOf<TextView>()
    private val choiceIcons = mutableListOf<TextView>()
    val choices = mutableListOf<View>()
    val ratings = linkedMapOf<String, TextView>()
    var answerRevealed = false
        private set
    val dragHandle: View
    private val header: LinearLayout
    private val footer: TextView
    private val feedback: TextView
    private var bodyHeightLimit = resources.displayMetrics.heightPixels

    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
    private fun tint(color: Int, alpha: Int) = (color and 0x00FFFFFF) or (alpha shl 24)
    private fun shape(color: Int, radius: Int, stroke: Int? = null, selected: Boolean = false) =
        GradientDrawable().apply {
            setColor(color)
            cornerRadius = dp(radius).toFloat()
            if (stroke != null) setStroke(if (selected) dp(2) else maxOf(1, dp(1)), stroke)
        }

    private fun text(value: String, size: Float, color: Int = INK, weight: Typeface = bold) = TextView(context).apply {
        text = value
        textSize = size
        typeface = weight
        setTextColor(color)
        includeFontPadding = false
        textDirection = TEXT_DIRECTION_FIRST_STRONG
        setLineSpacing(0f, 1.35f)
    }

    private fun icon(codePoint: Int, size: Float, color: Int) = text(String(Character.toChars(codePoint)), size, color, symbols).apply {
        setTextSize(TypedValue.COMPLEX_UNIT_DIP, size)
        gravity = Gravity.CENTER
        importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_NO
    }

    private fun space(height: Int) = addView(View(context), LayoutParams(1, dp(height)))

    private fun action(label: String, color: Int) = object : TextView(context) {
        override fun getAccessibilityClassName(): CharSequence = Button::class.java.name
    }.apply {
        text = label
        textSize = 14f
        typeface = bold
        setTextColor(color)
        gravity = Gravity.CENTER
        minimumHeight = dp(48)
        setPadding(dp(8), dp(10), dp(8), dp(10))
        background = RippleDrawable(ColorStateList.valueOf(tint(color, 26)), shape(tint(color, 20), 16), null)
        isFocusable = true
        isClickable = true
    }

    init {
        orientation = VERTICAL
        layoutDirection = LAYOUT_DIRECTION_RTL
        setPadding(dp(20), dp(16), dp(20), dp(16))
        background = shape(Color.WHITE, 30, BORDER)
        elevation = dp(10).toFloat()
        clipToOutline = true
        val accent = try {
            Color.parseColor(item.optString("item_color", item.optString("pack_color", "#4338ca")))
        } catch (_: IllegalArgumentException) { BLUE }
        if (Build.VERSION.SDK_INT >= 28) {
            outlineAmbientShadowColor = tint(accent, 46)
            outlineSpotShadowColor = tint(accent, 46)
        }

        header = LinearLayout(context).apply { gravity = Gravity.CENTER_VERTICAL }
        val identity = LinearLayout(context).apply {
            gravity = Gravity.CENTER_VERTICAL
            minimumHeight = dp(48)
        }
        identity.addView(icon(0xf59c, 23f, accent).apply { background = shape(tint(accent, 31), 16) }, LayoutParams(dp(44), dp(44)))
        val title = LinearLayout(context).apply {
            orientation = VERTICAL
            setPadding(dp(10), 0, dp(10), 0)
        }
        title.addView(text(item.optString("pack_title"), 15f, weight = heavy).apply {
            maxLines = 1
            ellipsize = TextUtils.TruncateAt.END
        })
        title.addView(text("مراجعة · معين", 11f, SECONDARY, regular))
        identity.addView(title, LayoutParams(0, -2, 1f))
        dragHandle = identity
        header.addView(identity, LayoutParams(0, -2, 1f))
        header.addView(icon(0xf647, 20f, SECONDARY).apply {
            background = shape(SURFACE, 16)
            contentDescription = "إغلاق السؤال"
            tooltipText = contentDescription
            importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_YES
            isFocusable = true
            setOnClickListener { onClose() }
        }, LayoutParams(dp(48), dp(48)))
        addView(header, LayoutParams(-1, -2))
        space(16)

        val content = LinearLayout(context).apply { orientation = VERTICAL }
        val type = item.optString("item_type")
        val typeLabel = when (type) {
            "mcq" -> "اختيارات"
            "qa" -> "سؤال وجواب"
            else -> "بطاقة تعليمية"
        }
        content.addView(text(typeLabel, 12f, BLUE, heavy).apply {
            setPadding(dp(10), dp(6), dp(10), dp(6))
            background = shape(tint(BLUE, 26), 12)
        }, LayoutParams(-2, -2).apply { gravity = Gravity.RIGHT; bottomMargin = dp(20) })
        content.addView(text(item.optString("front_content"), 24f, weight = heavy).apply {
            gravity = Gravity.CENTER
        }, LayoutParams(-1, -2).apply { bottomMargin = dp(24) })

        val options = if (type == "mcq") item.optJSONArray("options") else null
        for (index in 0 until (options?.length() ?: 0)) {
            val option = options!!.getString(index)
            val row = object : LinearLayout(context) {
                override fun getAccessibilityClassName(): CharSequence = Button::class.java.name
            }.apply {
                gravity = Gravity.CENTER_VERTICAL
                minimumHeight = dp(48)
                setPadding(dp(14), dp(13), dp(14), dp(13))
                background = RippleDrawable(ColorStateList.valueOf(tint(accent, 26)), shape(SURFACE, 16, BORDER), null)
                contentDescription = option
                isFocusable = true
                isClickable = true
            }
            val indicator = icon(0xf00d8, 20f, MUTED)
            row.addView(indicator, LayoutParams(dp(20), dp(24)))
            val label = text(option, 14f, 0xFF475569.toInt()).apply {
                gravity = Gravity.START
                importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_NO
            }
            row.addView(label, LayoutParams(0, -2, 1f).apply { marginStart = dp(10) })
            choiceLabels.add(label)
            choiceIcons.add(indicator)
            choices.add(row)
            content.addView(row, LayoutParams(-1, -2).apply { bottomMargin = dp(10) })
        }
        if (type == "qa" || type == "flash_card") {
            val answer = LinearLayout(context).apply {
                orientation = VERTICAL
                visibility = GONE
            }
            val answerTitle = text("الإجابة", 12f, BLUE, heavy)
            answer.addView(answerTitle, LayoutParams(-1, -2).apply { bottomMargin = dp(10) })
            answer.addView(text(item.optString("back_content"), 18f, weight = regular).apply {
                accessibilityLiveRegion = ACCESSIBILITY_LIVE_REGION_POLITE
            }, LayoutParams(-1, -2).apply { bottomMargin = dp(16) })
            val ratingRow = object : LinearLayout(context) {
                override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
                    val labelWidth = ratings.values.maxOfOrNull {
                        kotlin.math.ceil(it.paint.measureText(it.text.toString()).toDouble()).toInt() + it.paddingLeft + it.paddingRight
                    } ?: 0
                    val stacked = MeasureSpec.getSize(widthMeasureSpec) < labelWidth * childCount + dp(8) * (childCount - 1)
                    orientation = if (stacked) VERTICAL else HORIZONTAL
                    for (index in 0 until childCount) {
                        (getChildAt(index).layoutParams as LayoutParams).apply {
                            width = if (stacked) -1 else 0
                            weight = if (stacked) 0f else 1f
                            marginStart = if (!stacked && index > 0) dp(8) else 0
                            topMargin = if (stacked && index > 0) dp(8) else 0
                        }
                    }
                    super.onMeasure(widthMeasureSpec, heightMeasureSpec)
                }
            }.apply { visibility = GONE }
            listOf(Triple("easy", "سهل", 0xFF065F46.toInt()),
                Triple("medium", "متوسط", 0xFF92400E.toInt()),
                Triple("hard", "صعب", ERROR)).forEachIndexed { index, (level, label, color) ->
                val button = action(label, color)
                ratings[level] = button
                ratingRow.addView(button, LayoutParams(0, -2, 1f).apply { if (index > 0) marginStart = dp(8) })
            }
            content.addView(action("إظهار الإجابة", BLUE).apply {
                setOnClickListener {
                    answerRevealed = true
                    visibility = GONE
                    answer.visibility = VISIBLE
                    ratingRow.visibility = VISIBLE
                    answerTitle.post {
                        answerTitle.requestRectangleOnScreen(android.graphics.Rect(0, 0, answerTitle.width, answerTitle.height), false)
                    }
                }
            }, LayoutParams(-1, -2))
            content.addView(answer, LayoutParams(-1, -2))
            content.addView(ratingRow, LayoutParams(-1, -2).apply { bottomMargin = dp(10) })
        }
        feedback = text("", 13f, weight = regular).apply {
            visibility = GONE
            accessibilityLiveRegion = ACCESSIBILITY_LIVE_REGION_POLITE
            setPadding(dp(12), dp(10), dp(12), dp(10))
        }
        content.addView(feedback, LayoutParams(-1, -2))
        val scroll = object : ScrollView(context) {
            override fun onSizeChanged(width: Int, height: Int, oldWidth: Int, oldHeight: Int) {
                super.onSizeChanged(width, height, oldWidth, oldHeight)
                clipBounds = android.graphics.Rect(0, 0, width, height)
            }

            override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
                super.onMeasure(widthMeasureSpec, MeasureSpec.makeMeasureSpec(bodyHeightLimit, MeasureSpec.AT_MOST))
            }
        }.apply {
            isFillViewport = false
            clipToPadding = false
            addView(content)
        }
        addView(scroll, LayoutParams(-1, -2))
        space(12)
        footer = text("تأجيل", 14f, BLUE).apply {
            gravity = Gravity.CENTER
            minimumHeight = dp(48)
            background = RippleDrawable(ColorStateList.valueOf(tint(BLUE, 26)), shape(tint(BLUE, 20), 16), null)
            isFocusable = true
            setOnClickListener { onSnooze() }
        }
        addView(footer, LayoutParams(-1, -2))
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val innerWidth = MeasureSpec.makeMeasureSpec((MeasureSpec.getSize(widthMeasureSpec) - paddingLeft - paddingRight).coerceAtLeast(0), MeasureSpec.EXACTLY)
        val naturalHeight = MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED)
        header.measure(innerWidth, naturalHeight)
        footer.measure(innerWidth, naturalHeight)
        val maximumHeight = (resources.displayMetrics.heightPixels * 0.78).toInt()
        bodyHeightLimit = (maximumHeight - paddingTop - paddingBottom - header.measuredHeight - footer.measuredHeight - dp(28)).coerceAtLeast(dp(64))
        super.onMeasure(widthMeasureSpec, heightMeasureSpec)
    }

    fun showAnswer(index: Int, correct: Boolean, message: String) {
        val stateColor = if (correct) SUCCESS else ERROR
        choices[index].apply {
            isSelected = true
            background = shape(tint(stateColor, 31), 16, stateColor, selected = true)
            if (Build.VERSION.SDK_INT >= 30) stateDescription = if (correct) "إجابة صحيحة" else "إجابة غير صحيحة"
        }
        choiceLabels[index].setTextColor(INK)
        choiceIcons[index].apply {
            text = String(Character.toChars(if (correct) 0xf635 else 0xf616))
            setTextColor(stateColor)
        }
        feedback.apply {
            text = message
            setTextColor(if (correct) 0xFF065F46.toInt() else ERROR)
            background = shape(tint(stateColor, 20), 12)
            visibility = VISIBLE
        }
        feedback.post { feedback.requestRectangleOnScreen(android.graphics.Rect(0, 0, feedback.width, feedback.height), false) }
    }

    fun showError(message: String) {
        feedback.apply {
            text = message
            setTextColor(ERROR)
            background = shape(tint(ERROR, 20), 12)
            visibility = VISIBLE
        }
    }

    fun setAnswering(answering: Boolean) {
        choices.forEach { it.isEnabled = !answering }
        ratings.values.forEach { it.isEnabled = !answering }
    }

    fun showReviewRecorded(level: String) {
        ratings[level]?.apply {
            isSelected = true
            background = shape(tint(BLUE, 26), 16, BLUE, selected = true)
        }
        feedback.apply {
            text = "تم تسجيل المراجعة · ${ratings[level]?.text} · حُفظت للمزامنة"
            setTextColor(0xFF065F46.toInt())
            background = shape(tint(SUCCESS, 20), 12)
            visibility = VISIBLE
        }
        feedback.post { feedback.requestRectangleOnScreen(android.graphics.Rect(0, 0, feedback.width, feedback.height), false) }
    }

    fun showCompletion(remaining: Int, onContinue: () -> Unit) {
        footer.text = if (remaining > 0) "التالي · $remaining" else "إنهاء المراجعة"
        footer.setOnClickListener { onContinue() }
    }
}
