import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/services/app_state.dart';
import 'ui/root_screen.dart';
import 'ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.bgMain,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  final appState = AppState();
  await appState.initialize();

  runApp(InhibitApp(appState: appState));
}

class InhibitApp extends StatelessWidget {
  final AppState appState;

  const InhibitApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'Inhibit',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.neobrutalistTheme,
          home: appState.isInitialized
              ? RootScreen(appState: appState)
              : const Scaffold(
                  backgroundColor: AppTheme.bgMain,
                  body: Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  ),
                ),
        );
      },
    );
  }
}
