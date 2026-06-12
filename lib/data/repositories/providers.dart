import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_repository.dart';
import 'monster_repository.dart';
import 'run_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepository());
final monsterRepositoryProvider = Provider<MonsterRepository>((ref) => MonsterRepository());
final runRepositoryProvider = Provider<RunRepository>((ref) => RunRepository());
