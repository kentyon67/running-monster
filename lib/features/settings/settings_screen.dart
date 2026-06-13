import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/repositories/providers.dart';
import '../../data/models/monster.dart';
import '../../services/notification_service.dart';
import '../home/home_notifier.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(homeProvider);
    final user = asyncState.valueOrNull?.user;
    final monster = asyncState.valueOrNull?.monster;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('設定',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          _Section(title: 'アカウント', children: [
            _Item(
              icon: Icons.person,
              label: 'ユーザー名変更',
              subtitle: user?.username ?? '',
              onTap: user == null
                  ? null
                  : () => _showUsernameDialog(context, ref, user.username),
            ),
            _Item(
              icon: Icons.catching_pokemon,
              label: 'モンスター名変更',
              subtitle: monster == null
                  ? '—'
                  : monster.nameChangeRemaining > 0
                      ? '残り${monster.nameChangeRemaining}回'
                      : '変更済み',
              onTap: (monster == null || monster.nameChangeRemaining == 0)
                  ? null
                  : () => _showMonsterNameDialog(context, ref, monster),
            ),
          ]),
          _Section(title: 'プロフィール', children: [
            _Item(
              icon: Icons.qr_code,
              label: 'プロフィールカード・QR',
              onTap: () => context.push('/profile'),
            ),
            _Item(
              icon: Icons.people,
              label: 'フレンド',
              onTap: () => context.push('/friends'),
            ),
          ]),
          _Section(title: 'アプリ', children: [
            ListTile(
              leading: const Icon(Icons.notifications,
                  color: AppColors.textPrimary, size: 22),
              title: const Text('通知設定',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 15)),
              subtitle: Text(
                  user?.notificationEnabled == true ? 'ON' : 'OFF',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              trailing: Switch(
                value: user?.notificationEnabled ?? false,
                activeThumbColor: AppColors.primary,
                onChanged: user == null
                    ? null
                    : (val) =>
                        _toggleNotification(context, ref, user.notificationEnabled),
              ),
            ),
            _Item(
              icon: Icons.assignment,
              label: 'デイリーミッション・実績',
              onTap: () => context.push('/missions'),
            ),
          ]),
          _Section(title: 'データ', children: [
            _Item(
              icon: Icons.delete_forever,
              label: 'モンスターリセット',
              sublabelColor: Colors.redAccent,
              onTap: () => _showResetDialog(context, ref),
            ),
          ]),
          _Section(title: '法的情報', children: [
            _Item(
                icon: Icons.description,
                label: '利用規約',
                onTap: () => context.push('/privacy')),
            _Item(
                icon: Icons.privacy_tip,
                label: 'プライバシーポリシー',
                onTap: () => context.push('/privacy')),
            _Item(
                icon: Icons.mail,
                label: 'お問い合わせ',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text('お問い合わせ',
                          style: TextStyle(color: AppColors.textPrimary)),
                      content: const Text(
                          'ご意見・ご要望は\nGitHub Issuesよりお寄せください。',
                          style: TextStyle(color: AppColors.textSecondary)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('閉じる',
                              style: TextStyle(color: AppColors.primary)),
                        ),
                      ],
                    ),
                  );
                }),
          ]),
        ],
      ),
    );
  }

  void _showUsernameDialog(
      BuildContext context, WidgetRef ref, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('ユーザー名変更',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          maxLength: 16,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'ユーザー名',
            labelStyle: TextStyle(color: AppColors.textSecondary),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.surfaceLight)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              final userRepo = ref.read(userRepositoryProvider);
              await userRepo.loadOrCreate();
              final u = userRepo.current;
              u.username = name;
              await userRepo.save(u);
              ref.invalidate(homeProvider);
            },
            child: const Text('保存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMonsterNameDialog(
      BuildContext context, WidgetRef ref, Monster monster) {
    final ctrl = TextEditingController(text: monster.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('モンスター名変更',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('※ 1回のみ変更可能です',
                style: TextStyle(color: AppColors.accent, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              maxLength: 12,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'モンスター名',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.surfaceLight)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              final monsterRepo = ref.read(monsterRepositoryProvider);
              await monsterRepo.load();
              final m = monsterRepo.current!;
              m.name = name;
              m.nameChangeRemaining = 0;
              await monsterRepo.save(m);
              ref.invalidate(homeProvider);
            },
            child: const Text('変更', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleNotification(
      BuildContext context, WidgetRef ref, bool current) async {
    final newValue = !current;
    final userRepo = ref.read(userRepositoryProvider);
    await userRepo.loadOrCreate();
    final u = userRepo.current;
    u.notificationEnabled = newValue;
    await userRepo.save(u);
    if (newValue) {
      await NotificationService.requestPermission();
      await NotificationService.scheduleRunReminder(enabled: true);
    } else {
      await NotificationService.scheduleRunReminder(enabled: false);
    }
    ref.invalidate(homeProvider);
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('モンスターをリセット',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'モンスターのLv・EXP・進化ルートが初期化されます。\nコイン・ラン履歴・アイテムは残ります。\n\nよろしいですか？',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _doReset(context, ref);
            },
            child: const Text('リセット',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _doReset(BuildContext context, WidgetRef ref) async {
    final monsterRepo = ref.read(monsterRepositoryProvider);
    await monsterRepo.load();
    final m = monsterRepo.current;
    if (m == null) return;
    m.level = 1;
    m.exp = 0;
    m.evolutionPath.clear();
    m.currentEvolutionId = 'runmon_${m.color}';
    m.isEvolutionAvailable = false;
    m.skinUnlocked = false;
    await monsterRepo.save(m);
    ref.invalidate(homeProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('モンスターをリセットしました'),
          backgroundColor: AppColors.surface,
        ),
      );
    }
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
  final String? subtitle;
  final Color sublabelColor;
  final VoidCallback? onTap;

  const _Item({
    required this.icon,
    required this.label,
    this.subtitle,
    this.sublabelColor = AppColors.textPrimary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: onTap != null,
      leading: Icon(icon, color: sublabelColor, size: 22),
      title: Text(label,
          style: TextStyle(color: sublabelColor, fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12))
          : null,
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, color: AppColors.textSecondary)
          : null,
      onTap: onTap,
    );
  }
}
