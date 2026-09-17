import 'package:flutter/material.dart';

class ServiceInfo {
  final String id;
  final String name;
  final String homeUrl;
  final Color tint;
  final Color tintDark;
  final IconData iconData;
  final bool beta;
  final bool isComingSoon;
  final List<String> adSurfaces;
  final String adCopyOn;
  final String adCopyOff;

  const ServiceInfo({
    required this.id,
    required this.name,
    required this.homeUrl,
    required this.tint,
    required this.tintDark,
    required this.iconData,
    this.beta = false,
    this.isComingSoon = false,
    this.adSurfaces = const [],
    this.adCopyOn = '',
    this.adCopyOff = '',
  });

  bool get hasAdBlocking => adSurfaces.isNotEmpty;

  LinearGradient get gradient => LinearGradient(
        colors: [tint, tintDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static const List<ServiceInfo> activeServices = [
    ServiceInfo(
      id: 'instagram',
      name: 'Instagram',
      homeUrl: 'https://www.instagram.com/',
      tint: Color(0xFFE1306C),
      tintDark: Color(0xFFF77737),
      iconData: Icons.camera_alt_rounded,
      isComingSoon: false,
    ),
    ServiceInfo(
      id: 'youtube',
      name: 'YouTube',
      homeUrl: 'https://m.youtube.com/',
      tint: Color(0xFFE02F2F),
      tintDark: Color(0xFF9E1B1B),
      iconData: Icons.play_arrow_rounded,
      isComingSoon: false,
    ),
  ];

  static const List<ServiceInfo> comingSoonServices = [
    ServiceInfo(
      id: 'tiktok',
      name: 'TikTok',
      homeUrl: 'https://www.tiktok.com/',
      tint: Color(0xFF1E293B),
      tintDark: Color(0xFF0F172A),
      iconData: Icons.music_note_rounded,
      isComingSoon: true,
    ),
    ServiceInfo(
      id: 'facebook',
      name: 'Facebook',
      homeUrl: 'https://m.facebook.com/',
      tint: Color(0xFF1877F2),
      tintDark: Color(0xFF0C5EC7),
      iconData: Icons.facebook_rounded,
      isComingSoon: true,
    ),
    ServiceInfo(
      id: 'twitter',
      name: 'X (Twitter)',
      homeUrl: 'https://x.com/',
      tint: Color(0xFF14171A),
      tintDark: Color(0xFF657786),
      iconData: Icons.tag_rounded,
      isComingSoon: true,
    ),
    ServiceInfo(
      id: 'reddit',
      name: 'Reddit',
      homeUrl: 'https://www.reddit.com/',
      tint: Color(0xFFFF4500),
      tintDark: Color(0xFFCC3700),
      iconData: Icons.forum_rounded,
      isComingSoon: true,
    ),
    ServiceInfo(
      id: 'snapchat',
      name: 'Snapchat',
      homeUrl: 'https://www.snapchat.com/',
      tint: Color(0xFFFFCC00),
      tintDark: Color(0xFFD4AA00),
      iconData: Icons.chat_bubble_rounded,
      isComingSoon: true,
    ),
    ServiceInfo(
      id: 'linkedin',
      name: 'LinkedIn',
      homeUrl: 'https://www.linkedin.com/',
      tint: Color(0xFF0A66C2),
      tintDark: Color(0xFF084E96),
      iconData: Icons.work_rounded,
      isComingSoon: true,
    ),
  ];

  static List<ServiceInfo> get allServices => [...activeServices, ...comingSoonServices];

  static ServiceInfo? findById(String id) {
    try {
      return allServices.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}

