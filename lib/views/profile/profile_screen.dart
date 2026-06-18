import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/task_controller.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';

/// View : écran de profil de l'utilisateur connecté.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final tasks = context.watch<TaskController>();
    final email = auth.loggedInEmail ?? '';
    final username = auth.currentUser?.username ?? email.split('@').first;
    final initials = username.isNotEmpty ? username.substring(0, 1).toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    initials,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 14),
                Text(username, style: Theme.of(context).textTheme.titleLarge),
                Text(email, style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          if (auth.currentUser?.id == null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                "Profil partiellement identifié : créez une première tâche pour "
                "le compléter automatiquement.",
                style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MiniStat(label: 'Tâches totales', value: '${tasks.totalCount}'),
                ),
                Container(width: 1, height: 36, color: AppColors.divider),
                Expanded(
                  child: _MiniStat(label: 'Terminées', value: '${tasks.completedCount}'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () async {
              context.read<TaskController>().reset();
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout, color: AppColors.danger),
            label: const Text('Se déconnecter', style: TextStyle(color: AppColors.danger)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.danger),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
