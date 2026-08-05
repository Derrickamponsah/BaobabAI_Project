import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _status;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final s = await ApiService.instance.modelStatus();
      if (mounted) setState(() => _status = s);
    } catch (_) {/* offline is fine on the dashboard */}
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Baobab Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/history'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.instance.logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatus,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Hello, ${user?['full_name'] ?? 'Researcher'} 👋',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('Choose how you want to analyse a baobab tree.',
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 20),
            _ActionTile(
              icon: Icons.edit_note,
              color: AppTheme.primary,
              title: 'Manual entry',
              subtitle: 'Type the tree measurements and site details.',
              onTap: () => Navigator.pushNamed(context, '/manual'),
            ),
            _ActionTile(
              icon: Icons.photo_camera_outlined,
              color: AppTheme.secondary,
              title: 'Analyse from photo',
              subtitle:
                  'Upload a baobab photo to auto-estimate its dimensions.',
              onTap: () => Navigator.pushNamed(context, '/image'),
            ),
            _ActionTile(
              icon: Icons.history,
              color: AppTheme.accent,
              title: 'Prediction history',
              subtitle: 'Review your previous analyses.',
              onTap: () => Navigator.pushNamed(context, '/history'),
            ),
            const SizedBox(height: 10),
            if (_status != null) _ModelStatusCard(status: _status!),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModelStatusCard extends StatelessWidget {
  final Map<String, dynamic> status;
  const _ModelStatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final models = (status['models'] as Map).cast<String, dynamic>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Model status',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 10),
            ...models.entries.map((e) {
              final acc = (e.value['accuracy'] as num) * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key[0].toUpperCase() + e.key.substring(1)),
                    Text('${e.value['algorithm']} · ${acc.toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              );
            }),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.autorenew, size: 18, color: AppTheme.secondary),
                const SizedBox(width: 6),
                Text(
                    'Auto-retrain: ${status['pending_samples']}/${status['retrain_threshold']} new samples',
                    style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
