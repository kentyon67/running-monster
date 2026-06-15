import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/local/hive_boxes.dart';
import '../home/widgets/monster_painter.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _pages = [
    _PageData(
      icon: Icons.directions_run,
      title: 'ランニングモンスター',
      subtitle: 'へようこそ！',
      description: '走れば走るほどモンスターが成長する\nGPSランニングアプリです。\n毎日の走りがゲームになります！',
      color: AppColors.primary,
    ),
    _PageData(
      icon: Icons.star,
      title: 'EXPとコインを獲得',
      subtitle: '走るたびに報酬GET',
      description: '1km走るごとにEXP・コインを獲得。\n距離が長いほど倍率アップ！\n朝・夜ランはボーナスタイムです。',
      color: AppColors.accent,
    ),
    _PageData(
      icon: Icons.auto_awesome,
      title: 'モンスターを育てよう',
      subtitle: '進化・ガチャ・フレンド',
      description: 'レベルアップで進化を選択。\nガチャでアイテムを集め、\nフレンドのプロフィールをQRコードで共有しよう！',
      color: AppColors.blue,
      showMonster: true,
    ),
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      _ctrl.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await HiveBoxes.user.put('onboarding_complete', true);
    if (mounted) context.go('/home');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('スキップ',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _OnboardingPage(data: _pages[i]),
              ),
            ),

            // Dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _page ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? _pages[_page].color
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_page].color,
                        foregroundColor: _page == 1 ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _page == _pages.length - 1 ? 'はじめる！' : '次へ',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatefulWidget {
  final _PageData data;
  const _OnboardingPage({required this.data});

  @override
  State<_OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<_OnboardingPage>
    with TickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late AnimationController _monsterCtrl;
  late Animation<double> _monsterAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _anim, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _anim, curve: Curves.easeIn));
    _anim.forward();
    _monsterCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _monsterAnim = Tween<double>(begin: 0.0, end: math.pi * 2)
        .animate(_monsterCtrl);
  }

  @override
  void dispose() {
    _anim.dispose();
    _monsterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scale,
              child: widget.data.showMonster
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                widget.data.color.withValues(alpha: 0.18),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _monsterAnim,
                          builder: (_, __) => buildMonsterWidget(
                            'spiritmon',
                            'green',
                            size: 140,
                            animValue: _monsterAnim.value,
                          ),
                        ),
                      ],
                    )
                  : Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.data.color.withValues(alpha: 0.15),
                        border: Border.all(color: widget.data.color, width: 3),
                      ),
                      child: Center(
                        child: Icon(widget.data.icon,
                            size: 72, color: widget.data.color),
                      ),
                    ),
            ),
            const SizedBox(height: 40),
            Text(
              widget.data.title,
              style: TextStyle(
                color: widget.data.color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.data.subtitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              widget.data.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PageData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Color color;
  final bool showMonster;

  const _PageData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
    this.showMonster = false,
  });
}
