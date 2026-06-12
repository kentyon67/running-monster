import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GachaScreen extends StatelessWidget {
  const GachaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('ガチャ', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.casino, size: 80, color: AppColors.primary),
            SizedBox(height: 16),
            Text('近日公開', style: TextStyle(color: AppColors.textSecondary, fontSize: 18)),
            SizedBox(height: 8),
            Text('オーラ・バナー・フレーム・スキンを実装予定',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
