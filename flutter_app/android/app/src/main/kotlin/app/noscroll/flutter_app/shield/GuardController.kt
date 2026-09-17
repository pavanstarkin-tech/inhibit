package app.noscroll.flutter_app.shield

import android.content.Context
import android.content.SharedPreferences
import android.util.Log

/**
 * State machine and policy controller for doomscroll interception.
 *
 * Core Policies:
 * 1. Allow 1st Reel / Short per session.
 * 2. Block 2nd and subsequent Reels / Shorts immediately and redirect to Home tab.
 * 3. Separate transient transition grace (500ms) from true session reset timeout (2000ms).
 * 4. Normal posts, Explore search/grid, Stories, and Chats are 100% unrestricted.
 */
class GuardController(private val context: Context) {

    var allowedVideos: Int = 1
    var blockInstagramReels: Boolean = true
    var blockInstagramExplore: Boolean = false // Explore grid allowed; Reels inside Explore guarded
    var blockYouTubeShorts: Boolean = true
    var isExitInProgress: Boolean = false

    private var prefs: SharedPreferences = context.getSharedPreferences(PREFS_STATS, Context.MODE_PRIVATE)

    private var currentScreen: Screen = Screen.UNKNOWN
    private var activeVideoSig: VideoSignature? = null
    private var videosWatchedInSession: Int = 0
    private var sessionStartTime: Long = 0L
    private var lastActionTime: Long = 0L
    private var lastLeaveVideoTime: Long = 0L

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

    fun onScreenDetected(
        newScreen: Screen,
        currentSig: VideoSignature,
        isScrollEvent: Boolean,
        onExit: (String, Int) -> Unit
    ) {
        if (isExitInProgress) {
            // While exit is in progress, ignore duplicate triggers to preserve idempotency
            return
        }

        val now = System.currentTimeMillis()

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

        // 1. Session Management on Clearly Safe Screens (Require 2000ms true dwell before resetting session)
        if (isClearlySafeScreen) {
            if (lastLeaveVideoTime == 0L) {
                lastLeaveVideoTime = now
            }
            if (now - lastLeaveVideoTime > SESSION_RESET_TIMEOUT_MS) {
                if (currentScreen != newScreen || videosWatchedInSession > 0 || activeVideoSig != null) {
                    currentScreen = newScreen
                    activeVideoSig = null
                    videosWatchedInSession = 0
                    sessionStartTime = 0L
                    Log.d("INHIBIT_GUARD", "Reset video session on safe screen: $newScreen (dwelled ${now - lastLeaveVideoTime}ms)")
                }
            }
            return
        }

        // If on video or possible video screen, clear the safe leave timer
        if (isAnyVideo) {
            lastLeaveVideoTime = 0L
        }

        // If not a confirmed video (and not an active session scroll on possible video), return
        if (!isConfirmedVideo && !(isPossibleVideo && videosWatchedInSession >= allowedVideos && isScrollEvent)) {
            return
        }

        // 2. First Reel / Short in Session -> ALLOW
        if (videosWatchedInSession == 0) {
            currentScreen = newScreen
            sessionStartTime = now
            videosWatchedInSession = 1
            activeVideoSig = currentSig
            totalReelsScrolled++
            onReelCountChanged?.invoke(totalReelsScrolled)
            Log.d("INHIBIT_GUARD", "Allowed Short/Reel #1 (Sig: $activeVideoSig, Total Scrolled Today: $totalReelsScrolled)")
            return
        }

        // 3. While Video #1 is playing: Continuously enrich activeVideoSig with newly rendered metadata
        if (videosWatchedInSession == 1) {
            if (activeVideoSig != null && currentSig.isNotEmpty()) {
                activeVideoSig = activeVideoSig!!.merge(currentSig)
            }
        }

        // 4. Second Reel / Short Interception (User Swipe gesture or Distinct New Video Signature)
        val isTargetReel = (newScreen == Screen.INSTAGRAM_REEL || newScreen == Screen.INSTAGRAM_REEL_POSSIBLE) && blockInstagramReels
        val isTargetShort = (newScreen == Screen.YOUTUBE_SHORT || newScreen == Screen.YOUTUBE_SHORT_POSSIBLE) && blockYouTubeShorts

        if (isTargetReel || isTargetShort) {
            if (videosWatchedInSession >= allowedVideos) {
                val isDistinctNewVideo = activeVideoSig != null && currentSig.isDistinctFrom(activeVideoSig)
                val isSwipeEvent = isScrollEvent && (now - sessionStartTime > SETTLING_GRACE_MS)

                val shouldIntercept = isDistinctNewVideo || isSwipeEvent

                if (shouldIntercept) {
                    Log.d("INHIBIT_GUARD", "TRANSITION EVAL: screen=$newScreen previousSig='$activeVideoSig' currentSig='$currentSig' isDistinctNewVideo=$isDistinctNewVideo isSwipeEvent=$isSwipeEvent action=BLOCK")
                    if (now - lastActionTime > DEBOUNCE_MS) {
                        lastActionTime = now
                        videosWatchedInSession++
                        totalReelsScrolled++
                        totalReelsBlocked++

                        val mediaType = if (isTargetReel) "Reel" else "Short"
                        val message = "$mediaType limit reached"

                        Log.d("INHIBIT_GUARD", "DOOMSCROLL INTERCEPTED: $message | Total Blocked: $totalReelsBlocked")
                        onExit(message, totalReelsBlocked)
                    }
                }
            }
        }
    }

    fun reset() {
        currentScreen = Screen.UNKNOWN
        activeVideoSig = null
        videosWatchedInSession = 0
        sessionStartTime = 0L
        lastLeaveVideoTime = 0L
        isExitInProgress = false
    }

    companion object {
        private const val DEBOUNCE_MS = 400L
        private const val SETTLING_GRACE_MS = 250L
        private const val SESSION_RESET_TIMEOUT_MS = 2000L

        const val PREFS_STATS = "inhibit_stats_prefs"
        const val KEY_TOTAL_REELS_SCROLLED = "total_reels_scrolled"
        const val KEY_TOTAL_REELS_BLOCKED = "total_reels_blocked"
        const val KEY_POST_MODE_EXPIRES_AT = "post_mode_expires_at"
    }
}
