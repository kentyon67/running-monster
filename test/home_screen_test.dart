import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:running_monster/data/models/monster.dart';
import 'package:running_monster/data/models/user.dart';
import 'package:running_monster/data/repositories/providers.dart';
import 'package:running_monster/features/home/home_notifier.dart';
import 'package:running_monster/features/home/home_screen.dart';

// ─── Fake Notifiers ───────────────────────────────────────────────────────────
// Must extend HomeNotifier (not AsyncNotifier<HomeState>) because homeProvider
// is AsyncNotifierProvider<HomeNotifier, HomeState> — overrideWith requires
// a HomeNotifier subclass.

class _LoadingHomeNotifier extends HomeNotifier {
  @override
  Future<HomeState> build() => Completer<HomeState>().future;
}

class _ErrorHomeNotifier extends HomeNotifier {
  @override
  Future<HomeState> build() async => throw Exception('テスト用エラー');
}

class _DataHomeNotifier extends HomeNotifier {
  final HomeState _value;
  _DataHomeNotifier(this._value);

  @override
  Future<HomeState> build() async => _value;
}

// ─── Test data ────────────────────────────────────────────────────────────────

User _makeUser({int coins = 1500, double totalKm = 50.0}) => User(
      id: 'test-user',
      username: 'テストユーザー',
      createdAt: DateTime(2024, 1, 1),
      totalDistanceKm: totalKm,
      weeklyDistanceKm: 10.0,
      currentCoins: coins,
      lastWeeklyResetDate: DateTime(2024, 1, 1),
    );

Monster _makeMonster({bool evolutionAvailable = false}) => Monster(
      id: 'test-monster',
      name: 'テストモン',
      color: 'blue',
      level: 5,
      exp: 450,
      currentEvolutionId: 'runmon_blue',
      isEvolutionAvailable: evolutionAvailable,
    );

// ─── Router helper ────────────────────────────────────────────────────────────

Widget _buildTestApp(Widget homeChild, List<Override> overrides) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => homeChild),
      GoRoute(path: '/run/active', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/missions', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/monster', builder: (_, __) => const Scaffold()),
    ],
  );
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(routerConfig: router),
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('HomeScreen', () {
    testWidgets('shows loading spinner while data is loading', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const HomeScreen(),
          [
            homeProvider.overrideWith(_LoadingHomeNotifier.new),
            dailyMissionsProvider.overrideWith((ref) async => []),
          ],
        ),
      );
      await tester.pump(); // single frame — future not yet resolved
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows error text and retry button on failure', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const HomeScreen(),
          [
            homeProvider.overrideWith(_ErrorHomeNotifier.new),
            dailyMissionsProvider.overrideWith((ref) async => []),
          ],
        ),
      );
      await tester.pump(); // trigger build
    await tester.pump(const Duration(milliseconds: 300)); // let futures resolve
      expect(find.text('データの読み込みに失敗しました'), findsOneWidget);
      expect(find.text('再試行'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows monster select screen when no monster exists',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const HomeScreen(),
          [
            homeProvider.overrideWith(
              () => _DataHomeNotifier(HomeState(user: _makeUser(), monster: null)),
            ),
            dailyMissionsProvider.overrideWith((ref) async => []),
          ],
        ),
      );
      await tester.pump(); // trigger build
    await tester.pump(const Duration(milliseconds: 300)); // let futures resolve
      expect(find.text('ランモンを選んでください'), findsOneWidget);
      expect(find.text('赤'), findsOneWidget);
      expect(find.text('青'), findsOneWidget);
      expect(find.text('緑'), findsOneWidget);
    });

    testWidgets('shows app title and run button when monster exists',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const HomeScreen(),
          [
            homeProvider.overrideWith(
              () => _DataHomeNotifier(HomeState(
                user: _makeUser(),
                monster: _makeMonster(),
                todayDistanceKm: 3.5,
              )),
            ),
            dailyMissionsProvider.overrideWith((ref) async => []),
          ],
        ),
      );
      await tester.pump(); // trigger build
    await tester.pump(const Duration(milliseconds: 300)); // let futures resolve
      expect(find.text('ランニングモンスター'), findsOneWidget);
      expect(find.text('走る'), findsOneWidget);
      expect(find.byIcon(Icons.directions_run), findsOneWidget);
    });

    testWidgets('shows coin count in app bar', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const HomeScreen(),
          [
            homeProvider.overrideWith(
              () => _DataHomeNotifier(HomeState(
                user: _makeUser(coins: 2500),
                monster: _makeMonster(),
              )),
            ),
            dailyMissionsProvider.overrideWith((ref) async => []),
          ],
        ),
      );
      await tester.pump(); // trigger build
    await tester.pump(const Duration(milliseconds: 300)); // let futures resolve
      expect(find.text('2500'), findsWidgets);
    });

    testWidgets('shows evolution banner when isEvolutionAvailable is true',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const HomeScreen(),
          [
            homeProvider.overrideWith(
              () => _DataHomeNotifier(HomeState(
                user: _makeUser(),
                monster: _makeMonster(evolutionAvailable: true),
              )),
            ),
            dailyMissionsProvider.overrideWith((ref) async => []),
          ],
        ),
      );
      await tester.pump(); // trigger build
    await tester.pump(const Duration(milliseconds: 300)); // let futures resolve
      expect(find.text('進化できます！モンスター画面へ'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsWidgets);
    });

    testWidgets('hides evolution banner when isEvolutionAvailable is false',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const HomeScreen(),
          [
            homeProvider.overrideWith(
              () => _DataHomeNotifier(HomeState(
                user: _makeUser(),
                monster: _makeMonster(evolutionAvailable: false),
              )),
            ),
            dailyMissionsProvider.overrideWith((ref) async => []),
          ],
        ),
      );
      await tester.pump(); // trigger build
    await tester.pump(const Duration(milliseconds: 300)); // let futures resolve
      expect(find.text('進化できます！モンスター画面へ'), findsNothing);
    });

    testWidgets('shows daily missions section', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const HomeScreen(),
          [
            homeProvider.overrideWith(
              () => _DataHomeNotifier(HomeState(
                user: _makeUser(),
                monster: _makeMonster(),
              )),
            ),
            dailyMissionsProvider.overrideWith((ref) async => []),
          ],
        ),
      );
      await tester.pump(); // trigger build
    await tester.pump(const Duration(milliseconds: 300)); // let futures resolve
      expect(find.text('デイリーミッション'), findsOneWidget);
    });
  });
}
