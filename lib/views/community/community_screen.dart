import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/community_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_formatters.dart';
import '../auth/login_screen.dart';
import '../widgets/empty_state.dart';

/// View : écran "Communauté", avec deux sources de données provenant
/// toutes deux du backend Spring Boot :
///  - "Équipe" : les tâches des autres utilisateurs (`/api/tasks`) ;
///  - "Externe" : les tâches du proxy externe (`/api/external-tasks`).
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAll());
  }

  Future<void> _fetchAll() async {
    final auth = context.read<AuthController>();
    final controller = context.read<CommunityController>();
    if (auth.token == null || auth.loggedInEmail == null) return;
    await controller.refreshAll(token: auth.token!, myEmail: auth.loggedInEmail!);
  }

  Future<void> _handleSessionExpiry() async {
    await context.read<AuthController>().logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CommunityController>();

    if (controller.sessionExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleSessionExpiry());
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Communauté'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Équipe'),
              Tab(text: 'Externe'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: TextField(
                onChanged: controller.setSearchQuery,
                decoration: const InputDecoration(
                  hintText: 'Rechercher une tâche ou une personne...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  RefreshIndicator(onRefresh: _fetchAll, child: _buildTeamTab(controller)),
                  RefreshIndicator(onRefresh: _fetchAll, child: _buildExternalTab(controller)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamTab(CommunityController controller) {
    if (controller.isLoadingTeam) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.teamError != null) {
      return EmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Connexion impossible',
        message: controller.teamError!,
      );
    }
    if (controller.teamTasks.isEmpty) {
      return const EmptyState(
        icon: Icons.groups_outlined,
        title: 'Aucune tâche',
        message: "Aucune tâche d'autre utilisateur pour le moment.",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: controller.teamTasks.length,
      itemBuilder: (context, index) {
        final task = controller.teamTasks[index];
        final ownerName = task.owner?.username ?? 'Utilisateur';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  ownerName.isNotEmpty ? ownerName.substring(0, 1).toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('$ownerName · ${DateFormatters.relativeLabel(task.dueDate)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              _StatusBadge(completed: task.isCompleted),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExternalTab(CommunityController controller) {
    if (controller.isLoadingExternal) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.externalError != null) {
      return EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Source externe indisponible',
        message: controller.externalError!,
      );
    }
    if (controller.externalTasks.isEmpty) {
      return const EmptyState(
        icon: Icons.public_off_rounded,
        title: 'Aucune tâche externe',
        message: 'Rien à afficher pour le moment.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: controller.externalTasks.length,
      itemBuilder: (context, index) {
        final task = controller.externalTasks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.public, color: AppColors.accentDark, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: task.completed ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              _StatusBadge(completed: task.completed),
            ],
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool completed;
  const _StatusBadge({required this.completed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (completed ? AppColors.success : AppColors.warning).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        completed ? 'Terminée' : 'En cours',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: completed ? AppColors.success : AppColors.accentDark,
        ),
      ),
    );
  }
}
