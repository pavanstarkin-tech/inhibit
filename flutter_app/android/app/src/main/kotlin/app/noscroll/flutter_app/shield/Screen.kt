package app.noscroll.flutter_app.shield

/**
 * High-level screen classification for monitored applications.
 */
enum class Screen {
    UNKNOWN,
    OUTSIDE,

    // Instagram Screens
    INSTAGRAM_HOME,
    INSTAGRAM_EXPLORE,
    INSTAGRAM_POST,
    INSTAGRAM_CHAT,
    INSTAGRAM_REEL,              // Confirmed short-form video viewer (score >= 45 + temporal confirmation)
    INSTAGRAM_REEL_POSSIBLE,     // Passive candidate / transitioning (score 25-44 or pending temporal confirmation)
    INSTAGRAM_STORY,
    INSTAGRAM_PROFILE,

    // YouTube Screens
    YOUTUBE_HOME,
    YOUTUBE_SHORT,             // Confirmed short-form video viewer (score >= 45 + temporal confirmation)
    YOUTUBE_SHORT_POSSIBLE,    // Passive candidate / transitioning
    YOUTUBE_WATCH,
    YOUTUBE_OTHER
}

