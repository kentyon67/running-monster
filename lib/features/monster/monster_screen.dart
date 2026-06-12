import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MonsterScreen extends StatelessWidget {
  const MonsterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('モンスター', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.catching_pokemon, size: 80, color: AppColors.primary),
            SizedBox(height: 16),
            Text('近日公開', style: TextStyle(color: AppColors.textSecondary, fontSize: 18)),
            SizedBox(height: 8),
            Text('進化・スキン・図鑑機能を実装予定',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
