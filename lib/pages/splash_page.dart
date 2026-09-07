import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quick_social/common/common.dart';
import 'package:quick_social/pages/pages.dart';
import 'package:quick_social/widgets/widgets.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  /// How long the brand holds before the app opens.
  ///
  /// Nothing is loaded during this time — startup work happens before
  /// `runApp` — so this is a brand beat, not a progress indicator. Long
  /// enough to register, short enough not to feel like a stall.
  static const Duration holdDuration = Duration(milliseconds: 1500);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Scheduled once, from initState. Scheduling from build would queue
    // another navigation on every rebuild.
    _timer = Timer(SplashPage.holdDuration, _openHome);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _openHome() {
    if (!mounted) return;

    // Replaces rather than pushes, so system back from the feed exits the app
    // instead of returning to a splash screen the user cannot get past.
    context.pushReplacement(route: HomePage.route());
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: AppLogo(),
      ),
    );
  }
}
