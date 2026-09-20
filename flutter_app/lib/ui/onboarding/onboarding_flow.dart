import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/models/life_in_weeks.dart';
import '../../core/services/app_state.dart';
import '../components/neo_button.dart';
import '../components/neo_card.dart';
import '../components/neo_switch.dart';
import '../theme/app_theme.dart';

class OnboardingFlow extends StatefulWidget {
  final AppState appState;
  final VoidCallback onComplete;

  const OnboardingFlow({
    super.key,
    required this.appState,
    required this.onComplete,
  });

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> with WidgetsBindingObserver {
  int _currentStep = 0; // 0: Welcome, 1: Usage, 2: Life in Weeks, 3: Defaults, 4: Permission
  double _scrollHours = 3.5;
  final int _age = 22;

  // Defaults toggles
  bool _blockShorts = true;
  bool _hideFeeds = true;
  bool _enableSleep = true;
  bool _limitPosts = true;

  // Accessibility Permission Slider
  final PageController _permissionPageController = PageController();
  int _permissionImageIndex = 0;
  Timer? _permissionCarouselTimer;

  final List<Map<String, String>> _permissionSteps = const [
    {
      'image': 'assets/accesability/1.jpeg',
      'step': 'STEP 1 OF 4',
      'title': 'Open Accessibility Settings',
      'desc': 'Tap button in bottom right to open Android Accessibility settings.',
    },
    {
      'image': 'assets/accesability/2.jpeg',
      'step': 'STEP 2 OF 4',
      'title': 'Select "Inhibit"',
      'desc': 'Find and tap "Inhibit" under Downloaded / Installed apps.',
    },
    {
      'image': 'assets/accesability/4.jpeg',
      'step': 'STEP 3 OF 4',
      'title': 'Turn Inhibit ON',
      'desc': 'Toggle the switch to enable 24/7 Shield protection.',
    },
    {
      'image': 'assets/accesability/3.jpeg',
      'step': 'STEP 4 OF 4',
      'title': 'Tap "Allow" to Activate',
      'desc': 'Confirm permission to start auto-shielding your doomscrolling!',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.appState.checkAccessibilityPermission();
    _startPermissionCarouselTimer();
  }

  void _startPermissionCarouselTimer() {
    _permissionCarouselTimer?.cancel();
    _permissionCarouselTimer = Timer.periodic(const Duration(milliseconds: 3200), (timer) {
      if (!mounted) return;
      if (_currentStep == 4 && _permissionPageController.hasClients) {
        final next = (_permissionImageIndex + 1) % _permissionSteps.length;
        _permissionPageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _permissionCarouselTimer?.cancel();
    _permissionPageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.appState.checkAccessibilityPermission();
    }
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      // Step 4: Device Permission Step
      if (!widget.appState.isAccessibilityGranted) {
        widget.appState.openAccessibilitySettings();
      } else {
        widget.appState.completeOnboarding(
          age: _age,
          scrollHours: _scrollHours,
        );
        widget.appState.setSleepEnabled(_enableSleep);
        widget.onComplete();
      }
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              if (_currentStep > 0) _buildTopBar(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildStepContent(),
                ),
              ),
              const SizedBox(height: 12),
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _prevStep,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderBlack, width: 2.5),
                boxShadow: AppTheme.hardShadow(offset: const Offset(2, 2)),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
            ),
          ),
          Text(
            '${_currentStep + 1}/5',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildScreen1Welcome();
      case 1:
        return _buildScreen2Usage();
      case 2:
        return _buildScreen3LifeInWeeks();
      case 3:
        return _buildScreen4Defaults();
      case 4:
        return _buildScreen5Permission();
      default:
        return const SizedBox();
    }
  }

  // ==========================================
  // SCREEN 1: ONBOARDING 1 - WELCOME
  // ==========================================
  Widget _buildScreen1Welcome() {
    return Column(
      key: const ValueKey('step_1_welcome'),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(height: 12),

        // Logo Image
        Image.asset(
          'assets/images/logo.png',
          height: 52,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'Inhibit',
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1),
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Same social media.\nWithout the trap.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333333),
            height: 1.25,
          ),
        ),

        const SizedBox(height: 16),

        // Center Hero Welcome Art (clean image without border/background)
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Image.asset(
                'assets/images/welcome.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text(
                    'SOCIAL MEDIA ON YOUR TERMS',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  // ==========================================
  // SCREEN 2: ONBOARDING 2 - USAGE
  // ==========================================
  Widget _buildScreen2Usage() {
    return SingleChildScrollView(
      key: const ValueKey('step_2_usage'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HOW MUCH\nDO YOU SCROLL\nDAILY?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1.1,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Be honest. This helps show your real impact.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF555555)),
          ),
          const SizedBox(height: 20),

          // Pink Slider Card
          NeoCard(
            backgroundColor: const Color(0xFFFFD1DC),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            shadowOffset: const Offset(5, 5),
            child: Column(
              children: [
                // Display Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderBlack, width: 2.5),
                    boxShadow: AppTheme.hardShadow(offset: const Offset(3, 3)),
                  ),
                  child: Text(
                    '${_scrollHours.toStringAsFixed(1)} hours',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Slider Track
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.black,
                    inactiveTrackColor: Colors.black.withAlpha((255 * 0.2).toInt()),
                    trackHeight: 6,
                    thumbColor: AppTheme.accentYellow,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 13,
                      elevation: 4,
                      pressedElevation: 6,
                    ),
                    overlayColor: AppTheme.accentYellow.withAlpha((255 * 0.3).toInt()),
                  ),
                  child: Slider(
                    value: _scrollHours,
                    min: 0.0,
                    max: 8.0,
                    divisions: 16,
                    onChanged: (val) => setState(() => _scrollHours = val),
                  ),
                ),

                // Tick labels
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0h', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                      Text('2h', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                      Text('4h', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                      Text('6h', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                      Text('8h', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Floating Badge: Small change. Big life.
          Align(
            alignment: Alignment.centerRight,
            child: Transform.rotate(
              angle: -0.05,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderBlack, width: 2.5),
                  boxShadow: AppTheme.hardShadow(offset: const Offset(3, 3)),
                ),
                child: const Text(
                  'Small\nchange.\nBig life.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    height: 1.15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 3: ONBOARDING 3 - LIFE IN WEEKS
  // ==========================================
  Widget _buildScreen3LifeInWeeks() {
    final life = LifeInWeeks(
      age: _age,
      scrollHoursPerDay: _scrollHours,
    );

    return SingleChildScrollView(
      key: const ValueKey('step_3_life_weeks'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR LIFE\nIN WEEKS',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1.1,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Based on your input, you could spend ~4,700 weeks on this planet.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF555555)),
          ),
          const SizedBox(height: 14),

          // Life Grid Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderBlack, width: 2.5),
              boxShadow: AppTheme.hardShadow(offset: const Offset(4, 4)),
            ),
            child: Column(
              children: [
                // Matrix of boxes
                SizedBox(
                  height: 150,
                  child: _buildLifeWeeksDotGrid(life),
                ),
                const SizedBox(height: 10),

                // Legend
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B),
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: AppTheme.borderBlack, width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Potentially lost to scrolling', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: AppTheme.borderBlack, width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Your remaining weeks', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Two side-by-side callout cards with equal height
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 6,
                  child: NeoCard(
                    backgroundColor: AppTheme.accentYellow,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shadowOffset: const Offset(3, 3),
                    child: Center(
                      child: Text(
                        "That's ${(life.yearsLostToScrolling * 52).toInt()} weeks\n(~${life.yearsLostToScrolling.toStringAsFixed(1)} years) lost\nto doomscrolling.",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  flex: 4,
                  child: NeoCard(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    shadowOffset: Offset(3, 3),
                    child: Center(
                      child: Text(
                        "Let's\ntake some\nof those back.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifeWeeksDotGrid(LifeInWeeks life) {
    const totalCols = 36;
    const totalRows = 14;
    const totalCells = totalCols * totalRows;
    final spentRatio = (life.scrollPercent / 100.0).clamp(0.0, 1.0);
    final lostCount = (totalCells * spentRatio).toInt();

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: totalCols,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final isLost = index < lostCount;
        return Container(
          decoration: BoxDecoration(
            color: isLost ? const Color(0xFFFF6B6B) : Colors.white,
            borderRadius: BorderRadius.circular(1),
            border: Border.all(
              color: isLost ? const Color(0xFFCC0000) : const Color(0xFF777777),
              width: 0.8,
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // SCREEN 4: ONBOARDING 4 - SET DEFAULTS
  // ==========================================
  Widget _buildScreen4Defaults() {
    return SingleChildScrollView(
      key: const ValueKey('step_4_defaults'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SET YOUR DEFAULTS',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "We'll set up a calmer experience.\nYou can always change these later.",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF555555)),
          ),
          const SizedBox(height: 12),

          // 4 Toggle cards
          _buildDefaultToggleTile(
            title: 'Block short-form videos',
            subtitle: 'Instagram Reels & YouTube Shorts',
            icon: Icons.play_arrow_rounded,
            iconBg: AppTheme.accentBlue,
            value: _blockShorts,
            onChanged: (val) => setState(() => _blockShorts = val),
          ),
          const SizedBox(height: 8),

          _buildDefaultToggleTile(
            title: 'Hide algorithmic feeds',
            subtitle: 'Instagram Explore & Suggested Reels',
            icon: Icons.explore_rounded,
            iconBg: const Color(0xFFFF6B6B),
            value: _hideFeeds,
            onChanged: (val) => setState(() => _hideFeeds = val),
          ),
          const SizedBox(height: 8),

          _buildDefaultToggleTile(
            title: 'Enable sleep lockdown',
            subtitle: 'Protect your late nights',
            icon: Icons.nightlight_round,
            iconBg: AppTheme.accentGreen,
            value: _enableSleep,
            onChanged: (val) => setState(() => _enableSleep = val),
          ),
          const SizedBox(height: 8),

          _buildDefaultToggleTile(
            title: 'Limit to 4 post sessions',
            subtitle: 'Intentional posting only',
            icon: Icons.edit_note_rounded,
            iconBg: AppTheme.accentPurple,
            value: _limitPosts,
            onChanged: (val) => setState(() => _limitPosts = val),
          ),
          const SizedBox(height: 12),

          // Info Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderBlack, width: 2),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.black, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No tracking. No analytics.\nEverything stays on your device.',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultToggleTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return NeoCard(
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shadowOffset: const Offset(3, 3),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderBlack, width: 2),
            ),
            child: Icon(icon, size: 18, color: Colors.black),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
          NeoSwitch(
            value: value,
            activeColor: AppTheme.accentGreen,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 5: ONBOARDING 5 - PERMISSION
  // ==========================================
  Widget _buildScreen5Permission() {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final isGranted = widget.appState.isAccessibilityGranted;

        return SingleChildScrollView(
          key: const ValueKey('step_5_permission'),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // HERO SECTION: ACCESSIBILITY SHIELD CARD (COMPACT)
              // ==========================================
              NeoCard(
                backgroundColor: isGranted ? const Color(0xFFD1FAE5) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shadowOffset: const Offset(3, 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGranted ? '24/7 Shield Protection Active' : 'Enable Device App Shielding',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isGranted
                          ? 'Doomscrolling detection and swipe deflection active for Instagram & YouTube.'
                          : 'Auto-stops infinite scroll loops in Instagram & YouTube without accessing personal data.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isGranted ? const Color(0xFF15803D) : const Color(0xFF555555),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: AppTheme.borderBlack, width: 1.2),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 12, color: Colors.black),
                          SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '100% On-Device • Zero logs • Never reads messages or data',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ==========================================
              // STEP-BY-STEP 4-IMAGE AUTO-SLIDER SECTION
              // ==========================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'HOW TO ENABLE STEPS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'Step ${_permissionImageIndex + 1} of ${_permissionSteps.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Auto-slider Container with enlarged height to fit screenshots fully
              SizedBox(
                height: 440,
                child: PageView.builder(
                  controller: _permissionPageController,
                  itemCount: _permissionSteps.length,
                  onPageChanged: (idx) {
                    setState(() => _permissionImageIndex = idx);
                  },
                  itemBuilder: (context, index) {
                    final stepData = _permissionSteps[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: NeoCard(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                        shadowOffset: const Offset(3, 3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header of each slider card
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentYellow,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppTheme.borderBlack, width: 1.5),
                                  ),
                                  child: Text(
                                    stepData['step']!,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    stepData['title']!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stepData['desc']!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF555555),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),

                            // Image Preview Viewport
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.borderBlack, width: 2),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.asset(
                                  stepData['image']!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.touch_app_rounded, size: 36, color: Colors.black54),
                                        const SizedBox(height: 6),
                                        Text(
                                          stepData['title']!,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Carousel Dots Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_permissionSteps.length, (i) {
                  final isCurrent = i == _permissionImageIndex;
                  return GestureDetector(
                    onTap: () {
                      _permissionPageController.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isCurrent ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isCurrent ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // BOTTOM BUTTON (RIGHT-ALIGNED ON PERMISSION)
  // ==========================================
  Widget _buildBottomButton() {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        if (_currentStep == 4) {
          // Accessibility Permission step: Place the permission button in bottom right
          final isGranted = widget.appState.isAccessibilityGranted;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left status pill
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isGranted ? AppTheme.accentGreen : AppTheme.accentYellow,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.borderBlack, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isGranted ? 'Permission Active' : 'Setup Required',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),

              // Right Button: Accessibility Permission Action Button
              NeoButton(
                text: isGranted ? 'ACCESS APP →' : 'ENABLE PERMISSION →',
                backgroundColor: isGranted ? AppTheme.accentGreen : AppTheme.accentYellow,
                textColor: Colors.black,
                isFullWidth: false,
                height: 48,
                fontSize: 13,
                onPressed: () {
                  if (!isGranted) {
                    widget.appState.openAccessibilitySettings();
                  } else {
                    widget.appState.completeOnboarding(
                      age: _age,
                      scrollHours: _scrollHours,
                    );
                    widget.appState.setSleepEnabled(_enableSleep);
                    widget.onComplete();
                  }
                },
              ),
            ],
          );
        }

        // Steps 0-3: Full-width continuation buttons
        String buttonText;
        Color buttonBg = AppTheme.accentYellow;
        VoidCallback onPressed = _nextStep;

        if (_currentStep == 0) {
          buttonText = "LET'S BEGIN →";
        } else if (_currentStep < 3) {
          buttonText = "CONTINUE →";
        } else {
          buttonText = "SET UP PERMISSION →";
        }

        return NeoButton(
          text: buttonText,
          backgroundColor: buttonBg,
          textColor: Colors.black,
          isFullWidth: true,
          height: 52,
          fontSize: 14,
          onPressed: onPressed,
        );
      },
    );
  }
}
