import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/task_controller.dart';
import 'community/community_screen.dart';
import 'profile/profile_screen.dart';
import 'tasks/task_list_screen.dart';

/// View : coquille de navigation principale, affichée une fois
/// l'utilisateur connecté.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMyTasks());
  }

  Future<void> _loadMyTasks() async {
    final auth = context.read<AuthController>();
    final taskController = context.read<TaskController>();

    if (auth.token == null || auth.loggedInEmail == null) return;

    await taskController.loadTasksFor(
      token: auth.token!,
      email: auth.loggedInEmail!,
      knownOwnerId: auth.currentUser?.id,
    );

    // Complète le profil (id/username) si on vient de retrouver
    // l'utilisateur connecté parmi ses propres tâches.
    if (taskController.identifiedOwner != null) {
      await auth.adoptIdentity(taskController.identifiedOwner!);
    }
  }

  static const _screens = [
    TaskListScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_rtl_outlined),
            activeIcon: Icon(Icons.checklist_rtl_rounded),
            label: 'Mes tâches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups_rounded),
            label: 'Communauté',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
