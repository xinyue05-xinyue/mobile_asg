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
    bottomNavigationBar: _CurvedRoleNavigation(
      selectedIndex: selectedIndex,
      onSelected: (index) => setState(() => selectedIndex = index),
    ),
  );
}

class _CurvedRoleNavigation extends StatelessWidget {
  const _CurvedRoleNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
        decoration: BoxDecoration(
          color: theme.navigationBarTheme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: .12),
              blurRadius: 24,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _RoleDestination(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: 'Main',
                selected: selectedIndex == 0,
                onTap: () => onSelected(0),
              ),
            ),
            Semantics(
              label: 'QR attendance scanner',
              button: true,
              child: InkWell(
                onTap: () => onSelected(0),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 54,
                  height: 54,
                  margin: const EdgeInsets.symmetric(horizontal: 22),
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: .28),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _RoleDestination(
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                label: 'Profile',
                selected: selectedIndex == 1,
                onTap: () => onSelected(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleDestination extends StatelessWidget {
  const _RoleDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: .15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                selected ? selectedIcon : icon,
                color: selected ? accent : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: selected ? accent : null,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
