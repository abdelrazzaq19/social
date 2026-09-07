import 'package:flutter/material.dart';
import 'package:quick_social/common/common.dart';
import 'package:quick_social/data/dummy_data_source.dart';
import 'package:quick_social/pages/pages.dart';
import 'package:quick_social/theme/app_tokens.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const HomePage());
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// One controller for the lifetime of the state.
  ///
  /// Building it inside `build` leaked a controller per frame and left
  /// `jumpToPage` liable to run against a detached one.
  final PageController _pageController = PageController();

  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Called when the user taps the navigation bar or rail.
  void _onDestinationSelected(int index) {
    if (index == _pageIndex) return;

    final int previousIndex = _pageIndex;

    // Move the indicator immediately; waiting for the page to settle makes
    // the navigation feel unresponsive.
    setState(() => _pageIndex = index);

    if (!_pageController.hasClients) return;

    if ((index - previousIndex).abs() == 1) {
      _pageController.animateToPage(
        index,
        duration: AppDuration.medium,
        curve: Curves.easeOutCubic,
      );
    } else {
      // Animating across a non-adjacent page would build the page in between
      // for no reason.
      _pageController.jumpToPage(index);
    }
  }

  /// Called when the user swipes the [PageView].
  void _onPageChanged(int index) {
    if (index == _pageIndex) return;
    setState(() => _pageIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final Widget pageView = PageView(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      children: [
        const FeedPage(),
        const NotificationsPage(),
        ProfilePage(user: DummyDataSource.instance.currentUser),
      ],
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: context.responsive(
        sm: pageView,
        md: Row(
          children: [
            _navigationRail(context),
            const VerticalDivider(width: 1, thickness: 1),
            Flexible(child: pageView),
          ],
        ),
      ),
      bottomNavigationBar: context.isMobile ? _navigationBar(context) : null,
    );
  }

  static const List<({IconData icon, IconData selectedIcon, String label})>
      _destinations = [
    (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
    (
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications,
      label: 'Notifications',
    ),
    (icon: Icons.person_outlined, selectedIcon: Icons.person, label: 'Profile'),
  ];

  /// tablet & desktop screen
  Widget _navigationRail(BuildContext context) {
    return NavigationRail(
      selectedIndex: _pageIndex,
      onDestinationSelected: _onDestinationSelected,
      extended: context.isDesktop,
      labelType: context.isDesktop
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      destinations: [
        for (final destination in _destinations)
          NavigationRailDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: Text(destination.label),
          ),
      ],
    );
  }

  /// mobile screen
  Widget _navigationBar(BuildContext context) {
    return NavigationBar(
      selectedIndex: _pageIndex,
      onDestinationSelected: _onDestinationSelected,
      destinations: [
        for (final destination in _destinations)
          NavigationDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: destination.label,
            tooltip: destination.label,
          ),
      ],
    );
  }
}
