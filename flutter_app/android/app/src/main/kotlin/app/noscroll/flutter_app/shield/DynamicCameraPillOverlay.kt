package app.noscroll.flutter_app.shield

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Modern Dynamic Island / Camera Punch-Hole Pill Toast.
 *
 * Appears near the top camera punch-hole when watching/scrolling Reels.
 * Displays live reel count for the day and dynamically color-codes:
 * - Green (0-4 reels): Safe
 * - Orange (5-10 reels): Moderate warning
 * - Crimson Red (>10 reels / blocked): Strict limit alert
 */
class DynamicCameraPillOverlay(private val context: Context) {

    private val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val mainHandler = Handler(Looper.getMainLooper())

    private var overlayView: LinearLayout? = null
    private var iconView: TextView? = null
    private var textView: TextView? = null
    private var isShowing = false
    private var dismissRunnable: Runnable? = null
    private var lastShowTime = 0L

    private fun dpToPx(dp: Float): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp,
            context.resources.displayMetrics
        ).toInt()
    }

    private fun createOverlayView(): LinearLayout {
        val root = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dpToPx(14f), dpToPx(7f), dpToPx(16f), dpToPx(7f))
            elevation = dpToPx(10f).toFloat()
        }

        val icon = TextView(context).apply {
            textSize = 14f
            setPadding(0, 0, dpToPx(6f), 0)
        }
        iconView = icon
        root.addView(icon)

        val text = TextView(context).apply {
            textSize = 12.5f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.WHITE)
            maxLines = 1
        }
        textView = text
        root.addView(text)

        return root
    }

    /**
     * Displays the dynamic pill toast near the top camera.
     */
    fun show(totalReelsScrolled: Int, isBlocked: Boolean = false, customMessage: String? = null) {
        mainHandler.post {
            val now = System.currentTimeMillis()
            if (now - lastShowTime < 1500L && !isBlocked) {
                return@post // Debounce rapid non-block updates
            }
            lastShowTime = now

            // Determine style based on count and block status
            val (bgColor, borderColor, iconEmoji, message) = when {
                isBlocked -> {
                    Quad(
                        Color.parseColor("#E6180505"),
                        Color.parseColor("#EF4444"),
                        "🚫",
                        customMessage ?: "$totalReelsScrolled Reels Today • Limit Reached"
                    )
                }
                totalReelsScrolled > 10 -> {
                    Quad(
                        Color.parseColor("#E6200A0A"),
                        Color.parseColor("#F87171"),
                        "🛑",
                        "$totalReelsScrolled Reels Today (High Usage)"
                    )
                }
                totalReelsScrolled >= 5 -> {
                    Quad(
                        Color.parseColor("#E61E1600"),
                        Color.parseColor("#F59E0B"),
                        "⚠️",
                        "$totalReelsScrolled Reels Today"
                    )
                }
                else -> {
                    Quad(
                        Color.parseColor("#E60D1510"),
                        Color.parseColor("#10B981"),
                        "🎬",
                        "$totalReelsScrolled Reels Scrolled Today"
                    )
                }
            }

            if (overlayView == null) {
                overlayView = createOverlayView()
            }

            val pillDrawable = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dpToPx(24f).toFloat()
                setColor(bgColor)
                setStroke(dpToPx(1.5f), borderColor)
            }

            overlayView?.background = pillDrawable
            iconView?.text = iconEmoji
            textView?.text = message

            if (!isShowing) {
                val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                    WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
                } else {
                    WindowManager.LayoutParams.TYPE_SYSTEM_ALERT
                }

                val params = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    layoutType,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
                    y = dpToPx(38f) // Aligned right beneath the top punch-hole camera
                }

                try {
                    windowManager.addView(overlayView, params)
                    isShowing = true
                    overlayView?.alpha = 0f
                    overlayView?.translationY = -dpToPx(15f).toFloat()
                    overlayView?.animate()
                        ?.alpha(1f)
                        ?.translationY(0f)
                        ?.setDuration(220)
                        ?.start()
                } catch (e: Exception) {
                    // Fallback in case window manager is not accessible
                }
            } else {
                overlayView?.animate()
                    ?.scaleX(1.05f)
                    ?.scaleY(1.05f)
                    ?.setDuration(100)
                    ?.withEndAction {
                        overlayView?.animate()?.scaleX(1f)?.scaleY(1f)?.setDuration(100)?.start()
                    }
                    ?.start()
            }

            // Schedule dismiss after 2.5 seconds
            dismissRunnable?.let { mainHandler.removeCallbacks(it) }
            val dismiss = Runnable { hide() }
            dismissRunnable = dismiss
            mainHandler.postDelayed(dismiss, 2600L)
        }
    }

    fun hide() {
        mainHandler.post {
            if (isShowing && overlayView != null) {
                overlayView?.animate()
                    ?.alpha(0f)
                    ?.translationY(-dpToPx(10f).toFloat())
                    ?.setDuration(200)
                    ?.setListener(object : AnimatorListenerAdapter() {
                        override fun onAnimationEnd(animation: Animator) {
                            try {
                                if (isShowing && overlayView != null) {
                                    windowManager.removeView(overlayView)
                                    isShowing = false
                                }
                            } catch (_: Exception) {}
                        }
                    })
                    ?.start()
            }
        }
    }

    private data class Quad<A, B, C, D>(val first: A, val second: B, val third: C, val fourth: D)
}
