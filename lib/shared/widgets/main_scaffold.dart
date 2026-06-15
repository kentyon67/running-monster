import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell shell;

  const MainScaffold({super.key, required this.shell});

  static const _tabs = [
    _TabItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'ホーム',
        path: '/home'),
    _TabItem(
        icon: Icons.directions_run_outlined,
        activeIcon: Icons.directions_run,
        label: 'ラン',
        path: '/run'),
    _TabItem(
        icon: Icons.pets_outlined,
        activeIcon: Icons.pets,
        label: 'モンスター',
        path: '/monster'),
    _TabItem(
        icon: Icons.casino_outlined,
        activeIcon: Icons.casino,
        label: 'ガチャ',
        path: '/gacha'),
    _TabItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
        label: '設定',
        path: '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: shell,
      bottomNavigationBar: _PremiumNavBar(
        currentIndex: shell.currentIndex,
        onTap: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}

class _PremiumNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _PremiumNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = MainScaffold._tabs;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.surfaceBorder, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final isSelected = i == currentIndex;
              final tab = tabs[i];
              return Expanded(
                child: _NavItem(
                  icon: tab.icon,
                  activeIcon: tab.activeIcon,
                  label: tab.label,
                  isSelected: isSelected,
                  onTap: () => onTap(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: isSelected
                  ? BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected
                    ? AppColors.navSelected
                    : AppColors.navUnselected,
                size: 22,
                shadows: isSelected
                    ? [
                        Shadow(
                          color: AppColors.primary.withValues(alpha: 0.8),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.navSelected
                    : AppColors.navUnselected,
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}
