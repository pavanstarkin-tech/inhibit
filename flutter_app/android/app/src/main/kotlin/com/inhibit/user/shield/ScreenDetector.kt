package com.inhibit.user.shield

import android.graphics.Rect
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

/**
 * Structured signature capturing multiple resilient properties of an active video.
 */
data class VideoSignature(
    val author: String = "",
    val audio: String = "",
    val captionSnippet: String = "",
    val tokens: Set<String> = emptySet()
) {
    fun isNotEmpty(): Boolean = author.isNotEmpty() || audio.isNotEmpty() || captionSnippet.isNotEmpty() || tokens.isNotEmpty()

    fun isSimilarTo(other: VideoSignature?): Boolean {
        if (other == null) return false
        if (author.isNotEmpty() && other.author.isNotEmpty() && author.equals(other.author, ignoreCase = true)) {
            return true
        }
        if (audio.isNotEmpty() && other.audio.isNotEmpty() && audio.equals(other.audio, ignoreCase = true)) {
            return true
        }
        if (captionSnippet.isNotEmpty() && other.captionSnippet.isNotEmpty() && captionSnippet.equals(other.captionSnippet, ignoreCase = true)) {
            return true
        }
        if (tokens.isNotEmpty() && other.tokens.isNotEmpty()) {
            val intersection = tokens.intersect(other.tokens)
            if (intersection.size >= 2) return true
        }
        return false
    }

    fun isDistinctFrom(other: VideoSignature?): Boolean {
        if (other == null) return false
        if (author.isNotEmpty() && other.author.isNotEmpty() && author.length >= 2 && other.author.length >= 2) {
            if (!author.equals(other.author, ignoreCase = true)) {
                return true
            }
        }
        if (audio.isNotEmpty() && other.audio.isNotEmpty() && audio.length >= 3 && other.audio.length >= 3) {
            if (!audio.equals(other.audio, ignoreCase = true)) {
                return true
            }
        }
        if (captionSnippet.isNotEmpty() && other.captionSnippet.isNotEmpty() && captionSnippet.length >= 10 && other.captionSnippet.length >= 10) {
            if (!captionSnippet.equals(other.captionSnippet, ignoreCase = true)) {
                return true
            }
        }
        return false
    }

    fun merge(other: VideoSignature): VideoSignature {
        return VideoSignature(
            author = if (this.author.isNotEmpty()) this.author else other.author,
            audio = if (this.audio.isNotEmpty()) this.audio else other.audio,
            captionSnippet = if (this.captionSnippet.isNotEmpty()) this.captionSnippet else other.captionSnippet,
            tokens = this.tokens + other.tokens
        )
    }

    override fun toString(): String {
        return listOf(author, audio, captionSnippet).filter { it.isNotEmpty() }.joinToString(" | ")
    }
}

/**
 * Matched diagnostic evidence for short-video inspection.
 */
data class TreeEvidence(
    val classes: List<String>,
    val ids: List<String>,
    val texts: List<String>,
    val descriptions: List<String>
)

/**
 * Ultra-fast single-pass in-memory snapshot of accessibility node hierarchy.
 * Traverses up to 300 nodes and depth 25 with zero IPC recursion overhead.
 */
class UiTreeSnapshot(root: AccessibilityNodeInfo?) {
    val viewIds = HashSet<String>()
    val texts = ArrayList<String>()
    val descriptions = ArrayList<String>()
    val classNames = ArrayList<String>()
    val idToText = HashMap<String, String>()
    val visibleTokens = LinkedHashSet<String>()

    var nodeCount: Int = 0
        private set
    var maxDepthReached: Int = 0
        private set
    var truncated: Boolean = false
        private set
    var nullChildCount: Int = 0
        private set

    var hasVerticalFullScreenVideo = false
    var hasVerticalScrollableContainer = false
    var homeTabNode: AccessibilityNodeInfo? = null

    private val staticNavTokens = setOf(
        "home", "search", "search and explore", "reels", "profile", "activity", "create", "direct", "explore",
        "camera", "options", "audio", "original audio", "like", "liked", "comment", "comments", "share", "remix", "tab",
        "double tap to like", "back", "more", "save", "saved", "send"
    )

    init {
        if (root != null) {
            scan(root, depth = 0, maxDepth = 20, maxNodes = 150)
        }
    }

    private val tempRect = Rect()

    private fun scan(node: AccessibilityNodeInfo, depth: Int, maxDepth: Int, maxNodes: Int) {
        if (depth > maxDepthReached) {
            maxDepthReached = depth
        }
        if (depth > maxDepth || nodeCount >= maxNodes) {
            truncated = true
            return
        }
        nodeCount++

        val className = node.className?.toString()?.trim().orEmpty()
        if (className.isNotEmpty()) {
            val classLower = className.lowercase()
            classNames.add(classLower)
            if (classLower.contains("viewpager") || classLower.contains("recyclerview") || classLower.contains("scrollview")) {
                if (node.isScrollable) {
                    hasVerticalScrollableContainer = true
                }
            }
        }

        val viewId = node.viewIdResourceName
        if (!viewId.isNullOrEmpty()) {
            val idLower = viewId.lowercase()
            viewIds.add(idLower)
            val textVal = node.text?.toString()?.trim() ?: node.contentDescription?.toString()?.trim()
            if (!textVal.isNullOrEmpty()) {
                idToText[idLower] = textVal
            }
        }

        val text = node.text?.toString()?.trim()
        if (!text.isNullOrEmpty()) {
            val textLower = text.lowercase()
            texts.add(textLower)
            if (text.length > 2 && !staticNavTokens.contains(textLower) && visibleTokens.size < 10) {
                visibleTokens.add(textLower)
            }
        }

        val desc = node.contentDescription?.toString()?.trim()
        if (!desc.isNullOrEmpty()) {
            val descLower = desc.lowercase()
            descriptions.add(descLower)
            if (homeTabNode == null && (descLower == "home" || descLower == "feed" || viewId?.lowercase()?.contains("feed_tab") == true || viewId?.lowercase()?.contains("tab_icon_home") == true)) {
                homeTabNode = node
            }
            if (desc.length > 3 && !staticNavTokens.contains(descLower) && visibleTokens.size < 10) {
                visibleTokens.add(descLower)
            }
        }

        // Check vertical video bounds
        if (!hasVerticalFullScreenVideo) {
            try {
                node.getBoundsInScreen(tempRect)
                val width = tempRect.width()
                val height = tempRect.height()
                if (height > width && height >= 600 && width >= 300) {
                    val classLower = className.lowercase()
                    val idLower = viewId?.lowercase().orEmpty()
                    if (classLower.contains("surface") ||
                        classLower.contains("texture") ||
                        classLower.contains("video") ||
                        classLower.contains("player") ||
                        idLower.contains("video") ||
                        idLower.contains("player") ||
                        idLower.contains("surface") ||
                        idLower.contains("texture") ||
                        idLower.contains("media")
                    ) {
                        hasVerticalFullScreenVideo = true
                    }
                }
            } catch (_: Exception) {}
        }

        val childCount = node.childCount
        for (i in 0 until childCount) {
            val child = node.getChild(i)
            if (child == null) {
                nullChildCount++
                continue
            }
            scan(child, depth + 1, maxDepth, maxNodes)
            if (nodeCount >= maxNodes) {
                truncated = true
                break
            }
        }
    }

    fun hasIdContaining(snippet: String): Boolean {
        val snipLower = snippet.lowercase()
        return viewIds.any { it.contains(snipLower) }
    }

    fun hasIdAny(vararg snippets: String): Boolean {
        for (snippet in snippets) {
            val snipLower = snippet.lowercase()
            if (viewIds.any { it.contains(snipLower) }) return true
        }
        return false
    }

    fun hasTextContaining(query: String): Boolean {
        val q = query.lowercase()
        return texts.any { it.contains(q) }
    }

    fun hasTextAny(vararg queries: String): Boolean {
        for (query in queries) {
            val q = query.lowercase()
            if (texts.any { it.contains(q) }) return true
        }
        return false
    }

    fun hasDescContaining(query: String): Boolean {
        val q = query.lowercase()
        return descriptions.any { it.contains(q) }
    }

    fun hasDescAny(vararg queries: String): Boolean {
        for (query in queries) {
            val q = query.lowercase()
            if (descriptions.any { it.contains(q) }) return true
        }
        return false
    }

    fun hasClassContaining(query: String): Boolean {
        val q = query.lowercase()
        return classNames.any { it.contains(q) }
    }

    fun getTextForIds(snippets: List<String>): String {
        for (snip in snippets) {
            val snipLower = snip.lowercase()
            for ((k, v) in idToText) {
                if (k.contains(snipLower)) return v
            }
        }
        return ""
    }

    fun extractMatchedEvidence(pkg: String): TreeEvidence {
        val keywords = if (pkg == ScreenDetector.PKG_INSTAGRAM) {
            setOf("clips", "reel", "video", "audio", "original", "like", "comment", "share", "send", "music")
        } else {
            setOf("shorts", "short", "remix", "sound", "create", "like", "comment", "share", "subscribe", "video")
        }

        val matchedClasses = classNames.filter { cn -> keywords.any { kw -> cn.contains(kw) } }.distinct().take(10)
        val matchedIds = viewIds.filter { id -> keywords.any { kw -> id.contains(kw) } }.distinct().take(15)
        val matchedTexts = texts.filter { txt -> keywords.any { kw -> txt.contains(kw) } }.distinct().take(10)
        val matchedDescriptions = descriptions.filter { desc -> keywords.any { kw -> desc.contains(kw) } }.distinct().take(10)

        return TreeEvidence(matchedClasses, matchedIds, matchedTexts, matchedDescriptions)
    }
}

/**
 * Robust multi-signal screen classifier with structural verification and confidence scoring.
 */
class ScreenDetector {

    private var latestSnapshot: UiTreeSnapshot? = null

    fun setSnapshot(snapshot: UiTreeSnapshot) {
        latestSnapshot = snapshot
    }

    fun detect(event: AccessibilityEvent, root: AccessibilityNodeInfo?): Screen {
        val pkg = event.packageName?.toString().orEmpty()
        val className = event.className?.toString().orEmpty()
        return detect(pkg, className, root)
    }

    fun detect(pkg: String, className: String = "", root: AccessibilityNodeInfo?): Screen {
        val snapshot = UiTreeSnapshot(root)
        latestSnapshot = snapshot
        return detectWithSnapshot(pkg, className, snapshot)
    }

    fun detectWithSnapshot(pkg: String, className: String, snapshot: UiTreeSnapshot): Screen {
        latestSnapshot = snapshot

        if (pkg == PKG_INSTAGRAM) {
            resetYtTemporalState()
            return detectInstagram(className, snapshot)
        } else if (pkg == PKG_YOUTUBE) {
            resetInstaTemporalState()
            return detectYouTube(className, snapshot)
        }

        resetInstaTemporalState()
        resetYtTemporalState()
        return Screen.OUTSIDE
    }

    private var consecutiveInstaReelHits = 0
    private var lastInstaCandidateTime = 0L

    private var consecutiveYtShortHits = 0
    private var lastYtCandidateTime = 0L

    private fun resetInstaTemporalState() {
        consecutiveInstaReelHits = 0
        lastInstaCandidateTime = 0L
    }

    private fun resetYtTemporalState() {
        consecutiveYtShortHits = 0
        lastYtCandidateTime = 0L
    }

    private var lastLoggedInstaSig = ""
    private var lastLoggedInstaTime = 0L

    private var lastLoggedYtSig = ""
    private var lastLoggedYtTime = 0L

    // ==========================================
    // INSTAGRAM CLASSIFICATION
    // ==========================================

    private fun detectInstagram(
        className: String,
        snapshot: UiTreeSnapshot
    ): Screen {
        // A. Package validation handled in detect()

        // B. Direct Messages / Chats Check (HARD EXCLUSION - NEVER TOUCH CHATS)
        if (isChatActive(className, snapshot)) {
            resetInstaTemporalState()
            logInstagramDiagnostic(className, Screen.INSTAGRAM_CHAT, score = 0, strong = false, supporting = false,
                clipsClass = false, videoContainer = false, viewPager = false, reelsInd = false,
                author = false, audio = false, like = false, comment = false, share = false)
            return Screen.INSTAGRAM_CHAT
        }

        // Stories / Statuses Check (Always Safe)
        if (isStoryActive(className, snapshot)) {
            resetInstaTemporalState()
            logInstagramDiagnostic(className, Screen.INSTAGRAM_STORY, score = 0, strong = false, supporting = false,
                clipsClass = false, videoContainer = false, viewPager = false, reelsInd = false,
                author = false, audio = false, like = false, comment = false, share = false)
            return Screen.INSTAGRAM_STORY
        }

        // Profile Screen Check (Safe)
        if (isProfileActive(snapshot)) {
            resetInstaTemporalState()
            logInstagramDiagnostic(className, Screen.INSTAGRAM_PROFILE, score = 0, strong = false, supporting = false,
                clipsClass = false, videoContainer = false, viewPager = false, reelsInd = false,
                author = false, audio = false, like = false, comment = false, share = false)
            return Screen.INSTAGRAM_PROFILE
        }

        // C. Short-Video Viewer Detection (Instagram Reels)
        val instaEval = evaluateInstagramReel(className, snapshot)
        val reelConfidence = instaEval.score

        var finalScreen = Screen.INSTAGRAM_HOME

        if (reelConfidence >= REEL_CONFIDENCE_THRESHOLD) {
            finalScreen = Screen.INSTAGRAM_REEL
            logTransitionReason(Screen.INSTAGRAM_REEL, reelConfidence, instaEval.reasons)
        } else if (reelConfidence >= REEL_POSSIBLE_THRESHOLD) {
            finalScreen = Screen.INSTAGRAM_REEL_POSSIBLE
            logTransitionReason(Screen.INSTAGRAM_REEL_POSSIBLE, reelConfidence, instaEval.reasons)
        } else {
            // D. Explore Search & Discovery Grid (Allow Browsing)
            if (isExploreGridActive(className, snapshot)) {
                finalScreen = Screen.INSTAGRAM_EXPLORE
            }
            // E. Single Post Viewer (Photos, Carousels, Standard Feed Item Detail)
            else if (isPostDetailActive(className, snapshot)) {
                finalScreen = Screen.INSTAGRAM_POST
            }
            // F. Home Feed (Safe browsing of standard feed posts)
            else {
                finalScreen = Screen.INSTAGRAM_HOME
            }
        }

        logInstagramDiagnostic(
            className = className,
            screen = finalScreen,
            score = reelConfidence,
            strong = instaEval.hasStrongStructure,
            supporting = instaEval.hasSupportingEvidence,
            clipsClass = instaEval.hasClipsClass,
            videoContainer = instaEval.hasVideoContainer,
            viewPager = instaEval.hasViewPager,
            reelsInd = instaEval.hasReelsIndicator,
            author = instaEval.hasAuthorName,
            audio = instaEval.hasAudioTrack,
            like = instaEval.hasLike,
            comment = instaEval.hasComment,
            share = instaEval.hasShare
        )

        return finalScreen
    }

    private data class InstagramEvaluation(
        val score: Int,
        val hasStrongStructure: Boolean,
        val hasSupportingEvidence: Boolean,
        val hasClipsClass: Boolean,
        val hasVideoContainer: Boolean,
        val hasViewPager: Boolean,
        val hasReelsIndicator: Boolean,
        val hasAuthorName: Boolean,
        val hasAudioTrack: Boolean,
        val hasLike: Boolean,
        val hasComment: Boolean,
        val hasShare: Boolean,
        val reasons: List<String>
    )

    private fun evaluateInstagramReel(className: String, snapshot: UiTreeSnapshot): InstagramEvaluation {
        var score = 0
        val reasons = mutableListOf<String>()

        // 1. Clips / Reel Viewer Class / Activity / Fragment Signal
        val hasClipsClass = className.contains("ClipsViewer", ignoreCase = true) ||
                            className.contains("ClipsSwipeRefreshContainer", ignoreCase = true) ||
                            className.contains("ClipsViewerFragment", ignoreCase = true) ||
                            className.contains("ReelViewerFragment", ignoreCase = true) ||
                            className.contains("ClipsViewerActivity", ignoreCase = true) ||
                            className.contains("ClipsViewerLauncher", ignoreCase = true) ||
                            className.contains("ReelsActivity", ignoreCase = true) ||
                            snapshot.hasClassContaining("ClipsViewer") ||
                            snapshot.hasClassContaining("ClipsSwipeRefreshContainer")

        if (hasClipsClass) {
            score += 40
            reasons.add("clips_class")
        }

        // Hard Exclusion: Stories viewer & story progress bars are ALWAYS safe and never Reels
        val hasStoryElements = snapshot.hasIdAny("reel_viewer_progress_bar", "story_progress", "story_viewer_container", "direct_story_reply", "story_reply_composer") ||
                               snapshot.hasDescAny("reply to story", "send message to")

        if (hasStoryElements) {
            return InstagramEvaluation(
                score = 0,
                hasStrongStructure = false,
                hasSupportingEvidence = false,
                hasClipsClass = false,
                hasVideoContainer = false,
                hasViewPager = false,
                hasReelsIndicator = false,
                hasAuthorName = false,
                hasAudioTrack = false,
                hasLike = false,
                hasComment = false,
                hasShare = false,
                reasons = listOf("story_viewer_exclusion")
            )
        }

        // Hard Exclusion: Active Stories tray / Suggested Reels carousel / Grid layout unequivocally indicates Home/Explore
        val hasStoriesTray = snapshot.hasIdAny("tray_recycler_view", "stories_container", "reel_tray_container", "reels_tray_container", "stories_tray") ||
                             snapshot.hasDescContaining("reels tray container") ||
                             snapshot.hasDescContaining("stories tray")

        val hasGridStructure = snapshot.descriptions.any { it.contains("at row ") && it.contains("column") }
        val hasHomeFeedMarkers = snapshot.hasIdAny("main_feed", "feed_post") ||
                                 snapshot.hasDescAny("activity feed", "your story")

        val hasClipsViewerElements = snapshot.viewIds.any { id ->
            (id.contains("clips_") || id.contains("reel_viewer") || id.contains("root_clips")) && !id.contains("clips_tab")
        }

        if ((hasStoriesTray || hasGridStructure || hasHomeFeedMarkers) && !hasClipsViewerElements && !hasClipsClass && !snapshot.hasVerticalFullScreenVideo) {
            return InstagramEvaluation(
                score = 0,
                hasStrongStructure = false,
                hasSupportingEvidence = false,
                hasClipsClass = false,
                hasVideoContainer = false,
                hasViewPager = false,
                hasReelsIndicator = false,
                hasAuthorName = false,
                hasAudioTrack = false,
                hasLike = false,
                hasComment = false,
                hasShare = false,
                reasons = listOf("home_tray_or_grid_exclusion")
            )
        }

        // 2. Video Container Signal (including wildcard clips_ and reel_ IDs)
        val hasClipsWildcardId = snapshot.viewIds.any { id ->
            (id.contains("clips_") || id.contains("reel_viewer") || id.contains("root_clips")) && !id.contains("clips_tab")
        }

        val hasVideoContainerId = hasClipsWildcardId || snapshot.hasIdAny(
            "clips_video_container",
            "clips_item_container",
            "reel_viewer_container",
            "clips_media_component",
            "viewer_media_view",
            "reel_viewer_media_layout",
            "clips_overlay_container",
            "clips_action_bar_container",
            "clips_ufi_container",
            "clips_video_surface_view",
            "video_container"
        )
        val hasVideoContainer = hasVideoContainerId || snapshot.hasVerticalFullScreenVideo
        if (hasVideoContainer) {
            score += 35
            reasons.add(if (hasVideoContainerId) "clips_container" else "vertical_video")
        }

        // 3. ViewPager / Pager / Recycler Layout Signal
        val hasViewPagerId = snapshot.hasIdAny(
            "clips_viewer_view_pager",
            "clips_viewer_viewpager",
            "clips_swipe_refresh_container",
            "reel_recycler",
            "clips_recycler_view"
        )
        val hasViewPager = hasViewPagerId || (snapshot.hasVerticalScrollableContainer && (hasClipsClass || hasClipsWildcardId))
        if (hasViewPager) {
            score += 25
            reasons.add("view_pager")
        }

        // 4. Reels Specific Indicator
        val hasReelsIndicator = snapshot.hasTextAny("reel by", "watch more reels", "suggested reels", "remix this reel", "sequence this reel", "original audio") ||
                                snapshot.hasDescAny("reel by", "watch more reels", "suggested reels", "remix this reel", "sequence this reel", "original audio")
        if (hasReelsIndicator) {
            score += 20
            reasons.add("reels_indicator")
        }

        // 5. Author / Creator Name Signal
        val hasAuthorName = snapshot.hasIdAny("clips_author_name", "author_name", "user_name", "profile_name") ||
                            (snapshot.hasTextAny("follow", "following") && (hasClipsClass || hasClipsWildcardId))
        if (hasAuthorName) {
            score += 15
            reasons.add("author")
        }

        // 6. Audio Track Signal
        val hasAudioTrack = snapshot.hasIdAny("clips_music_pill", "clips_audio_track_title", "music_title", "audio_track_title", "audio_pill") ||
                            snapshot.hasDescAny("original audio", "use audio") ||
                            snapshot.hasTextAny("original audio")
        if (hasAudioTrack) {
            score += 15
            reasons.add("audio")
        }

        // 7. Action Controls (Like, Comment, Share)
        val hasLike = snapshot.hasDescAny("like", "liked", "double tap to like") || snapshot.hasIdAny("like_button", "row_feed_button_like")
        val hasComment = snapshot.hasDescAny("comment", "comments") || snapshot.hasIdAny("comment_button", "row_feed_button_comment")
        val hasShare = snapshot.hasDescAny("share", "send", "share reel", "share video") || snapshot.hasIdAny("button_share", "row_feed_button_share")

        if (hasLike) score += 10
        if (hasComment) score += 10
        if (hasShare) score += 10
        if (hasLike || hasComment || hasShare) {
            reasons.add("action_rail")
        }

        // Strong structure requires: clips class, clips container, viewpager, or full screen vertical video with reels context
        val hasStrongStructure = hasClipsClass ||
                                 hasVideoContainerId ||
                                 hasViewPagerId ||
                                 (hasReelsIndicator && (hasVideoContainer || hasAudioTrack || (hasLike && hasComment))) ||
                                 (snapshot.hasVerticalFullScreenVideo && (hasReelsIndicator || hasAudioTrack))

        // Supporting evidence requires at least 1 secondary signal (author, audio, indicator, or actions)
        val hasSupportingEvidence = hasAuthorName ||
                                    hasAudioTrack ||
                                    hasReelsIndicator ||
                                    hasClipsWildcardId ||
                                    (hasLike && hasComment) ||
                                    (hasLike && hasShare) ||
                                    (hasComment && hasShare)

        // Only award the score if structural requirements are met (prevents Home feed like/comment from scoring)
        val finalScore = if (hasStrongStructure && hasSupportingEvidence) score else 0

        return InstagramEvaluation(
            score = finalScore,
            hasStrongStructure = hasStrongStructure,
            hasSupportingEvidence = hasSupportingEvidence,
            hasClipsClass = hasClipsClass,
            hasVideoContainer = hasVideoContainer,
            hasViewPager = hasViewPager,
            hasReelsIndicator = hasReelsIndicator,
            hasAuthorName = hasAuthorName,
            hasAudioTrack = hasAudioTrack,
            hasLike = hasLike,
            hasComment = hasComment,
            hasShare = hasShare,
            reasons = reasons
        )
    }

    private fun logInstagramDiagnostic(
        className: String,
        screen: Screen,
        score: Int,
        strong: Boolean,
        supporting: Boolean,
        clipsClass: Boolean,
        videoContainer: Boolean,
        viewPager: Boolean,
        reelsInd: Boolean,
        author: Boolean,
        audio: Boolean,
        like: Boolean,
        comment: Boolean,
        share: Boolean
    ) {
        val sig = "$screen|$score|$strong|$supporting|$clipsClass|$videoContainer|$viewPager|$reelsInd|$author|$audio|$like|$comment|$share"
        val now = System.currentTimeMillis()
        if (sig != lastLoggedInstaSig || now - lastLoggedInstaTime > 1500L) {
            lastLoggedInstaSig = sig
            lastLoggedInstaTime = now
            Log.d("INHIBIT_DETECT",
                "pkg=$PKG_INSTAGRAM\n" +
                "class=$className\n" +
                "screen=$screen\n" +
                "score=$score\n" +
                "strongStructure=$strong\n" +
                "supportingEvidence=$supporting\n" +
                "hasClipsClass=$clipsClass\n" +
                "hasVideoContainer=$videoContainer\n" +
                "hasViewPager=$viewPager\n" +
                "hasReelsIndicator=$reelsInd\n" +
                "hasAuthorName=$author\n" +
                "hasAudioTrack=$audio\n" +
                "hasLike=$like\n" +
                "hasComment=$comment\n" +
                "hasShare=$share"
            )
        }
    }

    private fun isChatActive(className: String, snapshot: UiTreeSnapshot): Boolean {
        if (className.contains("DirectThread", ignoreCase = true) ||
            className.contains("DirectInbox", ignoreCase = true) ||
            className.contains("DirectMessages", ignoreCase = true) ||
            className.contains("DirectVisualMessageViewer", ignoreCase = true)
        ) {
            return true
        }

        val hasClipsViewer = snapshot.hasIdContaining("clips_") || snapshot.hasIdContaining("reel_viewer")
        if (hasClipsViewer) return false

        return snapshot.hasIdAny(
            "row_thread_composer_textarea",
            "direct_unified_inbox",
            "direct_text_message_glyph",
            "row_inbox_container",
            "direct_recipient_picker"
        ) || (snapshot.hasDescAny("search in chat", "direct message") && !snapshot.hasDescAny("reels", "like", "comment", "share"))
    }

    private fun isStoryActive(className: String, snapshot: UiTreeSnapshot): Boolean {
        // 1. Story Viewer Classes & Activities
        if (className.contains("StoryViewer", ignoreCase = true) ||
            className.contains("StatusViewer", ignoreCase = true) ||
            className.contains("ReelViewerFragment", ignoreCase = true) ||
            className.contains("StoryViewerFragment", ignoreCase = true) ||
            className.contains("StoryViewerActivity", ignoreCase = true)
        ) {
            // If it has story progress bars or story reply bar, it's definitely a Story
            if (snapshot.hasIdAny("reel_viewer_progress_bar", "story_progress", "story_viewer_container", "message_composer_container", "direct_story_reply", "send_message_bar")) {
                return true
            }
        }

        // 2. Story / Post Creation, Camera, and Upload Flows
        if (className.contains("CameraActivity", ignoreCase = true) ||
            className.contains("CreationActivity", ignoreCase = true) ||
            className.contains("CaptureActivity", ignoreCase = true) ||
            className.contains("GalleryActivity", ignoreCase = true) ||
            className.contains("MediaCaptureActivity", ignoreCase = true) ||
            className.contains("QuickCamActivity", ignoreCase = true) ||
            className.contains("CreationCameraFragment", ignoreCase = true) ||
            className.contains("StoryCreationActivity", ignoreCase = true) ||
            className.contains("DirectStoryReplyActivity", ignoreCase = true)
        ) {
            return true
        }

        // 3. Story progress bars and reply composer IDs
        if (snapshot.hasIdAny(
            "story_progress",
            "story_viewer_container",
            "reel_viewer_progress_bar",
            "reel_viewer_tall_story_cover",
            "direct_story_reply",
            "story_reply_composer",
            "camera_shutter_button",
            "gallery_grid",
            "story_capture_button",
            "post_capture_button",
            "share_to_story_button",
            "your_story_button",
            "close_friends_button",
            "story_share_sheet"
        )) {
            return true
        }

        // 4. Content descriptions for Story interactions
        if (snapshot.hasDescAny("reply to story", "send message to", "your story", "story reactions", "share to your story", "take a story photo", "record a story")) {
            return true
        }

        return false
    }

    private fun isProfileActive(snapshot: UiTreeSnapshot): Boolean {
        return snapshot.hasDescAny("edit profile", "share profile") ||
               snapshot.hasIdAny("profile_tabs_container", "profile_header_container")
    }

    private fun isExploreGridActive(className: String, snapshot: UiTreeSnapshot): Boolean {
        if (isSearchActive(className, snapshot)) return true

        val hasSearchBox = snapshot.hasIdAny("action_bar_search_edit_text", "search_edit_text")

        val hasStoriesTray = snapshot.hasIdAny("tray_recycler_view", "stories_container", "reel_tray_container", "reels_tray_container", "stories_tray") ||
                             snapshot.hasDescContaining("reels tray container")

        val hasHomeFeed = snapshot.hasIdAny("main_feed", "feed_post") || snapshot.hasDescAny("instagram", "activity feed")

        return hasSearchBox && !hasStoriesTray && !hasHomeFeed
    }

    private fun isPostDetailActive(className: String, snapshot: UiTreeSnapshot): Boolean {
        val isPostViewer = className.contains("FeedViewer", ignoreCase = true) ||
                           snapshot.hasIdAny("row_feed_photo_profile_name", "row_feed_comment_textview_layout")
        val isClips = evaluateInstagramReel(className, snapshot).score >= REEL_CONFIDENCE_THRESHOLD
        return isPostViewer && !isClips
    }

    private fun isSearchActive(className: String, snapshot: UiTreeSnapshot): Boolean {
        if (className.contains("SearchTypeahead", ignoreCase = true) ||
            className.contains("SearchHistory", ignoreCase = true) ||
            className.contains("SearchResult", ignoreCase = true)
        ) {
            return true
        }

        return snapshot.hasIdAny("action_bar_search_edit_text", "search_edit_text")
    }

    // ==========================================
    // YOUTUBE CLASSIFICATION
    // ==========================================

    private fun detectYouTube(
        className: String,
        snapshot: UiTreeSnapshot
    ): Screen {
        // A. Package validation handled in detect()

        // B. Short-Video Viewer Detection (YouTube Shorts)
        val ytEval = evaluateYouTubeShort(className, snapshot)
        val shortsConfidence = ytEval.score

        var finalScreen = Screen.YOUTUBE_HOME

        if (shortsConfidence >= SHORTS_CONFIDENCE_THRESHOLD) {
            finalScreen = Screen.YOUTUBE_SHORT
            logTransitionReason(Screen.YOUTUBE_SHORT, shortsConfidence, ytEval.reasons)
        } else if (shortsConfidence >= SHORTS_POSSIBLE_THRESHOLD) {
            finalScreen = Screen.YOUTUBE_SHORT_POSSIBLE
            logTransitionReason(Screen.YOUTUBE_SHORT_POSSIBLE, shortsConfidence, ytEval.reasons)
        } else {
            // C. Long-Form Video Watch Check (Safe - NEVER block standard YouTube watch)
            if (ytEval.hasLongFormSeekBar ||
                className.contains("WatchActivity", ignoreCase = true) ||
                snapshot.hasIdAny("watch_panel", "movie_player", "time_bar", "player_control_play_pause_replay_button")
            ) {
                finalScreen = Screen.YOUTUBE_WATCH
            } else {
                finalScreen = Screen.YOUTUBE_HOME
            }
        }

        logYouTubeDiagnostic(
            className = className,
            screen = finalScreen,
            score = shortsConfidence,
            shortsActivity = ytEval.hasShortsActivity,
            shortsContainer = ytEval.hasShortsContainer,
            shortsDescriptor = ytEval.hasShortsDescriptor,
            longFormSeekBar = ytEval.hasLongFormSeekBar,
            videoContainer = ytEval.hasVideoContainer,
            like = ytEval.hasLike,
            comment = ytEval.hasComment,
            share = ytEval.hasShare
        )

        return finalScreen
    }

    private data class YouTubeEvaluation(
        val score: Int,
        val hasShortsActivity: Boolean,
        val hasShortsContainer: Boolean,
        val hasShortsDescriptor: Boolean,
        val hasLongFormSeekBar: Boolean,
        val hasVideoContainer: Boolean,
        val hasLike: Boolean,
        val hasComment: Boolean,
        val hasShare: Boolean,
        val reasons: List<String>
    )

    private fun evaluateYouTubeShort(className: String, snapshot: UiTreeSnapshot): YouTubeEvaluation {
        var score = 0
        val reasons = mutableListOf<String>()

        // 1. Explicit Shorts container / layout in YouTube hierarchy
        val hasShortsContainer = snapshot.hasIdAny(
            "reel_scrim",
            "reel_recycler",
            "shorts_container",
            "shorts_player",
            "reel_player",
            "shorts_video_view",
            "shorts_player_fragment",
            "reel_player_fragment",
            "reel_root_view",
            "shorts_metadata",
            "shorts_overlay",
            "reel_player_overlay",
            "shorts_panel"
        )
        if (hasShortsContainer) {
            score += 45
            reasons.add("shorts_container")
        }

        // 2. Shorts Activity / Fragment Class Signal
        val hasShortsActivity = (className.contains("Shorts", ignoreCase = true) ||
                                 className.contains("ReelPlayer", ignoreCase = true) ||
                                 snapshot.hasClassContaining("Shorts") ||
                                 snapshot.hasClassContaining("ReelPlayer")) &&
                                !className.contains("Pivot", ignoreCase = true) &&
                                !className.contains("Tab", ignoreCase = true)

        if (hasShortsActivity) {
            score += 40
            reasons.add("shorts_activity")
        }

        // 3. Shorts Specific Descriptors / Controls Signal
        val hasShortsDescriptor = snapshot.hasDescAny(
            "dislike this short",
            "dislike this video",
            "remix this video",
            "remix with this audio",
            "remix this short",
            "use this sound",
            "create with this sound",
            "comments for this short",
            "sound used in this short",
            "short by",
            "like this short"
        ) || snapshot.hasTextAny("create with this sound", "use this sound")

        if (hasShortsDescriptor) {
            score += 30
            reasons.add("shorts_descriptor")
        }

        // 4. Video Container Signal
        val hasVideoContainer = hasShortsContainer || snapshot.hasVerticalFullScreenVideo
        if (hasVideoContainer) {
            score += 25
            reasons.add("vertical_video")
        }

        // 5. Interaction Controls (Like, Comment, Share)
        val hasLike = snapshot.hasDescAny("like this short", "like this video") || (snapshot.hasDescAny("like") && hasShortsDescriptor)
        val hasComment = snapshot.hasDescAny("comments for this short", "comments for this video") || (snapshot.hasDescAny("comments", "comment") && hasShortsDescriptor)
        val hasShare = snapshot.hasDescAny("share this short", "share this video") || (snapshot.hasDescAny("share") && hasShortsDescriptor)

        if (hasLike) score += 10
        if (hasComment) score += 10
        if (hasShare) score += 10
        if (hasLike || hasComment || hasShare) {
            reasons.add("shorts_control")
        }

        // Hard Exclusion: True Standard YouTube Long-Form Watch Video (has 16:9 movie_player or play_pause_replay AND NOT in shorts container)
        val hasLongFormPlayer = (snapshot.hasIdAny("movie_player", "player_control_play_pause_replay_button", "fullscreen_button") ||
                                className.contains("WatchActivity", ignoreCase = true)) &&
                                !hasShortsContainer && !hasShortsActivity && !hasShortsDescriptor

        if (hasLongFormPlayer) {
            return YouTubeEvaluation(
                score = 0,
                hasShortsActivity = false,
                hasShortsContainer = false,
                hasShortsDescriptor = false,
                hasLongFormSeekBar = true,
                hasVideoContainer = false,
                hasLike = false,
                hasComment = false,
                hasShare = false,
                reasons = listOf("long_form_watch_exclusion")
            )
        }

        // Hard Exclusion: YouTube Home Feed and Browse surfaces
        val hasYouTubeHomeMarkers = snapshot.hasDescAny("subscriptions", "notifications", "search youtube", "cast disconnected") ||
                                    snapshot.hasTextAny("subscriptions", "podcasts", "all", "gaming", "music", "news", "live") ||
                                    snapshot.hasIdAny("feed_filter_bar")

        val hasExplicitShorts = hasShortsContainer || hasShortsActivity || hasShortsDescriptor

        if (hasYouTubeHomeMarkers && !hasExplicitShorts) {
            return YouTubeEvaluation(
                score = 0,
                hasShortsActivity = false,
                hasShortsContainer = false,
                hasShortsDescriptor = false,
                hasLongFormSeekBar = false,
                hasVideoContainer = false,
                hasLike = false,
                hasComment = false,
                hasShare = false,
                reasons = listOf("youtube_home_feed_exclusion")
            )
        }

        val hasStrongStructure = hasShortsContainer || hasShortsActivity || (hasShortsDescriptor && hasVideoContainer)
        val hasSupportingEvidence = hasShortsDescriptor || hasShortsActivity || hasShortsContainer

        val finalScore = if (hasStrongStructure && hasSupportingEvidence) score else 0

        return YouTubeEvaluation(
            score = finalScore,
            hasShortsActivity = hasShortsActivity,
            hasShortsContainer = hasShortsContainer,
            hasShortsDescriptor = hasShortsDescriptor,
            hasLongFormSeekBar = false,
            hasVideoContainer = hasVideoContainer,
            hasLike = hasLike,
            hasComment = hasComment,
            hasShare = hasShare,
            reasons = reasons
        )
    }

    private fun logYouTubeDiagnostic(
        className: String,
        screen: Screen,
        score: Int,
        shortsActivity: Boolean,
        shortsContainer: Boolean,
        shortsDescriptor: Boolean,
        longFormSeekBar: Boolean,
        videoContainer: Boolean,
        like: Boolean,
        comment: Boolean,
        share: Boolean
    ) {
        val sig = "$screen|$score|$shortsActivity|$shortsContainer|$shortsDescriptor|$longFormSeekBar|$videoContainer|$like|$comment|$share"
        val now = System.currentTimeMillis()
        if (sig != lastLoggedYtSig || now - lastLoggedYtTime > 1500L) {
            lastLoggedYtSig = sig
            lastLoggedYtTime = now
            Log.d("INHIBIT_DETECT",
                "pkg=$PKG_YOUTUBE\n" +
                "class=$className\n" +
                "screen=$screen\n" +
                "score=$score\n" +
                "hasShortsActivity=$shortsActivity\n" +
                "hasShortsContainer=$shortsContainer\n" +
                "hasShortsDescriptor=$shortsDescriptor\n" +
                "hasLongFormSeekBar=$longFormSeekBar\n" +
                "hasVideoContainer=$videoContainer\n" +
                "hasLike=$like\n" +
                "hasComment=$comment\n" +
                "hasShare=$share"
            )
        }
    }

    private fun logTransitionReason(screen: Screen, score: Int, reasons: List<String>) {
        Log.d("INHIBIT_DETECT", "$screen score=$score reason=${reasons.joinToString(" + ")}")
    }

    // ==========================================
    // SIGNATURE EXTRACTION
    // ==========================================

    fun extractInstagramSignature(root: AccessibilityNodeInfo?): VideoSignature {
        val snap = latestSnapshot ?: UiTreeSnapshot(root)
        val author = snap.getTextForIds(listOf(
            "clips_author_name",
            "row_feed_photo_profile_name",
            "author_name",
            "user_name",
            "profile_name",
            "clips_creator"
        ))
        val audio = snap.getTextForIds(listOf(
            "clips_music_pill",
            "clips_audio_track_title",
            "music_title",
            "audio_track_title",
            "audio_pill"
        ))
        val caption = snap.getTextForIds(listOf(
            "clips_caption",
            "caption",
            "caption_text",
            "row_feed_comment_textview_layout"
        ))

        return VideoSignature(
            author = author,
            audio = audio,
            captionSnippet = caption.take(40),
            tokens = snap.visibleTokens
        )
    }

    fun extractYouTubeSignature(root: AccessibilityNodeInfo?): VideoSignature {
        val snap = latestSnapshot ?: UiTreeSnapshot(root)
        val title = snap.getTextForIds(listOf(
            "reel_player_title",
            "video_title",
            "title",
            "shorts_title",
            "reel_title_text_view"
        ))
        val channel = snap.getTextForIds(listOf(
            "reel_channel_name",
            "channel_name",
            "channel_title",
            "byline",
            "reel_channel_header"
        ))
        val sound = snap.getTextForIds(listOf(
            "reel_sound_title",
            "sound_title",
            "audio_title",
            "sound_metadata"
        ))

        return VideoSignature(
            author = channel,
            audio = sound,
            captionSnippet = title.take(40),
            tokens = snap.visibleTokens
        )
    }

    // ==========================================
    // UTILITY METHODS
    // ==========================================

    fun findHomeTabNode(root: AccessibilityNodeInfo?): AccessibilityNodeInfo? {
        if (root == null) return null
        if (latestSnapshot?.homeTabNode != null) {
            return latestSnapshot?.homeTabNode
        }

        // Priority 1: Match node with contentDescription or text "Home" or "Feed"
        val byDesc = findNodeWithDescExact(root, "Home") ?:
                     findNodeWithDescExact(root, "Feed") ?:
                     findNodeWithDescExact(root, "home") ?:
                     findNodeWithDescExact(root, "feed")
        if (byDesc != null) return byDesc

        // Priority 2: Direct view ID match
        val byId = findNodeWithViewId(root, "feed_tab") ?:
                   findNodeWithViewId(root, "tab_icon_home") ?:
                   findNodeWithViewId(root, "home_tab")
        if (byId != null) return byId

        // Priority 3: Bottom tab bar container -> 1st child (Tab 0) is always Home tab
        val tabBar = findNodeWithViewId(root, "tab_bar") ?:
                     findNodeWithViewId(root, "navigation_bar") ?:
                     findNodeWithViewId(root, "bottom_navigation") ?:
                     findNodeWithViewId(root, "bottom_bar") ?:
                     findNodeWithViewId(root, "pivot_bar")
        if (tabBar != null && tabBar.childCount > 0) {
            val firstChild = tabBar.getChild(0)
            if (firstChild != null) return firstChild
        }

        return null
    }

    fun findInAppCloseOrBackNode(root: AccessibilityNodeInfo?): AccessibilityNodeInfo? {
        if (root == null) return null
        val byDesc = findNodeWithDescExact(root, "Back") ?:
                     findNodeWithDescExact(root, "Close") ?:
                     findNodeWithDescExact(root, "Navigate up") ?:
                     findNodeWithDescExact(root, "back") ?:
                     findNodeWithDescExact(root, "close")
        if (byDesc != null) return byDesc

        return findNodeWithViewId(root, "action_bar_button_back") ?:
               findNodeWithViewId(root, "action_bar_button_close") ?:
               findNodeWithViewId(root, "back_button") ?:
               findNodeWithViewId(root, "btn_back") ?:
               findNodeWithViewId(root, "close_button") ?:
               findNodeWithViewId(root, "btn_close")
    }

    fun findNodeWithDescExact(node: AccessibilityNodeInfo?, query: String): AccessibilityNodeInfo? {
        if (node == null) return null
        val desc = node.contentDescription?.toString()?.trim().orEmpty()
        val text = node.text?.toString()?.trim().orEmpty()
        if (desc.equals(query, ignoreCase = true) || text.equals(query, ignoreCase = true)) {
            return node
        }
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val found = findNodeWithDescExact(child, query)
            if (found != null) return found
        }
        return null
    }

    fun performDeepClick(node: AccessibilityNodeInfo?): Boolean {
        if (node == null) return false
        var current: AccessibilityNodeInfo? = node
        while (current != null) {
            if (current.isClickable && current.performAction(AccessibilityNodeInfo.ACTION_CLICK)) {
                return true
            }
            current = current.parent
        }
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (child != null && child.isClickable && child.performAction(AccessibilityNodeInfo.ACTION_CLICK)) {
                return true
            }
        }
        try {
            return node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
        } catch (_: Exception) {
            return false
        }
    }

    fun findNodeWithViewId(node: AccessibilityNodeInfo?, targetIdSnippet: String): AccessibilityNodeInfo? {
        if (node == null) return null

        val viewId = node.viewIdResourceName.orEmpty()
        if (viewId.contains(targetIdSnippet, ignoreCase = true)) {
            return node
        }

        val count = node.childCount
        for (i in 0 until count) {
            val child = node.getChild(i) ?: continue
            val found = findNodeWithViewId(child, targetIdSnippet)
            if (found != null) return found
        }
        return null
    }

    companion object {
        const val PKG_INSTAGRAM = "com.instagram.android"
        const val PKG_YOUTUBE = "com.google.android.youtube"

        const val REEL_CONFIDENCE_THRESHOLD = 45
        const val REEL_POSSIBLE_THRESHOLD = 25
        const val SHORTS_CONFIDENCE_THRESHOLD = 45
        const val SHORTS_POSSIBLE_THRESHOLD = 25
    }
}
