import 'package:flutter/material.dart';

import 'shared/theme/app_theme.dart';
import 'shared/router/app_router.dart';

class AvodahApp extends StatelessWidget {
  const AvodahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Avodah',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
