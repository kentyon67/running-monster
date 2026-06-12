import 'package:go_router/go_router.dart';
import '../../data/local/hive_boxes.dart';
import '../../features/home/home_screen.dart';
import '../../features/run/run_screen.dart';
import '../../features/run/run_result_screen.dart';
import '../../features/monster/monster_screen.dart';
import '../../features/gacha/gacha_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/profile/profile_card_screen.dart';
import '../../features/friends/friends_screen.dart';
import '../../features/missions/missions_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/settings/privacy_policy_screen.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../../data/models/run_record.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  redirect: (context, state) {
    final done = HiveBoxes.user.get('onboarding_complete') as bool? ?? false;
    if (!done && state.uri.path != '/onboarding') return '/onboarding';
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainScaffold(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/home', builder: (c, s) => const HomeScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/run', builder: (c, s) => const RunScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/monster', builder: (c, s) => const MonsterScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/gacha', builder: (c, s) => const GachaScreen())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen())],
        ),
      ],
    ),
    GoRoute(
      path: '/run/active',
      builder: (context, state) => const RunActiveScreen(),
    ),
    GoRoute(
      path: '/run/result',
      builder: (context, state) {
        final record = state.extra as RunRecord;
        return RunResultScreen(record: record);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileCardScreen(),
    ),
    GoRoute(
      path: '/friends',
      builder: (context, state) => const FriendsScreen(),
    ),
    GoRoute(
      path: '/missions',
      builder: (context, state) => const MissionsScreen(),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
  ],
);
