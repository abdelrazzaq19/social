import 'package:flutter/material.dart';
import 'package:quick_social/app.dart';
import 'package:quick_social/services/prefs_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Opened before the first frame so every repository can read its stored
  // state synchronously, and the app never starts in one state and snaps
  // into another.
  final PrefsService prefs = await PrefsService.create();

  runApp(MyApp(prefs: prefs));
}
