import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/community_controller.dart';
import 'controllers/task_controller.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'views/auth/login_screen.dart';
import 'views/main_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  runApp(const TodoCollabApp());
}

/// Racine de l'application.
///
/// Met en place les Controllers (couche MVC) via [MultiProvider] afin
/// qu'ils soient accessibles depuis n'importe quelle View grâce à
/// `context.watch<...>()` / `context.read<...>()`.
class TodoCollabApp extends StatelessWidget {
  const TodoCollabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => TaskController()),
        ChangeNotifierProvider(create: (_) => CommunityController()),
      ],
      child: MaterialApp(
        title: 'TaskTeam',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const _Bootstrapper(),
      ),
    );
  }
}

/// Détermine, au lancement, si l'on doit afficher l'écran de connexion
/// ou directement la navigation principale (session déjà active).
class _Bootstrapper extends StatefulWidget {
  const _Bootstrapper();

  @override
  State<_Bootstrapper> createState() => _BootstrapperState();
}

class _BootstrapperState extends State<_Bootstrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthController>();
      await auth.bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (auth.status == AuthStatus.unknown ||
        auth.status == AuthStatus.loading) {
      return const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (auth.status == AuthStatus.authenticated) {
      return const MainNavigation();
    }

    return const LoginScreen();
  }
}
