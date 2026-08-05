import 'package:flutter/material.dart';
import '../main.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    final route = await resolveStartRoute();
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.park_rounded, size: 88, color: Colors.white),
            SizedBox(height: 16),
            Text('Baobab Tree Analysis',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Predict uses & agronomic value',
                style: TextStyle(color: Colors.white70)),
            SizedBox(height: 28),
            SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
