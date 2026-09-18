package com.inhibit.user.shield

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import com.inhibit.user.MainActivity

/**
 * Modern Neobrutalist Native Shield Screen.
 *
 * Appears over shielded native apps to redirect the user to Inhibit's clean browser
 * or safely return to their home screen.
 */
class ShieldActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val blockedPkg = intent.getStringExtra(EXTRA_PACKAGE).orEmpty()
        val serviceId = packageToServiceId(blockedPkg)
        val appName = friendlyName(blockedPkg)

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#FFF8E7"))
            setPadding(dp(24), dp(24), dp(24), dp(24))
        }

        // Neobrutalist Center Card
        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(20), dp(28), dp(20), dp(24))
            background = GradientDrawable().apply {
                setColor(Color.WHITE)
                setStroke(dp(3), Color.BLACK)
                cornerRadius = dp(12).toFloat()
            }
        }

        // Badge: "SHIELD ACTIVE"
        val badge = TextView(this).apply {
            text = "★ INHIBIT SHIELD"
            textSize = 12f
            setTypeface(Typeface.DEFAULT_BOLD, Typeface.BOLD)
            setTextColor(Color.BLACK)
            setPadding(dp(10), dp(4), dp(10), dp(4))
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#FFD93D"))
                setStroke(dp(2), Color.BLACK)
                cornerRadius = dp(6).toFloat()
            }
        }
        card.addView(badge)

        // Title
        val title = TextView(this).apply {
            text = "$appName IS SHIELDED".uppercase()
            textSize = 22f
            setTypeface(Typeface.DEFAULT_BOLD, Typeface.BOLD)
            setTextColor(Color.BLACK)
            gravity = Gravity.CENTER
            setPadding(0, dp(16), 0, dp(8))
        }
        card.addView(title)

        // Subtitle
        val subtitle = TextView(this).apply {
            text = "Use Inhibit for a calmer, distraction-free version with messages and friends — zero Reels, Shorts, or algorithmic traps."
            textSize = 13f
            setTextColor(Color.parseColor("#444444"))
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, dp(24))
        }
        card.addView(subtitle)

        // Primary Button: Open Calm Version in NoScroll
        val primaryBtn = Button(this).apply {
            text = "OPEN CALMER $appName →".uppercase()
            textSize = 13f
            setTypeface(Typeface.DEFAULT_BOLD, Typeface.BOLD)
            setTextColor(Color.BLACK)
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#7ED957"))
                setStroke(dp(2), Color.BLACK)
                cornerRadius = dp(8).toFloat()
            }
            setOnClickListener {
                val launchIntent = Intent(this@ShieldActivity, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    putExtra(MainActivity.EXTRA_LAUNCH_SERVICE, serviceId)
                }
                startActivity(launchIntent)
                finish()
            }
        }
        val btnParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            dp(48),
        ).apply { setMargins(0, 0, 0, dp(10)) }
        card.addView(primaryBtn, btnParams)

        // Secondary Button: Return to Phone Home
        val secondaryBtn = Button(this).apply {
            text = "RETURN TO PHONE HOME".uppercase()
            textSize = 12f
            setTypeface(Typeface.DEFAULT_BOLD, Typeface.BOLD)
            setTextColor(Color.BLACK)
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#FFF8E7"))
                setStroke(dp(2), Color.BLACK)
                cornerRadius = dp(8).toFloat()
            }
            setOnClickListener {
                startActivity(
                    Intent(Intent.ACTION_MAIN).apply {
                        addCategory(Intent.CATEGORY_HOME)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    },
                )
                finish()
            }
        }
        card.addView(secondaryBtn, btnParams)

        // Tertiary Button: Temporary Unlock (15m)
        val unlockBtn = Button(this).apply {
            text = "TEMPORARY UNLOCK (15 MIN)".uppercase()
            textSize = 11f
            setTextColor(Color.parseColor("#666666"))
            background = GradientDrawable().apply {
                setColor(Color.TRANSPARENT)
            }
            setOnClickListener {
                val prefs = getSharedPreferences(ReelsBlockAccessibilityService.PREFS_NAME, Context.MODE_PRIVATE)
                val unlockUntil = System.currentTimeMillis() + (15 * 60 * 1000L)
                prefs.edit().putLong("unlock_${blockedPkg}", unlockUntil).apply()
                finish()
            }
        }
        card.addView(unlockBtn, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(38)))

        root.addView(card, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        setContentView(root)
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        startActivity(
            Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            },
        )
        finish()
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
        "com.zhiliaoapp.musically", "com.ss.android.ugc.trill" -> "TikTok"
        "com.twitter.android" -> "X"
        "com.reddit.frontpage" -> "Reddit"
        "com.facebook.katana" -> "Facebook"
        "com.snapchat.android" -> "Snapchat"
        "com.linkedin.android" -> "LinkedIn"
        else -> "This App"
    }

    private fun packageToServiceId(pkg: String): String = when (pkg) {
        "com.instagram.android" -> "instagram"
        "com.google.android.youtube" -> "youtube"
        "com.zhiliaoapp.musically", "com.ss.android.ugc.trill" -> "tiktok"
        "com.twitter.android" -> "x"
        "com.reddit.frontpage" -> "reddit"
        "com.facebook.katana" -> "facebook"
        "com.snapchat.android" -> "snapchat"
        "com.linkedin.android" -> "linkedin"
        else -> "instagram"
    }

    companion object {
        const val EXTRA_PACKAGE = "app.noscroll.blockedPackage"
    }
}
