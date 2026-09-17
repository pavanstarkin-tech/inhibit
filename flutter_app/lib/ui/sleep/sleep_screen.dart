import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/app_state.dart';
import '../components/neo_card.dart';
import '../components/neo_switch.dart';
import '../theme/app_theme.dart';

class SleepScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback? onBack;

  const SleepScreen({super.key, required this.appState, this.onBack});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final currentMin = isStart
        ? widget.appState.sleepStartMinutes
        : widget.appState.sleepEndMinutes;

    final initialTime = TimeOfDay(
      hour: currentMin ~/ 60,
      minute: currentMin % 60,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              surface: AppTheme.bgMain,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final newMin = picked.hour * 60 + picked.minute;
      widget.appState.setSleepSchedule(
        enabled: widget.appState.sleepEnabled,
        startMinutes: isStart ? newMin : widget.appState.sleepStartMinutes,
        endMinutes: isStart ? widget.appState.sleepEndMinutes : newMin,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = widget.appState.sleepSchedule;
    final now = DateTime.now();
    final isActive = schedule.isActive(now);
    final timeUntil = schedule.timeUntilNextChange(now);

    final hoursLeft = timeUntil.inHours;
    final minsLeft = timeUntil.inMinutes.remainder(60);

    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Back Arrow
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderBlack, width: 2),
                        boxShadow: AppTheme.hardShadow(offset: const Offset(2, 2)),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Moon Icon & Screen Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.borderBlack, width: 2),
                      ),
                      child: const Icon(Icons.nightlight_round, size: 28, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Sleep Schedule',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Set quiet hours to protect your focus\nand sleep.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF555555)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // SLEEP MODE Pink Card
              NeoCard(
                backgroundColor: const Color(0xFFFFD1DC),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shadowOffset: const Offset(4, 4),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.accentPurple,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderBlack, width: 2),
                      ),
                      child: const Icon(Icons.nightlight_round, size: 20, color: Colors.black),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SLEEP MODE',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black),
                          ),
                          Text(
                            'Block social media during your scheduled hours.',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                          ),
                        ],
                      ),
                    ),
                    NeoSwitch(
                      value: widget.appState.sleepEnabled,
                      activeColor: AppTheme.accentGreen,
                      onChanged: (val) => widget.appState.setSleepEnabled(val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Bedtime Card
              _buildTimeSelectorCard(
                icon: Icons.nightlight_outlined,
                label: 'Bedtime',
                time: schedule.formattedStart,
                onTap: () => _pickTime(isStart: true),
              ),
              const SizedBox(height: 10),

              // Wake up Card
              _buildTimeSelectorCard(
                icon: Icons.wb_sunny_outlined,
                label: 'Wake up',
                time: schedule.formattedEnd,
                onTap: () => _pickTime(isStart: false),
              ),
              const SizedBox(height: 14),

              // Next Sleep Session (Green Card)
              NeoCard(
                backgroundColor: const Color(0xFF7ED957),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                shadowOffset: const Offset(4, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isActive ? 'Active sleep lockdown' : 'Next sleep session',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isActive
                              ? 'Ends in ${hoursLeft}h ${minsLeft}m'
                              : 'Starts in ${hoursLeft}h ${minsLeft}m',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    // Cute sleeping moon graphic
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF70D6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderBlack, width: 2),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.nightlight_round, size: 24, color: Colors.black),
                          SizedBox(width: 4),
                          Column(
                            children: [
                              Text('z', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                              Text('Z', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Bottom Card
              const NeoCard(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shadowOffset: Offset(3, 3),
                child: Center(
                  child: Text(
                    'A better tomorrow\nstarts with better nights.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSelectorCard({
    required IconData icon,
    required String label,
    required String time,
    required VoidCallback onTap,
  }) {
    return NeoCard(
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shadowOffset: const Offset(3, 3),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.black),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF666666)),
              ),
              Text(
                time,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF888888)),
        ],
      ),
    );
  }
}
