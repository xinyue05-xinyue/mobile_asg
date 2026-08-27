import 'package:flutter/material.dart';

class StaffShell extends StatefulWidget {
  const StaffShell({
    super.key,
    required this.mainPage,
    required this.profilePage,
  });

  final Widget mainPage;
  final Widget profilePage;

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: selectedIndex,
      children: [widget.mainPage, widget.profilePage],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => setState(() => selectedIndex = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Main',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    ),
  );
}
