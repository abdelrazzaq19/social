import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_social/pages/pages.dart';
import 'package:quick_social/repositories/repositories.dart';
import 'package:quick_social/services/prefs_service.dart';
import 'package:quick_social/state/theme_controller.dart';
import 'package:quick_social/theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.prefs});

  final PrefsService prefs;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeController(prefs)..load(),
        ),
        ChangeNotifierProvider(create: (_) => FeedRepository(prefs)),
        ChangeNotifierProvider(create: (_) => CommentRepository(prefs)),
        ChangeNotifierProvider(create: (_) => SocialRepository(prefs)),
        ChangeNotifierProvider(create: (_) => StoryRepository(prefs)),
        ChangeNotifierProvider(create: (_) => NotificationRepository(prefs)),
      ],
      child: Consumer<ThemeController>(
        builder: (_, themeController, __) {
          return MaterialApp(
            title: 'Quick Social',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeController.mode,
            home: const SplashPage(),
          );
        },
      ),
    );
  }
}
