import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell shell;

  const MainScaffold({super.key, required this.shell});

  static const _tabs = [
    _TabItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'ホーム', path: '/home'),
    _TabItem(icon: Icons.directions_run_outlined, activeIcon: Icons.directions_run, label: 'ラン', path: '/run'),
    _TabItem(icon: Icons.catching_pokemon_outlined, activeIcon: Icons.catching_pokemon, label: 'モンスター', path: '/monster'),
    _TabItem(icon: Icons.casino_outlined, activeIcon: Icons.casino, label: 'ガチャ', path: '/gacha'),
    _TabItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: '設定', path: '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: shell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: shell.currentIndex,
        onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.navSelected,
        unselectedItemColor: AppColors.navUnselected,
        type: BottomNavigationBarType.fixed,
        items: _tabs
            .map((t) => BottomNavigationBarItem(
                  icon: Icon(t.icon),
                  activeIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  const _TabItem({required this.icon, required this.activeIcon, required this.label, required this.path});
}
