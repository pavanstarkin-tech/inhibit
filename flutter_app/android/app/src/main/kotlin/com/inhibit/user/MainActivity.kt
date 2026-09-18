package com.inhibit.user

import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.text.TextUtils
import com.inhibit.user.shield.ReelsBlockAccessibilityService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "app.noscroll/shield"
    private var pendingLaunchService: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        pendingLaunchService = intent.getStringExtra(EXTRA_LAUNCH_SERVICE)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityGranted" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "openAccessibilitySettings" -> {
                    val componentName = android.content.ComponentName(
                        applicationContext.packageName,
                        ReelsBlockAccessibilityService::class.java.name
                    )
                    val flatString = componentName.flattenToString()

                    val args = android.os.Bundle().apply {
                        putString("component_name", flatString)
                        putString("preference_key", flatString)
                        putString(":settings:fragment_args_key", flatString)
                        putString("android.intent.extra.COMPONENT_NAME", flatString)
                        putString("android.provider.extra.COMPONENT_NAME", flatString)
                        putString("extra_component_name", flatString)
                        putString("title", "Inhibit")
                    }

                    val intentsToTry = listOf(
                        // 1. Official ACCESSIBILITY_DETAILS_SETTINGS with ComponentName parcelable & string extras
                        Intent("android.settings.ACCESSIBILITY_DETAILS_SETTINGS").apply {
                            putExtra(Intent.EXTRA_COMPONENT_NAME, componentName)
                            putExtra("android.intent.extra.COMPONENT_NAME", componentName)
                            putExtra("android.provider.extra.COMPONENT_NAME", flatString)
                            putExtra("component_name", flatString)
                            putExtra(":settings:fragment_args_key", flatString)
                            putExtra(":settings:show_fragment_args", args)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        },
                        // 2. ACCESSIBILITY_DETAILS_SETTINGS with package URI
                        Intent("android.settings.ACCESSIBILITY_DETAILS_SETTINGS").apply {
                            data = android.net.Uri.parse("package:$packageName")
                            putExtra(Intent.EXTRA_COMPONENT_NAME, flatString)
                            putExtra("android.intent.extra.COMPONENT_NAME", flatString)
                            putExtra("android.provider.extra.COMPONENT_NAME", flatString)
                            putExtra("component_name", flatString)
                            putExtra(":settings:fragment_args_key", flatString)
                            putExtra(":settings:show_fragment_args", args)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        },
                        // 3. ColorOS / OxygenOS Installed Services Activity
                        Intent().apply {
                            setComponent(android.content.ComponentName("com.android.settings", "com.android.settings.Settings\$AccessibilityInstalledServiceActivity"))
                            putExtra(":settings:fragment_args_key", flatString)
                            putExtra(":settings:show_fragment_args", args)
                            putExtra("component_name", flatString)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        },
                        // 4. ACTION_ACCESSIBILITY_SETTINGS with fragment args highlighting Inhibit
                        Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                            putExtra(":settings:fragment_args_key", flatString)
                            putExtra(":settings:show_fragment_args", args)
                            putExtra("component_name", flatString)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                    )

                    var launched = false
                    for (attemptIntent in intentsToTry) {
                        try {
                            if (attemptIntent.resolveActivity(packageManager) != null) {
                                startActivity(attemptIntent)
                                launched = true
                                break
                            }
                        } catch (_: Exception) {}
                    }
                    if (!launched) {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        })
                    }
                    result.success(true)
                }
                "getPendingLaunchService" -> {
                    val svc = pendingLaunchService
                    pendingLaunchService = null
                    result.success(svc)
                }
                "updateShieldRules" -> {
                    val blockInstaReels = call.argument<Boolean>("blockInstaReels") ?: true
                    val blockInstaExplore = call.argument<Boolean>("blockInstaExplore") ?: true
                    val blockYtShorts = call.argument<Boolean>("blockYtShorts") ?: true

                    val prefs = getSharedPreferences(ReelsBlockAccessibilityService.PREFS_NAME, Context.MODE_PRIVATE)
                    prefs.edit()
                        .putBoolean(ReelsBlockAccessibilityService.KEY_BLOCK_INSTA_REELS, blockInstaReels)
                        .putBoolean(ReelsBlockAccessibilityService.KEY_BLOCK_INSTA_EXPLORE, blockInstaExplore)
                        .putBoolean(ReelsBlockAccessibilityService.KEY_BLOCK_YT_SHORTS, blockYtShorts)
                        .apply()

                    result.success(true)
                }
                "setPackageShielded" -> {
                    val pkg = call.argument<String>("package")
                    val shielded = call.argument<Boolean>("shielded") ?: true
                    if (pkg != null) {
                        val prefs = getSharedPreferences(ReelsBlockAccessibilityService.PREFS_NAME, Context.MODE_PRIVATE)
                        prefs.edit().putBoolean("shield_pkg_$pkg", shielded).apply()
                    }
                    result.success(true)
                }
                "getShieldStats" -> {
                    val statsPrefs = getSharedPreferences(com.inhibit.user.shield.GuardController.PREFS_STATS, Context.MODE_PRIVATE)
                    val scrolled = statsPrefs.getInt(com.inhibit.user.shield.GuardController.KEY_TOTAL_REELS_SCROLLED, 0)
                    val blocked = statsPrefs.getInt(com.inhibit.user.shield.GuardController.KEY_TOTAL_REELS_BLOCKED, 0)
                    result.success(mapOf(
                        "totalReelsScrolled" to scrolled,
                        "totalReelsBlocked" to blocked
                    ))
                }
                "startPostMode" -> {
                    val durationMinutes = call.argument<Int>("durationMinutes") ?: 30
                    val expiresAt = if (durationMinutes <= 0) 0L else (System.currentTimeMillis() + (durationMinutes * 60 * 1000L))
                    val statsPrefs = getSharedPreferences(com.inhibit.user.shield.GuardController.PREFS_STATS, Context.MODE_PRIVATE)
                    statsPrefs.edit().putLong(com.inhibit.user.shield.GuardController.KEY_POST_MODE_EXPIRES_AT, expiresAt).apply()
                    result.success(true)
                }
                "isPostModeActive" -> {
                    val statsPrefs = getSharedPreferences(com.inhibit.user.shield.GuardController.PREFS_STATS, Context.MODE_PRIVATE)
                    val expiresAt = statsPrefs.getLong(com.inhibit.user.shield.GuardController.KEY_POST_MODE_EXPIRES_AT, 0L)
                    result.success(System.currentTimeMillis() < expiresAt)
                }
                "getPostModeRemainingSeconds" -> {
                    val statsPrefs = getSharedPreferences(com.inhibit.user.shield.GuardController.PREFS_STATS, Context.MODE_PRIVATE)
                    val expiresAt = statsPrefs.getLong(com.inhibit.user.shield.GuardController.KEY_POST_MODE_EXPIRES_AT, 0L)
                    val remaining = (expiresAt - System.currentTimeMillis()) / 1000
                    result.success(if (remaining > 0) remaining.toInt() else 0)
                }
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        try {
                            val browserIntent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse(url)).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            }
                            startActivity(browserIntent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val svc = intent.getStringExtra(EXTRA_LAUNCH_SERVICE)
        if (svc != null && flutterEngine != null) {
            MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                .invokeMethod("onOpenServiceFromShield", svc)
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        if (ReelsBlockAccessibilityService.instance != null) return true

        val expectedServiceName = "${packageName}/${ReelsBlockAccessibilityService::class.java.canonicalName}"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        val colonSplitter = TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(enabledServices)

        while (colonSplitter.hasNext()) {
            val componentName = colonSplitter.next()
            if (componentName.equals(expectedServiceName, ignoreCase = true) ||
                componentName.contains("ReelsBlockAccessibilityService", ignoreCase = true)) {
                return true
            }
        }
        return false
    }

    companion object {
        const val EXTRA_LAUNCH_SERVICE = "app.noscroll.launchService"
    }
}
