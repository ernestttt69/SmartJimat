import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/adaptive_navigation_scaffold.dart';

import 'customer_home_screen.dart';
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
  static const Color smartJimatGreen =
  Color(0xFF38BB62);

  static const Color darkGreen =
  Color(0xFF2E9F52);

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
          await SystemNavigator.pop();
        }
      },
      child: AdaptiveNavigationScaffold(
        body: IndexedStack(
          index: selectedIndex,
          children: [
            buildNavigator(
              index: 0,
              page: const CustomerHomeScreen(),
            ),
            buildNavigator(
              index: 1,
              page: const SearchShopScreen(),
            ),
            buildNavigator(
              index: 2,
              page: const ProfileScreen(),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected:
          onDestinationSelected,
          backgroundColor:
          smartJimatGreen,
          indicatorColor:
          Colors.white,
          labelBehavior:
          NavigationDestinationLabelBehavior
              .alwaysShow,
          height: 72,
          destinations: const [
            NavigationDestination(
              icon: Icon(
                Icons.home_outlined,
                color: Colors.white,
              ),
              selectedIcon: Icon(
                Icons.home,
                color: darkGreen,
              ),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.store_outlined,
                color: Colors.white,
              ),
              selectedIcon: Icon(
                Icons.store,
                color: darkGreen,
              ),
              label: 'Search Shop',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.person_outline,
                color: Colors.white,
              ),
              selectedIcon: Icon(
                Icons.person,
                color: darkGreen,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}