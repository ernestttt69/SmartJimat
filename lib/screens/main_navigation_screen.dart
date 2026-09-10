import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'search_shop_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState
    extends State<MainNavigationScreen> {
  int selectedIndex = 0;

  final List<GlobalKey<NavigatorState>> navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  void onDestinationSelected(int index) {
    if (selectedIndex == index) {
      navigatorKeys[index]
          .currentState
          ?.popUntil((route) => route.isFirst);

      return;
    }

    setState(() {
      selectedIndex = index;
    });
  }

  Future<bool> handleBack() async {
    final navigator =
        navigatorKeys[selectedIndex].currentState;

    if (navigator != null &&
        navigator.canPop()) {
      navigator.pop();
      return false;
    }

    if (selectedIndex != 0) {
      setState(() {
        selectedIndex = 0;
      });

      return false;
    }

    return true;
  }

  Widget buildNavigator({
    required int index,
    required Widget page,
  }) {
    return Navigator(
      key: navigatorKeys[index],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => page,
          settings: settings,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (
          didPop,
          result,
          ) async {
        if (didPop) {
          return;
        }

        final shouldExit =
        await handleBack();

        if (shouldExit &&
            context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: selectedIndex,
          children: [
            buildNavigator(
              index: 0,
              page:
              const DashboardScreen(),
            ),
            buildNavigator(
              index: 1,
              page:
              const SearchShopScreen(),
            ),
            buildNavigator(
              index: 2,
              page:
              const ProfileScreen(),
            ),
          ],
        ),
        bottomNavigationBar:
        NavigationBar(
          selectedIndex:
          selectedIndex,
          onDestinationSelected:
          onDestinationSelected,
          backgroundColor:
          Colors.white,
          indicatorColor:
          const Color(
            0xFFE1F6E8,
          ),
          height: 72,
          destinations:
          const [
            NavigationDestination(
              icon: Icon(
                Icons.home_outlined,
              ),
              selectedIcon: Icon(
                Icons.home,
                color: Color(
                  0xFF38BB62,
                ),
              ),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.store_outlined,
              ),
              selectedIcon: Icon(
                Icons.store,
                color: Color(
                  0xFF38BB62,
                ),
              ),
              label: 'Search Shop',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.person_outline,
              ),
              selectedIcon: Icon(
                Icons.person,
                color: Color(
                  0xFF38BB62,
                ),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}