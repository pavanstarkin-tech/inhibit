package com.inhibit.user.shield

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityWindowInfo
import android.widget.Toast
import androidx.core.app.NotificationCompat
import com.inhibit.user.MainActivity

/**
 * Inhibit Native Accessibility Doomscroll & Explore Blocker.
 *
 * Redirects to the Instagram/YouTube Home tab upon doomscroll interception.
 */
class ReelsBlockAccessibilityService : AccessibilityService() {

    private lateinit var prefs: SharedPreferences
    private val mainHandler = Handler(Looper.getMainLooper())
    private val detector = ScreenDetector()
    private lateinit var guardController: GuardController
    private lateinit var notificationManager: NotificationManager
    private lateinit var pillOverlay: DynamicCameraPillOverlay

    private var exitInProgress = false
    private var exitAttempts = 0
    private var lastContentEventTime = 0L

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d("INHIBIT_SERVICE", "ReelsBlockAccessibilityService CONNECTED!")
        prefs = applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        guardController = GuardController(applicationContext)
        pillOverlay = DynamicCameraPillOverlay(this)

        guardController.onReelCountChanged = null
        exitInProgress = false
        exitAttempts = 0

        // Explicitly configure AccessibilityServiceInfo via code
        val info = serviceInfo ?: AccessibilityServiceInfo()
        info.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                AccessibilityEvent.TYPE_VIEW_SCROLLED or
                AccessibilityEvent.TYPE_VIEW_SELECTED
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.flags = info.flags or
                AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS or
                AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
        info.notificationTimeout = 100L
        serviceInfo = info

        Log.d("INHIBIT_SERVICE",
            "Accessibility configured:\n" +
            "eventTypes=${info.eventTypes}\n" +
            "feedbackType=${info.feedbackType}\n" +
            "flags=${info.flags}\n" +
            "canRetrieveWindowContent=true"
        )

        createNotificationChannels()
        showOngoing24hProtectionNotification()
        syncPreferences()
        instance = this

        // Automatically bring our app back to foreground once user enables Accessibility
        mainHandler.postDelayed({
            try {
                val launchIntent = Intent(this, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                startActivity(launchIntent)
            } catch (e: Exception) {
                Log.e("INHIBIT_SERVICE", "Failed to auto-navigate back to app", e)
            }
        }, 350L)
    }

    private fun syncPreferences() {
        if (!::guardController.isInitialized) {
            guardController = GuardController(applicationContext)
        }
        guardController.blockInstagramReels = prefs.getBoolean(KEY_BLOCK_INSTA_REELS, true)
        guardController.blockInstagramExplore = prefs.getBoolean(KEY_BLOCK_INSTA_EXPLORE, true)
        guardController.blockYouTubeShorts = prefs.getBoolean(KEY_BLOCK_YT_SHORTS, true)
        guardController.allowedVideos = prefs.getInt(KEY_ALLOWED_VIDEOS, 1)
    }

    data class ResolvedTree(
        val root: AccessibilityNodeInfo?,
        val selectedPackage: String,
        val selectedClass: String,
        val sourcePackage: String,
        val sourceClass: String,
        val selectionMethod: String
    )

    private var lastCandidateLogTime = 0L

    /**
     * Resolves the true application root node for the target package.
     * Guaranteed never to return SystemUI or unrelated windows when inspecting Instagram or YouTube.
     */
    private fun resolveTargetAppRoot(targetPkg: String, event: AccessibilityEvent?): ResolvedTree {
        val eventType = event?.eventType ?: 0
        val eventSource = try { event?.source } catch (_: Exception) { null }
        val srcPkg = eventSource?.packageName?.toString().orEmpty()
        val srcClass = eventSource?.className?.toString().orEmpty()

        // 1. Check rootInActiveWindow first (fastest single-IPC path)
        try {
            val activeRoot = rootInActiveWindow
            if (activeRoot != null && activeRoot.packageName?.toString() == targetPkg) {
                return ResolvedTree(
                    root = activeRoot,
                    selectedPackage = targetPkg,
                    selectedClass = activeRoot.className?.toString().orEmpty(),
                    sourcePackage = srcPkg,
                    sourceClass = srcClass,
                    selectionMethod = "ACTIVE_WINDOW"
                )
            }
        } catch (_: Exception) {}

        // 2. Fallback to event.source if it belongs to targetPkg
        if (srcPkg == targetPkg && eventSource != null) {
            val parentRoot = tryFindTopmostParentMatching(eventSource, targetPkg)
            val chosen = parentRoot ?: eventSource
            val method = if (parentRoot != null && parentRoot != eventSource) "PARENT" else "SOURCE"
            return ResolvedTree(
                root = chosen,
                selectedPackage = targetPkg,
                selectedClass = chosen.className?.toString().orEmpty(),
                sourcePackage = srcPkg,
                sourceClass = srcClass,
                selectionMethod = method
            )
        }

        // 3. Fallback: inspect windows collection ONLY for TYPE_APPLICATION windows
        try {
            val windowList = windows
            if (!windowList.isNullOrEmpty()) {
                val now = System.currentTimeMillis()
                val shouldLogCandidates = (now - lastCandidateLogTime > 2000L)

                for (window in windowList) {
                    if (window.type != AccessibilityWindowInfo.TYPE_APPLICATION) continue

                    val wRoot = try { window.root } catch (_: Exception) { null } ?: continue
                    val wPkg = wRoot.packageName?.toString().orEmpty()

                    if (shouldLogCandidates) {
                        Log.d("INHIBIT_WINDOW_CANDIDATE",
                            "pkg=$targetPkg\n" +
                            "windowType=TYPE_APPLICATION\n" +
                            "windowPackage=$wPkg\n" +
                            "active=${window.isActive}\n" +
                            "focused=${window.isFocused}"
                        )
                    }

                    if (wPkg == targetPkg) {
                        val chosenClass = wRoot.className?.toString().orEmpty()
                        Log.d("INHIBIT_WINDOW_SELECTED",
                            "pkg=$targetPkg\n" +
                            "windowPackage=$wPkg\n" +
                            "active=${window.isActive}\n" +
                            "focused=${window.isFocused}"
                        )
                        return ResolvedTree(
                            root = wRoot,
                            selectedPackage = wPkg,
                            selectedClass = chosenClass,
                            sourcePackage = srcPkg,
                            sourceClass = srcClass,
                            selectionMethod = "WINDOW"
                        )
                    }
                }

                if (shouldLogCandidates) {
                    lastCandidateLogTime = now
                }
            }
        } catch (e: Exception) {
            Log.e("INHIBIT_SERVICE", "Error inspecting windows", e)
        }

        // 4. No valid target-package root could be obtained -> reject
        return ResolvedTree(
            root = null,
            selectedPackage = "",
            selectedClass = "",
            sourcePackage = srcPkg,
            sourceClass = srcClass,
            selectionMethod = "NONE"
        )
    }

    private fun tryFindTopmostParentMatching(node: AccessibilityNodeInfo, targetPkg: String): AccessibilityNodeInfo? {
        var top: AccessibilityNodeInfo = node
        try {
            var curr = node
            while (curr.parent != null) {
                val parent = curr.parent ?: break
                if (parent.packageName?.toString() == targetPkg) {
                    top = parent
                    curr = parent
                } else {
                    break
                }
            }
        } catch (_: Exception) {}
        return if (top.packageName?.toString() == targetPkg) top else null
    }

    private var lastLoggedTreeSig = ""
    private var lastLoggedTreeTime = 0L

    private var lastLoggedEvidenceSig = ""
    private var lastLoggedEvidenceTime = 0L

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val eventPkg = event.packageName?.toString().orEmpty()
        val eventClassName = event.className?.toString().orEmpty()
        val eventType = event.eventType

        // Never process our own app's events
        if (eventPkg == packageName) return

        // 1. Check if user is outside Instagram / YouTube (e.g. Launcher, App Switcher, other apps)
        val isTargetApp = (eventPkg == ScreenDetector.PKG_INSTAGRAM || eventPkg == ScreenDetector.PKG_YOUTUBE)
        if (!isTargetApp) {
            if (eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED && eventPkg.isNotEmpty()) {
                guardController.onOutsidePackageDetected(eventPkg)
            }
            return
        }

        // 2. Target app is active
        guardController.onAppForegrounded(eventPkg)

        if (eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            eventType != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED &&
            eventType != AccessibilityEvent.TYPE_VIEW_SCROLLED &&
            eventType != AccessibilityEvent.TYPE_VIEW_SELECTED
        ) {
            return
        }

        // Throttle rapid window content changes to prevent saturating accessibility IPC buffer
        if (eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) {
            val nowUptime = SystemClock.uptimeMillis()
            if (nowUptime - lastContentEventTime < 120L) {
                return
            }
            lastContentEventTime = nowUptime
        }

        val targetPkg = eventPkg

        // Resolve target application root
        val resolved = resolveTargetAppRoot(targetPkg, event)

        Log.d("INHIBIT_TREE_SELECTED",
            "eventPackage=$eventPkg\n" +
            "selectedPackage=${resolved.selectedPackage}\n" +
            "selectedClass=${resolved.selectedClass}\n" +
            "sourcePackage=${resolved.sourcePackage}\n" +
            "sourceClass=${resolved.sourceClass}\n" +
            "selectionMethod=${resolved.selectionMethod}"
        )

        val root = resolved.root

        // Strict safety invariant: verify selected package strictly matches targetPkg
        if (root == null || resolved.selectedPackage != targetPkg) {
            Log.d("INHIBIT_TREE_REJECTED",
                "eventPackage=$eventPkg\n" +
                "rootPackage=${resolved.selectedPackage}\n" +
                "reason=ROOT_PACKAGE_MISMATCH"
            )
            return
        }

        val effectivePkg = resolved.selectedPackage
        val rootClass = resolved.selectedClass

        // Window state change diagnostic
        if (eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            Log.d("INHIBIT_WINDOW",
                "pkg=$effectivePkg\n" +
                "class=$eventClassName\n" +
                "rootPackage=$effectivePkg\n" +
                "rootClass=$rootClass"
            )
        }

        syncPreferences()

        val snapshot = UiTreeSnapshot(root)
        detector.setSnapshot(snapshot)

        val screen = detector.detectWithSnapshot(effectivePkg, eventClassName, snapshot)
        val isVerticalScroll = isVerticalReelPagerScroll(event, screen)

        val sig = when (screen) {
            Screen.INSTAGRAM_REEL, Screen.INSTAGRAM_REEL_POSSIBLE -> detector.extractInstagramSignature(root)
            Screen.YOUTUBE_SHORT, Screen.YOUTUBE_SHORT_POSSIBLE -> detector.extractYouTubeSignature(root)
            else -> VideoSignature()
        }

        guardController.onScreenDetected(screen, sig, isVerticalScroll) { message, totalBlocked ->
            redirectToHomeTab(effectivePkg, screen, message, totalBlocked)
        }
    }

    private fun isVerticalReelPagerScroll(event: AccessibilityEvent, screen: Screen): Boolean {
        if (event.eventType != AccessibilityEvent.TYPE_VIEW_SCROLLED) return false

        val source = try { event.source } catch (_: Exception) { null }
        val srcClass = source?.className?.toString().orEmpty().lowercase()
        val srcId = source?.viewIdResourceName?.lowercase().orEmpty()

        // 1. Explicitly ignore horizontal tickers, textviews, audio pills, seekbars, comments
        if (srcClass.contains("textview") ||
            srcClass.contains("horizontal") ||
            srcClass.contains("marquee") ||
            srcClass.contains("progressbar") ||
            srcClass.contains("seekbar") ||
            srcId.contains("music") ||
            srcId.contains("audio") ||
            srcId.contains("pill") ||
            srcId.contains("ticker") ||
            srcId.contains("comment") ||
            srcId.contains("caption") ||
            srcId.contains("search")
        ) {
            return false
        }

        // 2. Check if source is a ViewPager or vertical container for Reels / Shorts
        val isPagerOrRecycler = srcClass.contains("viewpager") ||
                                srcClass.contains("reboundviewpager") ||
                                srcClass.contains("recyclerview") ||
                                srcClass.contains("vertical") ||
                                srcId.contains("reel_recycler") ||
                                srcId.contains("shorts_container") ||
                                srcId.contains("reel_viewer") ||
                                srcId.contains("clips_pager")

        if (isPagerOrRecycler) {
            return true
        }

        // 3. Fallback: on Android 9+, check if scrollDeltaY is non-zero
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            if (event.scrollDeltaY != 0) {
                return true
            }
        }

        // 4. Default for confirmed Reel/Short screen when a view scrolled
        return (screen == Screen.INSTAGRAM_REEL || screen == Screen.YOUTUBE_SHORT)
    }

    private var currentToast: Toast? = null
    private var lastToastTime: Long = 0L

    private fun showDebouncedToast(text: String) {
        val now = System.currentTimeMillis()
        if (now - lastToastTime < 3000L) {
            return
        }
        lastToastTime = now
        mainHandler.post {
            try {
                currentToast?.cancel()
            } catch (_: Exception) {}
            val toast = Toast.makeText(applicationContext, "🚫 $text", Toast.LENGTH_SHORT)
            currentToast = toast
            toast.show()
        }
    }

    /**
     * Executes safe, in-app navigation to the target app's Homepage.
     * Guaranteed NEVER to close the app or exit to the Android launcher.
     * Priority 1: In-app Home Tab Click (Bottom Navigation Bar / Pivot Bar)
     * Priority 2: In-app Close/Back Button Click (Full-screen Modal / Overlay)
     * Priority 3: Single Global Back (Only if in-app buttons cannot be resolved)
     * Priority 4: Bring Target App to Front on Home Activity via Single-Top Intent
     */
    private fun redirectToHomeTab(pkg: String, currentScreen: Screen, message: String, totalBlocked: Int) {
        if (exitInProgress) {
            Log.d("INHIBIT_SERVICE", "BLOCK EXIT IGNORED: exit already in progress")
            return
        }

        exitInProgress = true
        exitAttempts = 1
        guardController.notifyExitStarted()

        Log.d("INHIBIT_SERVICE", "BLOCK EXIT START: package=$pkg, screen=$currentScreen")

        // 1. Show immediate debounced feedback
        showDebouncedToast(message)
        showPushAlertNotification("🚫 Inhibit: Intercepted", "$message (Total Blocked: $totalBlocked)")

        // Safe in-app navigation helper
        fun performSafeHomeNavigation(): Boolean {
            try {
                val activeRoot = rootInActiveWindow
                val activePkg = activeRoot?.packageName?.toString().orEmpty()
                if (activePkg.isNotEmpty() && activePkg != pkg) {
                    Log.d("INHIBIT_SERVICE", "EXIT ABORTED: active window ($activePkg) does not match target ($pkg)")
                    return false
                }

                // Priority 1: In-app Home Tab Click (Bottom Navigation Bar / Pivot Bar)
                val homeNode = detector.findHomeTabNode(activeRoot)
                if (homeNode != null && detector.performDeepClick(homeNode)) {
                    Log.d("INHIBIT_SERVICE", "EXIT: In-app Home Tab clicked successfully for $pkg")
                    return true
                }

                // Priority 2: In-app Close/Back Button Click (Full-screen Modal / Overlay)
                val closeNode = detector.findInAppCloseOrBackNode(activeRoot)
                if (closeNode != null && detector.performDeepClick(closeNode)) {
                    Log.d("INHIBIT_SERVICE", "EXIT: In-app Close/Back button clicked successfully for $pkg")
                    return true
                }

                // Priority 3: Single Global Back (Fallback) - NEVER REPEAT
                val backSuccess = performGlobalAction(GLOBAL_ACTION_BACK)
                Log.d("INHIBIT_SERVICE", "EXIT: Fallback single GLOBAL_ACTION_BACK ($backSuccess)")
                return backSuccess
            } catch (e: Exception) {
                Log.e("INHIBIT_SERVICE", "Error during in-app navigation for $pkg", e)
                return false
            }
        }

        // Execute primary navigation
        performSafeHomeNavigation()

        // Post-delay verification check
        mainHandler.postDelayed({
            try {
                val freshResolved = resolveTargetAppRoot(pkg, null)
                val freshRoot = freshResolved.root
                val freshScreen = if (freshRoot != null && freshResolved.selectedPackage == pkg) {
                    detector.detect(pkg, "", freshRoot)
                } else {
                    Screen.UNKNOWN
                }
                Log.d("INHIBIT_SERVICE", "EXIT VERIFY: screen=$freshScreen")

                val isStillShort = (freshScreen == Screen.INSTAGRAM_REEL ||
                                    freshScreen == Screen.YOUTUBE_SHORT ||
                                    freshScreen == Screen.INSTAGRAM_REEL_POSSIBLE ||
                                    freshScreen == Screen.YOUTUBE_SHORT_POSSIBLE)

                if (isStillShort) {
                    // If still on short-video container, DO NOT execute another back action (prevents closing app)
                    // Instead, try finding the Home Tab again or bring target app's home activity to front
                    val retryHomeNode = detector.findHomeTabNode(freshRoot)
                    if (retryHomeNode != null && detector.performDeepClick(retryHomeNode)) {
                        Log.d("INHIBIT_SERVICE", "EXIT VERIFY: Home tab clicked on retry for $pkg")
                    } else {
                        // Bring target app to front on its main task
                        val launchIntent = packageManager.getLaunchIntentForPackage(pkg)?.apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                        }
                        if (launchIntent != null) {
                            Log.d("INHIBIT_SERVICE", "EXIT VERIFY: Bringing $pkg to front via Main Intent")
                            startActivity(launchIntent)
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e("INHIBIT_SERVICE", "Error during exit verification", e)
            } finally {
                finishExitSequence()
            }
        }, 350L)
    }

    private fun finishExitSequence() {
        Log.d("INHIBIT_SERVICE", "BLOCK EXIT COMPLETE")
        exitInProgress = false
        exitAttempts = 0
        guardController.notifyExitCompleted()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ongoingChannel = NotificationChannel(
                CHANNEL_ONGOING_ID,
                "Inhibit 24/7 Protection",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows ongoing 24/7 doomscrolling shield status"
                setShowBadge(false)
            }

            val alertChannel = NotificationChannel(
                CHANNEL_ALERT_ID,
                "Inhibit Shield Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifies when doomscrolling or explore feeds are blocked"
                enableVibration(true)
            }

            notificationManager.createNotificationChannel(ongoingChannel)
            notificationManager.createNotificationChannel(alertChannel)
        }
    }

    private fun showOngoing24hProtectionNotification() {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ONGOING_ID)
            .setContentTitle("Inhibit Shield Active")
            .setContentText("24/7 Doomscrolling protection enabled for Instagram & YouTube")
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        notificationManager.notify(NOTIFICATION_ONGOING_ID, notification)
    }

    private fun showPushAlertNotification(title: String, message: String) {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            1,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ALERT_ID)
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        notificationManager.notify(NOTIFICATION_ALERT_ID, notification)
    }

    override fun onInterrupt() = Unit

    override fun onDestroy() {
        super.onDestroy()
        Log.d("INHIBIT_SERVICE", "ReelsBlockAccessibilityService DESTROYED")
        exitInProgress = false
        exitAttempts = 0
        if (::guardController.isInitialized) {
            guardController.isExitInProgress = false
        }
        if (instance == this) instance = null
    }

    companion object {
        var instance: ReelsBlockAccessibilityService? = null
            private set

        const val PREFS_NAME = "noscroll_native_shield"
        const val KEY_BLOCK_INSTA_REELS = "block_insta_reels"
        const val KEY_BLOCK_INSTA_EXPLORE = "block_insta_explore"
        const val KEY_BLOCK_YT_SHORTS = "block_yt_shorts"
        const val KEY_ALLOWED_VIDEOS = "allowed_videos"

        private const val CHANNEL_ONGOING_ID = "inhibit_ongoing_protection"
        private const val CHANNEL_ALERT_ID = "inhibit_alerts"
        private const val NOTIFICATION_ONGOING_ID = 1001
        private const val NOTIFICATION_ALERT_ID = 1002
    }
}
