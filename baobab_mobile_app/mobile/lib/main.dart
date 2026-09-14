import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/manual_input_screen.dart';
import 'screens/image_input_screen.dart';
import 'screens/history_screen.dart';
import 'screens/compare_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BaobabApp());
}

class BaobabApp extends StatelessWidget {
  const BaobabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baobab Tree Analysis',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/home': (_) => const HomeScreen(),
        '/manual': (_) => const ManualInputScreen(),
        '/image': (_) => const ImageInputScreen(),
        '/history': (_) => const HistoryScreen(),
        '/compare': (_) => const CompareScreen(),
      },
    );
  }
}

/// Decides the first screen based on a persisted session.
Future<String> resolveStartRoute() async {
  await AuthService.instance.loadSession();
  return AuthService.instance.isLoggedIn ? '/home' : '/login';
}
