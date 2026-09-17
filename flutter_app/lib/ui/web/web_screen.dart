import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/models/service_model.dart';
import '../../core/services/app_state.dart';
import '../home/service_settings_sheet.dart';
import '../theme/app_theme.dart';

class WebScreen extends StatefulWidget {
  final AppState appState;
  final String initialServiceId;
  final VoidCallback? onBackToHome;

  const WebScreen({
    super.key,
    required this.appState,
    this.initialServiceId = 'instagram',
    this.onBackToHome,
  });

  @override
  State<WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen> {
  late WebViewController _controller;
  late String _currentServiceId;
  bool _isLoading = true;
  int _blockedCountThisPage = 4;
  bool _isAuthSurface = false;
  String _currentUrl = '';
  bool _showDemoOverlay = false;

  @override
  void initState() {
    super.initState();
    _currentServiceId = widget.initialServiceId;
    _setupWebView();
  }

  void _setupWebView() {
    final service = ServiceInfo.findById(_currentServiceId) ?? ServiceInfo.allServices[0];
    _currentUrl = service.homeUrl;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'NoScrollAndroid',
        onMessageReceived: (JavaScriptMessage message) {
          _handleEngineMessage(message.message);
        },
      )
      ..addJavaScriptChannel(
        'noscroll',
        onMessageReceived: (JavaScriptMessage message) {
          _handleEngineMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
            final bootstrap = widget.appState.generateBootstrapJs(_currentServiceId);
            _controller.runJavaScript(bootstrap);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
            final bootstrap = widget.appState.generateBootstrapJs(_currentServiceId);
            _controller.runJavaScript(bootstrap);
          },
          onWebResourceError: (WebResourceError error) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(_currentUrl));
  }

  void _handleEngineMessage(String rawJson) {
    widget.appState.handleBridgeMessage(rawJson, serviceId: _currentServiceId);
    try {
      if (rawJson.contains('"type":"blocked"')) {
        setState(() => _blockedCountThisPage++);
      } else if (rawJson.contains('"type":"auth-surface"')) {
        setState(() => _isAuthSurface = true);
      }
    } catch (_) {}
  }

  void _switchService(String newServiceId) {
    if (_currentServiceId == newServiceId) return;
    setState(() {
      _currentServiceId = newServiceId;
      _blockedCountThisPage = 4;
      _isAuthSurface = false;
    });
    final service = ServiceInfo.findById(newServiceId) ?? ServiceInfo.allServices[0];
    _currentUrl = service.homeUrl;
    _controller.loadRequest(Uri.parse(service.homeUrl));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          _controller.goBack();
        } else if (widget.onBackToHome != null) {
          widget.onBackToHome!();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgMain,
        body: SafeArea(
          child: Column(
            children: [
              // Top Service Selector Row (Instagram, YouTube, X, TikTok, +)
              _buildTopServicePills(),

              // Auth-Guard Active Banner
              _buildAuthGuardBanner(),

              // URL Address Bar
              _buildUrlAddressBar(),

              if (_isLoading)
                const LinearProgressIndicator(
                  backgroundColor: AppTheme.bgMain,
                  color: Colors.black,
                  minHeight: 2,
                ),

              // Web / Content Body
              Expanded(
                child: Stack(
                  children: [
                    WebViewWidget(controller: _controller),

                    // Demo / Preview overlay option (matches Screen 6 of ui.png)
                    if (_showDemoOverlay) _buildSimulatedCleanFeed(),

                    // Floating Pink "4 BLOCKED" Badge
                    Positioned(
                      top: 10,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD1DC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderBlack, width: 2),
                          boxShadow: AppTheme.hardShadow(offset: const Offset(2, 2)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_blockedCountThisPage',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                height: 1.0,
                              ),
                            ),
                            const Text(
                              'BLOCKED',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_isAuthSurface)
                      Positioned(
                        top: 12,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.accentYellow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderBlack, width: 2.5),
                            boxShadow: AppTheme.hardShadow(offset: const Offset(3, 3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.shield, color: Colors.black, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'AUTH GUARD ACTIVE: Engine paused on login page.',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Bottom Browser Toolbar
              _buildBottomBrowserBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopServicePills() {
    final services = [
      {'id': 'instagram', 'name': 'Instagram', 'icon': Icons.camera_alt_rounded, 'color': const Color(0xFFFFD1DC)},
      {'id': 'youtube', 'name': 'YouTube', 'icon': Icons.play_arrow_rounded, 'color': const Color(0xFFFF6B6B)},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppTheme.bgMain,
      child: Row(
        children: [
          ...services.map((s) {
            final isSelected = s['id'] == _currentServiceId;
            final iconBg = s['color'] as Color;
            final isDark = iconBg == Colors.black;

            return GestureDetector(
              onTap: () => _switchService(s['id'] as String),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.black : const Color(0xFFCCCCCC),
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: isSelected ? AppTheme.hardShadow(offset: const Offset(2, 2)) : null,
                ),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    s['icon'] as IconData,
                    size: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          // Add/More Services Button (+)
          GestureDetector(
            onTap: () => _openServiceSettings(context, _currentServiceId),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderBlack, width: 2),
                boxShadow: AppTheme.hardShadow(offset: const Offset(2, 2)),
              ),
              child: const Icon(Icons.add, size: 18, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthGuardBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderBlack, width: 2),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, color: Colors.black, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auth-Guard Active',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black),
                ),
                Text(
                  'We never touch your login or 2FA pages.',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF444444)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlAddressBar() {
    final displayUrl = _currentUrl.isNotEmpty ? _currentUrl : 'https://www.instagram.com';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderBlack, width: 2),
        boxShadow: AppTheme.hardShadow(offset: const Offset(2, 2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, color: Colors.black, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              displayUrl,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showDemoOverlay = !_showDemoOverlay),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: _showDemoOverlay ? AppTheme.accentGreen : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.borderBlack, width: 1),
              ),
              child: Text(
                _showDemoOverlay ? 'DEMO ON' : 'PREVIEW',
                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatedCleanFeed() {
    return Container(
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Instagram Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text(
              'Instagram',
              style: TextStyle(fontFamily: 'serif', fontSize: 24, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
            ),
          ),

          // Stories Row
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildStoryAvatar('Your story', AppTheme.accentYellow, Icons.add),
                _buildStoryAvatar('friend', AppTheme.accentPink, Icons.person),
                _buildStoryAvatar('travel', AppTheme.accentBlue, Icons.flight),
                _buildStoryAvatar('design', AppTheme.accentGreen, Icons.brush),
                _buildStoryAvatar('food', AppTheme.accentPurple, Icons.restaurant),
              ],
            ),
          ),
          const Divider(height: 1),

          // Post Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.accentGreen,
                  child: Icon(Icons.terrain, size: 16, color: Colors.black),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('nature.grid', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                      Text('Mountains are therapy 🏔️', style: TextStyle(fontSize: 10, color: Color(0xFF666666))),
                    ],
                  ),
                ),
                Icon(Icons.more_horiz, size: 20),
              ],
            ),
          ),

          // Post Media Container
          Container(
            height: 240,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF87CEEB),
            ),
            child: const Center(
              child: Icon(Icons.landscape, size: 64, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildStoryAvatar(String label, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderBlack, width: 2),
            ),
            child: Icon(icon, size: 22, color: Colors.black),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildBottomBrowserBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.bgMain,
        border: Border(top: BorderSide(color: AppTheme.borderBlack, width: 2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () async {
              if (await _controller.canGoBack()) {
                _controller.goBack();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.black),
            onPressed: () async {
              if (await _controller.canGoForward()) {
                _controller.goForward();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () => _controller.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.black),
            onPressed: () {
              if (widget.onBackToHome != null) {
                widget.onBackToHome!();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black),
            onPressed: () => _openServiceSettings(context, _currentServiceId),
          ),
        ],
      ),
    );
  }

  void _openServiceSettings(BuildContext context, String serviceId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ServiceSettingsSheet(
        serviceId: serviceId,
        appState: widget.appState,
        onOpenInBrowser: () {
          Navigator.of(ctx).pop();
        },
      ),
    );
  }
}
