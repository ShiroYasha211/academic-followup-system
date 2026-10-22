package com.mohammed.moeen.moeen_student_app

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.View
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.PopupMenu
import android.widget.TextView

internal class FloatingReviewBubbleView(context: Context, onOpen: () -> Unit, private val onSnooze: () -> Unit) : FrameLayout(context) {
    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
    private val snoozeAction = View.generateViewId()
    private var actions: PopupMenu? = null
    private val badge = TextView(context).apply {
        textSize = 12f
        typeface = Typeface.createFromAsset(context.assets, "flutter_assets/assets/fonts/Cairo-ExtraBold.ttf")
        setTextColor(Color.WHITE)
        gravity = Gravity.CENTER
        minWidth = dp(26)
        minimumHeight = dp(26)
        setPadding(dp(5), 0, dp(5), 0)
        background = GradientDrawable().apply { setColor(0xFFBE123C.toInt()); cornerRadius = dp(16).toFloat() }
        elevation = dp(7).toFloat()
        importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_NO
    }

    init {
        clipChildren = false
        clipToPadding = false
        isFocusable = true
        tooltipText = "بطاقات المراجعة"
        val icon = ImageView(context).apply {
            setImageResource(R.mipmap.launcher_icon)
            scaleType = ImageView.ScaleType.CENTER_CROP
            setPadding(dp(5), dp(5), dp(5), dp(5))
            background = GradientDrawable().apply {
                setColor(Color.WHITE)
                shape = GradientDrawable.OVAL
                setStroke(dp(1).coerceAtLeast(1), 0xFFCBD5E1.toInt())
            }
            clipToOutline = true
            elevation = dp(5).toFloat()
            importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_NO
        }
        addView(icon, LayoutParams(dp(56), dp(56), Gravity.CENTER))
        addView(badge, LayoutParams(-2, -2, Gravity.TOP or Gravity.LEFT).apply { topMargin = dp(2); leftMargin = dp(2) })
        setOnClickListener { onOpen() }
        setOnLongClickListener { showActions(); true }
        accessibilityDelegate = object : AccessibilityDelegate() {
            override fun onInitializeAccessibilityNodeInfo(host: View, info: AccessibilityNodeInfo) {
                super.onInitializeAccessibilityNodeInfo(host, info)
                info.className = "android.widget.Button"
                info.addAction(AccessibilityNodeInfo.AccessibilityAction(snoozeAction, "تأجيل المراجعة"))
            }
            override fun performAccessibilityAction(host: View, action: Int, args: android.os.Bundle?): Boolean {
                if (action == snoozeAction) { onSnooze(); return true }
                return super.performAccessibilityAction(host, action, args)
            }
        }
    }

    fun updateCount(count: Int) {
        badge.text = if (count > 99) "99+" else count.toString()
        contentDescription = "بطاقات المراجعة، $count بطاقة مستحقة"
    }

    fun showActions() {
        actions?.dismiss()
        actions = PopupMenu(context, this).apply {
            menu.add("تأجيل المراجعة").setOnMenuItemClickListener { onSnooze(); true }
            show()
        }
    }

    override fun onDetachedFromWindow() {
        actions?.dismiss()
        actions = null
        super.onDetachedFromWindow()
    }
}
