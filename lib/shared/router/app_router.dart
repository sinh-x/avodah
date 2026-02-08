import 'package:go_router/go_router.dart';

import '../../features/tasks/screens/task_list_screen.dart';
import '../../features/timer/screens/timer_screen.dart';
import '../../features/projects/screens/project_list_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import 'shell_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/tasks',
  routes: [
    ShellRoute(
      builder: (context, state, child) => ShellScaffold(child: child),
      routes: [
        GoRoute(
          path: '/tasks',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TaskListScreen(),
          ),
        ),
        GoRoute(
          path: '/timer',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: TimerScreen(),
          ),
        ),
        GoRoute(
          path: '/projects',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProjectListScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
  ],
);
