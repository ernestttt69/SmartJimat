import 'package:flutter/material.dart';

/// Keeps the page subtree mounted when rotating between bottom and side navigation.
class AdaptiveNavigationScaffold extends StatelessWidget {
  const AdaptiveNavigationScaffold({
    super.key,
    required this.body,
    required this.bottomNavigationBar,
    this.backgroundColor,
  });

  final Widget body;
  final NavigationBar bottomNavigationBar;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final navigation = bottomNavigationBar;
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (landscape)
            ColoredBox(
              color: navigation.backgroundColor ?? Theme.of(context).colorScheme.surface,
              child: SafeArea(
              right: false,
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                  child: NavigationRail(
                    groupAlignment: -1,
                    selectedIndex: navigation.selectedIndex,
                    onDestinationSelected: navigation.onDestinationSelected,
                    backgroundColor: navigation.backgroundColor,
                    indicatorColor: navigation.indicatorColor,
                    labelType: NavigationRailLabelType.all,
                    destinations: navigation.destinations
                        .cast<NavigationDestination>()
                        .map((destination) => NavigationRailDestination(
                              icon: destination.icon,
                              selectedIcon: destination.selectedIcon,
                              label: Text(destination.label),
                            ))
                        .toList(),
                  ),
                    ),
                  ),
                ),
              ),
              ),
            ),
          Expanded(key: const ValueKey('navigation-content'), child: body),
        ],
      ),
      bottomNavigationBar: landscape ? null : navigation,
    );
  }
}
