import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('設定', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: ListView(
        children: [
          _Section(title: 'アカウント', children: [
            _Item(icon: Icons.person, label: 'ユーザー名変更', onTap: () {}),
            _Item(icon: Icons.catching_pokemon, label: 'モンスター名変更', onTap: () {}),
          ]),
          _Section(title: 'アプリ', children: [
            _Item(icon: Icons.notifications, label: '通知設定', onTap: () {}),
            _Item(icon: Icons.backup, label: 'バックアップ', onTap: () {}),
            _Item(icon: Icons.restore, label: '復元', onTap: () {}),
          ]),
          _Section(title: 'データ', children: [
            _Item(
              icon: Icons.delete_forever,
              label: 'リセット',
              onTap: () => _showResetDialog(context),
              color: Colors.redAccent,
            ),
          ]),
          _Section(title: '法的情報', children: [
            _Item(icon: Icons.description, label: '利用規約', onTap: () {}),
            _Item(icon: Icons.privacy_tip, label: 'プライバシーポリシー', onTap: () {}),
            _Item(icon: Icons.mail, label: 'お問い合わせ', onTap: () {}),
          ]),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('モンスターをリセット', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'モンスターのLv・EXP・進化ルートが初期化されます。\nコイン・ラン履歴・アイテムは残ります。\n\nよろしいですか？',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: implement reset in Phase 2
            },
            child: const Text('リセット', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(title,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _Item({required this.icon, required this.label, required this.onTap, this.color = AppColors.textPrimary});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: TextStyle(color: color, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
