package com.inhibit.user.shield

import android.app.Activity
import android.app.AlertDialog
import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.ViewGroup
import android.view.Window
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast

/**
 * Modern Neobrutalist Life Dialog & Intentional Pass Interception.
 *
 * Appears directly over Instagram / YouTube when the user attempts to doomscroll beyond the 1st video.
 * Gives the user the choice:
 * 1. PROCEED with 1 of 4 free daily lives (if available).
 * 2. REQUEST 30 MINS+ / 60 MINS+ (simulated payment unlock, especially after using 4/4 lives).
 * 3. CLOSE & STOP SCROLLING: Safely returns to Chat / Feed / Home.
 */
class ShieldActivity : Activity() {

    private lateinit var guardController: GuardController

    override fun onCreate(savedInstanceState: Bundle?) {
        overridePendingTransition(0, 0)
        super.onCreate(savedInstanceState)
        requestWindowFeature(Window.FEATURE_NO_TITLE)
        
        window.apply {
            setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
            addFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND)
            setDimAmount(0.65f)
        }

        guardController = GuardController(applicationContext)

        val blockedPkg = intent.getStringExtra(EXTRA_PACKAGE).orEmpty()
        val appName = friendlyName(blockedPkg)
        val lives = guardController.getRemainingLives()
        val hasFreeLives = lives > 0

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(20), dp(20), dp(20), dp(20))
            setOnClickListener {
                handleClose()
            }
        }

        // Neobrutalist Center Modal Card
        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(22), dp(24), dp(22), dp(20))
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#FFFDF7"))
                setStroke(dp(3), Color.BLACK)
                cornerRadius = dp(16).toFloat()
            }
            setOnClickListener {
                // Prevent dismiss when clicking inside card
            }
        }

        // 1. Badge / Hearts Indicator
        val heartsText = if (hasFreeLives) {
            val filled = "❤️ ".repeat(lives).trim()
            val empty = "🤍 ".repeat(4 - lives).trim()
            "$filled $empty".trim() + "  ($lives / 4 LIVES REMAINING)"
        } else {
            "💔 4 / 4 LIVES USED (0 LEFT TODAY)"
        }

        val badge = TextView(this).apply {
            text = heartsText
            textSize = 11.5f
            setTypeface(Typeface.DEFAULT_BOLD, Typeface.BOLD)
            setTextColor(Color.BLACK)
            gravity = Gravity.CENTER
            setPadding(dp(12), dp(6), dp(12), dp(6))
            background = GradientDrawable().apply {
                setColor(if (hasFreeLives) Color.parseColor("#FFE58F") else Color.parseColor("#FFA39E"))
                setStroke(dp(2), Color.BLACK)
                cornerRadius = dp(20).toFloat()
            }
        }
        card.addView(badge)

        // 2. Title
        val title = TextView(this).apply {
            text = if (hasFreeLives) "DOOMSCROLL PAUSED 🛑" else "ALL 4 FREE LIVES USED ⏳"
            textSize = 18f
            setTypeface(Typeface.DEFAULT_BOLD, Typeface.BOLD)
            setTextColor(Color.BLACK)
            gravity = Gravity.CENTER
            setPadding(0, dp(14), 0, dp(6))
        }
        card.addView(title)

        // 3. Subtitle / Message
        val message = TextView(this).apply {
            text = if (hasFreeLives) {
                "You've watched your 1 free preview on $appName.\n\nUse 1 of your $lives free daily lives to unlock 30 minutes of viewing."
            } else {
                "You've used all 4 of your daily free lives on $appName.\n\nRequest 30 minutes of intentional viewing for ₹10."
            }
            textSize = 13f
            setTextColor(Color.parseColor("#333333"))
            gravity = Gravity.CENTER
            setLineSpacing(0f, 1.25f)
            setPadding(0, 0, 0, dp(18))
        }
        card.addView(message)

        val buttonRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            weightSum = 2f
        }

        if (hasFreeLives) {
            // Button 1: PROCEED (Use 1 Life)
            val proceedBtn = Button(this).apply {
                text = "PROCEED ➔"
                textSize = 13f
                setTypeface(Typeface.DEFAULT_BOLD, Typeface.BOLD)
                setTextColor(Color.BLACK)
                background = GradientDrawable().apply {
                    setColor(Color.parseColor("#52C41A"))
                    setStroke(dp(2), Color.BLACK)
                    cornerRadius = dp(10).toFloat()
                }
                setOnClickListener {
                    val success = guardController.consumeLife()
                    val remaining = guardController.getRemainingLives()
                    if (success) {
                        Toast.makeText(this@ShieldActivity, "✨ 30 Minutes Unlocked! ($remaining lives left today)", Toast.LENGTH_SHORT).show()
                        finish()
                    }
                }
            }
            val proceedParams = LinearLayout.LayoutParams(0, dp(46), 1f).apply {
                setMargins(0, 0, dp(6), 0)
            }
            buttonRow.addView(proceedBtn, proceedParams)

            // Button 2: CLOSE
            val closeBtn = Button(this).apply {
                text = "CLOSE ✕"
                textSize = 13f
                setTypeface(Typeface.DEFAULT_BOLD, Typeface.BOLD)
                setTextColor(Color.BLACK)
                background = GradientDrawable().apply {
                    setColor(Color.WHITE)
                    setStroke(dp(2), Color.BLACK)
                    cornerRadius = dp(10).toFloat()
                }
                setOnClickListener {
                    handleClose()
                }
            }
            val closeParams = LinearLayout.LayoutParams(0, dp(46), 1f).apply {
                setMargins(dp(6), 0, 0, 0)
            }
            buttonRow.addView(closeBtn, closeParams)
        } else {
            // All 4 lives used: Show REQUEST 30M (₹10) and CLOSE in same row
            val requestBtn = Button(this).apply {
                text = "REQUEST (₹10) ⚡"
                textSize = 12f
                setTypeface(Typeface.DEFAULT_BOLD, Typeface.BOLD)
                setTextColor(Color.BLACK)
                background = GradientDrawable().apply {
                    setColor(Color.parseColor("#FFE58F"))
                    setStroke(dp(2), Color.BLACK)
                    cornerRadius = dp(10).toFloat()
                }
                setOnClickListener {
                    showSimulatedPaymentDialog(30, 10)
                }
            }
            val requestParams = LinearLayout.LayoutParams(0, dp(46), 1f).apply {
                setMargins(0, 0, dp(6), 0)
            }
            buttonRow.addView(requestBtn, requestParams)

            // CLOSE
            val closeBtn = Button(this).apply {
                text = "CLOSE ✕"
                textSize = 13f
                setTypeface(Typeface.DEFAULT_BOLD, Typeface.BOLD)
                setTextColor(Color.BLACK)
                background = GradientDrawable().apply {
                    setColor(Color.WHITE)
                    setStroke(dp(2), Color.BLACK)
                    cornerRadius = dp(10).toFloat()
                }
                setOnClickListener {
                    handleClose()
                }
            }
            val closeParams = LinearLayout.LayoutParams(0, dp(46), 1f).apply {
                setMargins(dp(6), 0, 0, 0)
            }
            buttonRow.addView(closeBtn, closeParams)
        }

        card.addView(buttonRow, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))

        root.addView(card, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        setContentView(root)
    }

    private fun showSimulatedPaymentDialog(minutes: Int, amountInr: Int) {
        val builder = AlertDialog.Builder(this)
        builder.setTitle("💳 Inhibit UPI / Card Simulation")
        builder.setMessage("Simulating payment of ₹$amountInr to unlock $minutes Minutes of unrestricted access...")
        builder.setPositiveButton("Confirm ₹$amountInr & Unlock $minutes Mins") { dialog, _ ->
            dialog.dismiss()
            guardController.simulatePaymentUnlock(minutes)
            Toast.makeText(this, "🎉 Payment of ₹$amountInr Successful! $minutes minutes unrestricted access activated.", Toast.LENGTH_LONG).show()
            finish()
        }
        builder.setNegativeButton("Cancel") { dialog, _ ->
            dialog.dismiss()
        }
        builder.setCancelable(false)
        builder.show()
    }

    private fun handleClose() {
        try {
            ReelsBlockAccessibilityService.instance?.performSafeBack()
        } catch (_: Exception) {}
        finish()
    }

    override fun finish() {
        super.finish()
        overridePendingTransition(0, 0)
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        handleClose()
    }

    private fun dp(value: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            resources.displayMetrics,
        ).toInt()
    }

    private fun friendlyName(pkg: String): String = when (pkg) {
        "com.instagram.android" -> "Instagram"
        "com.google.android.youtube" -> "YouTube"
        else -> "this app"
    }

    companion object {
        const val EXTRA_PACKAGE = "app.noscroll.blockedPackage"
        const val EXTRA_REMAINING_LIVES = "app.noscroll.remainingLives"
        const val EXTRA_TOTAL_BLOCKED = "app.noscroll.totalBlocked"
    }
}
