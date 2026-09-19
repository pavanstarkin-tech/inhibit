package com.inhibit.user.shield

import android.content.Context
import android.content.SharedPreferences
import android.util.Log

/**
 * State machine and policy controller for doomscroll interception.
 *
 * Core Policies:
 * 1. Allow 1st Reel / Short per session to be watched fully without interruption.
 * 2. Launch Grace: Never block or execute back actions during the first 2000ms after opening target app.
 * 3. Smooth In-App Navigation: When 2nd video is scrolled, redirect to Home tab without closing the app.
 * 4. Outside Package Detection: Reset session immediately when user switches to launcher or other apps.
 * 5. Cooldown: Enforce 1500ms exit cooldown to prevent event cascade re-triggers.
 */
class GuardController(private val context: Context) {

    var allowedVideos: Int = 1
    var blockInstagramReels: Boolean = true
    var blockInstagramExplore: Boolean = false // Explore grid allowed; Reels inside Explore guarded
    var blockYouTubeShorts: Boolean = true
    var isExitInProgress: Boolean = false

    private var prefs: SharedPreferences = context.getSharedPreferences(PREFS_STATS, Context.MODE_PRIVATE)

    private var currentActivePackage: String = ""
    private var currentScreen: Screen = Screen.UNKNOWN
    private var activeVideoSig: VideoSignature? = null
    private var videosWatchedInSession: Int = 0
    private var sessionStartTime: Long = 0L
    private var lastActionTime: Long = 0L
    private var lastLeaveVideoTime: Long = 0L
    private var appForegroundedTime: Long = 0L
    private var exitCooldownUntil: Long = 0L

    var onReelCountChanged: ((Int) -> Unit)? = null

    val isPostModeActive: Boolean
        get() {
            val expiresAt = prefs.getLong(KEY_POST_MODE_EXPIRES_AT, 0L)
            return System.currentTimeMillis() < expiresAt
        }

    fun startPostMode(durationMinutes: Int = 30) {
        val expiresAt = System.currentTimeMillis() + (durationMinutes * 60 * 1000L)
        prefs.edit().putLong(KEY_POST_MODE_EXPIRES_AT, expiresAt).apply()
        Log.d("INHIBIT_GUARD", "Intentional Post Mode STARTED for $durationMinutes min (Expires at $expiresAt)")
    }

    fun getPostModeRemainingSeconds(): Long {
        val expiresAt = prefs.getLong(KEY_POST_MODE_EXPIRES_AT, 0L)
        val remaining = (expiresAt - System.currentTimeMillis()) / 1000
        return if (remaining > 0) remaining else 0L
    }

    var totalReelsScrolled: Int
        get() = prefs.getInt(KEY_TOTAL_REELS_SCROLLED, 0)
        private set(value) = prefs.edit().putInt(KEY_TOTAL_REELS_SCROLLED, value).apply()

    var totalReelsBlocked: Int
        get() = prefs.getInt(KEY_TOTAL_REELS_BLOCKED, 0)
        private set(value) = prefs.edit().putInt(KEY_TOTAL_REELS_BLOCKED, value).apply()

    /**
     * Called when an outside package (Launcher, Settings, or another app) is active.
     * Instantly resets session state so opening Instagram/YouTube starts completely fresh.
     */
    fun onOutsidePackageDetected(pkg: String) {
        if (currentActivePackage != pkg) {
            currentActivePackage = pkg
            currentScreen = Screen.OUTSIDE
            activeVideoSig = null
            videosWatchedInSession = 0
            sessionStartTime = 0L
            lastLeaveVideoTime = System.currentTimeMillis()
            isExitInProgress = false
            Log.d("INHIBIT_GUARD", "Outside package detected: $pkg -> Session reset")
        }
    }

    /**
     * Called when a target package (Instagram or YouTube) comes to the foreground.
     */
    fun onAppForegrounded(pkg: String) {
        if (currentActivePackage != pkg) {
            currentActivePackage = pkg
            appForegroundedTime = System.currentTimeMillis()
            videosWatchedInSession = 0
            activeVideoSig = null
            sessionStartTime = 0L
            isExitInProgress = false
            Log.d("INHIBIT_GUARD", "Target app foregrounded: $pkg (Launch settling grace active)")
        }
    }

    fun notifyExitStarted() {
        isExitInProgress = true
        exitCooldownUntil = System.currentTimeMillis() + EXIT_COOLDOWN_MS
    }

    fun notifyExitCompleted() {
        isExitInProgress = false
        exitCooldownUntil = maxOf(exitCooldownUntil, System.currentTimeMillis() + 800L)
    }

    fun onScreenDetected(
        newScreen: Screen,
        currentSig: VideoSignature,
        isScrollEvent: Boolean,
        onExit: (String, Int) -> Unit
    ) {
        val now = System.currentTimeMillis()

        if (isExitInProgress || now < exitCooldownUntil) {
            // While exit or transition cooldown is active, ignore all triggers to avoid duplicate actions
            return
        }

        // --- Intentional Post Mode Check (30-Minute Creator Session) ---
        if (isPostModeActive) {
            val remainingSec = (prefs.getLong(KEY_POST_MODE_EXPIRES_AT, 0L) - now) / 1000
            Log.d("INHIBIT_GUARD", "Intentional Post Mode ACTIVE (${remainingSec}s left) -> Passing all events without restriction")
            return
        }

        val isConfirmedVideo = (newScreen == Screen.INSTAGRAM_REEL || newScreen == Screen.YOUTUBE_SHORT)
        val isPossibleVideo = (newScreen == Screen.INSTAGRAM_REEL_POSSIBLE || newScreen == Screen.YOUTUBE_SHORT_POSSIBLE)
        val isAnyVideo = isConfirmedVideo || isPossibleVideo

        val isClearlySafeScreen = (
            newScreen == Screen.INSTAGRAM_CHAT ||
            newScreen == Screen.INSTAGRAM_PROFILE ||
            newScreen == Screen.INSTAGRAM_STORY ||
            newScreen == Screen.INSTAGRAM_HOME ||
            newScreen == Screen.INSTAGRAM_EXPLORE ||
            newScreen == Screen.INSTAGRAM_POST ||
            newScreen == Screen.YOUTUBE_HOME ||
            newScreen == Screen.YOUTUBE_WATCH ||
            newScreen == Screen.OUTSIDE
        )

        // 1. Session Management on Clearly Safe Screens
        if (isClearlySafeScreen) {
            val isImmediateResetScreen = (newScreen == Screen.INSTAGRAM_CHAT || newScreen == Screen.OUTSIDE)
            if (lastLeaveVideoTime == 0L) {
                lastLeaveVideoTime = now
            }
            if (isImmediateResetScreen || (now - lastLeaveVideoTime > SESSION_RESET_TIMEOUT_MS)) {
                if (currentScreen != newScreen || videosWatchedInSession > 0 || activeVideoSig != null) {
                    currentScreen = newScreen
                    activeVideoSig = null
                    videosWatchedInSession = 0
                    sessionStartTime = 0L
                    Log.d("INHIBIT_GUARD", "Reset video session on safe screen: $newScreen (immediate=$isImmediateResetScreen)")
                }
            }
            return
        }

        // If on video or possible video screen, clear the safe leave timer
        if (isAnyVideo) {
            lastLeaveVideoTime = 0L
        }

        // If not a video screen, return
        if (!isConfirmedVideo && !isPossibleVideo) {
            return
        }

        // --- Launch Settling Grace Period ---
        // If app was foregrounded less than 2000ms ago, allow it to settle into Video #1 with ZERO back actions.
        val timeSinceForeground = now - appForegroundedTime
        val isAppLaunchSettling = appForegroundedTime > 0L && timeSinceForeground < APP_LAUNCH_GRACE_MS

        // 2. First Reel / Short in Session -> ALLOW TO WATCH FULLY WITHOUT INTERRUPTION
        if (videosWatchedInSession == 0) {
            currentScreen = newScreen
            sessionStartTime = now
            videosWatchedInSession = 1
            activeVideoSig = currentSig
            totalReelsScrolled++
            onReelCountChanged?.invoke(totalReelsScrolled)
            Log.d("INHIBIT_GUARD", "Allowed Short/Reel #1 to watch fully with ZERO interruption (Sig: $activeVideoSig, Total Scrolled: $totalReelsScrolled)")
            return
        }

        // If in launch settling grace, do not block yet
        if (isAppLaunchSettling) {
            return
        }

        // 3. While Video #1 is playing:
        // ONLY intercept when the user explicitly performs a vertical swipe/scroll to advance to Reel #2!
        if (videosWatchedInSession == 1) {
            val timeSinceStart = now - sessionStartTime
            val isPastSettling = timeSinceStart > INITIAL_SETTLING_GRACE_MS

            val isTargetReel = (newScreen == Screen.INSTAGRAM_REEL || newScreen == Screen.INSTAGRAM_REEL_POSSIBLE) && blockInstagramReels
            val isTargetShort = (newScreen == Screen.YOUTUBE_SHORT || newScreen == Screen.YOUTUBE_SHORT_POSSIBLE) && blockYouTubeShorts

            if ((isTargetReel || isTargetShort) && isScrollEvent && isPastSettling) {
                if (now - lastActionTime > DEBOUNCE_MS) {
                    lastActionTime = now
                    notifyExitStarted()
                    videosWatchedInSession = 2
                    totalReelsScrolled++
                    totalReelsBlocked++

                    val mediaType = if (isTargetReel) "Instagram Reel" else "YouTube Short"
                    val message = "$mediaType scroll stopped"

                    Log.d("INHIBIT_GUARD", "DOOMSCROLL INTERCEPTED: $message on scroll past Reel #1 | Total Blocked: $totalReelsBlocked")
                    onExit(message, totalReelsBlocked)
                }
            }
            return
        }

        // 4. Subsequent Reels / Shorts in the same session:
        // Only trigger on explicit scroll event or if past debounce
        val isTargetReel = (newScreen == Screen.INSTAGRAM_REEL || newScreen == Screen.INSTAGRAM_REEL_POSSIBLE) && blockInstagramReels
        val isTargetShort = (newScreen == Screen.YOUTUBE_SHORT || newScreen == Screen.YOUTUBE_SHORT_POSSIBLE) && blockYouTubeShorts

        if ((isTargetReel || isTargetShort) && isScrollEvent) {
            if (now - lastActionTime > DEBOUNCE_MS) {
                lastActionTime = now
                notifyExitStarted()
                videosWatchedInSession++
                totalReelsScrolled++
                totalReelsBlocked++

                val mediaType = if (isTargetReel) "Instagram Reel" else "YouTube Short"
                val message = "$mediaType limit reached"

                Log.d("INHIBIT_GUARD", "DOOMSCROLL INTERCEPTED: $message | Total Blocked: $totalReelsBlocked")
                onExit(message, totalReelsBlocked)
            }
        }
    }

    fun reset() {
        currentActivePackage = ""
        currentScreen = Screen.UNKNOWN
        activeVideoSig = null
        videosWatchedInSession = 0
        sessionStartTime = 0L
        lastLeaveVideoTime = 0L
        isExitInProgress = false
        exitCooldownUntil = 0L
    }

    companion object {
        private const val DEBOUNCE_MS = 600L
        private const val INITIAL_SETTLING_GRACE_MS = 1500L
        private const val APP_LAUNCH_GRACE_MS = 2000L
        private const val SESSION_RESET_TIMEOUT_MS = 1200L
        private const val EXIT_COOLDOWN_MS = 1500L

        const val PREFS_STATS = "inhibit_stats_prefs"
        const val KEY_TOTAL_REELS_SCROLLED = "total_reels_scrolled"
        const val KEY_TOTAL_REELS_BLOCKED = "total_reels_blocked"
        const val KEY_POST_MODE_EXPIRES_AT = "post_mode_expires_at"
    }
}
