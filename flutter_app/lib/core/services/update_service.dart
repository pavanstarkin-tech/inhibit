import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/components/neo_button.dart';

class AppUpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String releaseName;
  final String releaseNotes;
  final String downloadUrl;
  final String releaseUrl;
  final String? publishedAt;

  const AppUpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseName,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.releaseUrl,
    this.publishedAt,
  });
}

class UpdateService {
  static const String _primaryRepo = 'pavanstarkin-tech/inhibit-app';
  static const String _fallbackRepo = 'pavanstarkin-tech/inhibit';
  static const String currentAppVersion = '1.0.0';

  /// Checks GitHub Releases for a newer version of the application
  static Future<AppUpdateInfo> checkForUpdate({String currentVersion = currentAppVersion}) async {
    final repos = [_primaryRepo, _fallbackRepo];

    for (final repo in repos) {
      try {
        final info = await _fetchLatestRelease(repo, currentVersion);
        if (info != null) {
          return info;
        }
      } catch (e) {
        if (kDebugMode) print('Error checking updates on $repo: $e');
      }
    }

    return AppUpdateInfo(
      hasUpdate: false,
      currentVersion: currentVersion,
      latestVersion: currentVersion,
      releaseName: 'Up to date',
      releaseNotes: 'You are running the latest version of Inhibit.',
      downloadUrl: '',
      releaseUrl: 'https://github.com/$_primaryRepo/releases',
    );
  }

  static Future<AppUpdateInfo?> _fetchLatestRelease(String repo, String currentVersion) async {
    final uri = Uri.parse('https://api.github.com/repos/$repo/releases/latest');
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);

    try {
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'Inhibit-App');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody) as Map<String, dynamic>;

        final tagName = (data['tag_name'] as String? ?? '').replaceFirst('v', '').trim();
        final releaseName = data['name'] as String? ?? 'Release v$tagName';
        final releaseNotes = data['body'] as String? ?? 'New improvements and bug fixes.';
        final htmlUrl = data['html_url'] as String? ?? 'https://github.com/$repo/releases';
        final publishedAt = data['published_at'] as String?;

        String downloadUrl = '';
        final assets = data['assets'] as List<dynamic>?;
        if (assets != null && assets.isNotEmpty) {
          final apkAsset = assets.firstWhere(
            (a) => (a['name'] as String? ?? '').endsWith('.apk'),
            orElse: () => assets.first,
          );
          downloadUrl = apkAsset['browser_download_url'] as String? ?? '';
        }

        if (downloadUrl.isEmpty) {
          downloadUrl = 'https://github.com/$repo/releases/download/v$tagName/inhibit-v$tagName.apk';
        }

        final bool isNewer = _isVersionNewer(currentVersion, tagName);

        return AppUpdateInfo(
          hasUpdate: isNewer,
          currentVersion: currentVersion,
          latestVersion: tagName.isEmpty ? currentVersion : tagName,
          releaseName: releaseName,
          releaseNotes: releaseNotes,
          downloadUrl: downloadUrl,
          releaseUrl: htmlUrl,
          publishedAt: publishedAt,
        );
      }
    } finally {
      client.close();
    }
    return null;
  }

  /// Compares semantic versions: returns true if latest is strictly newer than current
  static bool _isVersionNewer(String current, String latest) {
    if (latest.isEmpty) return false;
    try {
      final currentParts = current.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final latestParts = latest.split('.').map((p) => int.tryParse(p) ?? 0).toList();

      while (currentParts.length < 3) {
        currentParts.add(0);
      }
      while (latestParts.length < 3) {
        latestParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (_) {
      return latest != current;
    }
  }

  /// Shows an interactive NeoBrutalist update dialog with release notes & download button
  static void showUpdateDialog({
    required BuildContext context,
    required AppUpdateInfo update,
    required VoidCallback onDownload,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgMain,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 3),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderBlack, width: 2),
              ),
              child: const Text('UPDATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 8),
            Text('v${update.latestVersion}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                update.releaseName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderBlack, width: 1.5),
                ),
                child: Text(
                  update.releaseNotes.isNotEmpty ? update.releaseNotes : 'Performance improvements and bug fixes.',
                  style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF333333)),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Current installed: v${update.currentVersion}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF777777)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('LATER', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
          ),
          NeoButton(
            text: 'DOWNLOAD APK →',
            backgroundColor: AppTheme.accentGreen,
            textColor: Colors.black,
            height: 40,
            fontSize: 12,
            onPressed: () {
              Navigator.of(ctx).pop();
              onDownload();
            },
          ),
        ],
      ),
    );
  }
}
