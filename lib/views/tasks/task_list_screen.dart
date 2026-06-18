import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/task_controller.dart';
import '../../models/task.dart';
import '../../theme/app_colors.dart';
import '../auth/login_screen.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';

/// View : écran principal "Mes tâches".
///
/// Affiche les tâches de l'utilisateur connecté récupérées depuis le
/// backend Spring Boot (MySQL), avec filtres, statistiques rapides et
/// possibilité de créer / modifier / supprimer / terminer une tâche.
class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  Future<void> _handleSessionExpiry(BuildContext context) async {
    await context.read<AuthController>().logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final taskController = context.watch<TaskController>();
    final username = auth.currentUser?.username ?? '';
    final token = auth.token;

    if (taskController.sessionExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleSessionExpiry(context));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(username.isEmpty ? 'Mes tâches' : 'Bonjour, $username 👋'),
      ),
      body: RefreshIndicator(
        onRefresh: () => token == null
            ? Future.value()
            : taskController.loadTasksFor(
                token: token,
                email: auth.loggedInEmail!,
                knownOwnerId: auth.currentUser?.id,
              ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _StatsRow(controller: taskController),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _FilterChips(controller: taskController),
              ),
            ),
            if (taskController.errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    taskController.errorMessage!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 13),
                  ),
                ),
              ),
            if (taskController.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (taskController.tasks.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.task_alt_rounded,
                  title: 'Aucune tâche ici',
                  message: taskController.filter == TaskFilter.all
                      ? 'Appuyez sur "Nouvelle tâche" pour commencer à organiser votre journée.'
                      : 'Aucune tâche ne correspond à ce filtre pour le moment.',
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = taskController.tasks[index];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: TaskCard(
                        task: task,
                        onToggleCompleted: () => token == null
                            ? null
                            : taskController.toggleCompleted(task, token: token),
                        onTap: () => _openForm(context, task: task),
                        onDelete: () => token == null
                            ? null
                            : taskController.deleteTask(task, token: token),
                      ),
                    );
                  },
                  childCount: taskController.tasks.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle tâche'),
      ),
    );
  }

  void _openForm(BuildContext context, {Task? task}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TaskFormScreen(existingTask: task)),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final TaskController controller;
  const _StatsRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'À faire',
            value: controller.totalCount - controller.completedCount,
            color: AppColors.primary,
            icon: Icons.pending_actions_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Terminées',
            value: controller.completedCount,
            color: AppColors.success,
            icon: Icons.task_alt_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'En retard',
            value: controller.overdueCount,
            color: AppColors.danger,
            icon: Icons.error_outline_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final TaskController controller;
  const _FilterChips({required this.controller});

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, TaskFilter value) {
      final selected = controller.filter == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => controller.setFilter(value),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: AppColors.surface,
          side: BorderSide.none,
        ),
      );
    }

    return Row(
      children: [
        chip('Toutes', TaskFilter.all),
        chip('En cours', TaskFilter.active),
        chip('Terminées', TaskFilter.completed),
      ],
    );
  }
}
