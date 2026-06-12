import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/utils/exp_calculator.dart';
import '../../core/utils/run_validator.dart';
import '../../data/models/route_point.dart';
import '../../data/models/run_record.dart';

enum RunStatus { idle, running, paused, finished }

class RunState {
  final RunStatus status;
  final double distanceKm;
  final int elapsedSeconds;
  final double paceMinPerKm;
  final List<RoutePoint> routePoints;
  final String? errorMessage;
  final RunRecord? finishedRecord;

  const RunState({
    this.status = RunStatus.idle,
    this.distanceKm = 0,
    this.elapsedSeconds = 0,
    this.paceMinPerKm = 0,
    this.routePoints = const [],
    this.errorMessage,
    this.finishedRecord,
  });

  RunState copyWith({
    RunStatus? status,
    double? distanceKm,
    int? elapsedSeconds,
    double? paceMinPerKm,
    List<RoutePoint>? routePoints,
    String? errorMessage,
    RunRecord? finishedRecord,
  }) =>
      RunState(
        status: status ?? this.status,
        distanceKm: distanceKm ?? this.distanceKm,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        paceMinPerKm: paceMinPerKm ?? this.paceMinPerKm,
        routePoints: routePoints ?? this.routePoints,
        errorMessage: errorMessage,
        finishedRecord: finishedRecord ?? this.finishedRecord,
      );
}

class RunNotifier extends Notifier<RunState> {
  StreamSubscription<Position>? _positionSub;
  Timer? _timer;
  Position? _lastPosition;
  DateTime? _startTime;
  int _pausedSeconds = 0;
  DateTime? _pauseStart;

  @override
  RunState build() => const RunState();

  Future<bool> requestPermission() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  Future<void> startRun() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      state = state.copyWith(errorMessage: '位置情報の許可が必要です');
      return;
    }

    await WakelockPlus.enable();
    _startTime = DateTime.now();
    _pausedSeconds = 0;
    _lastPosition = null;

    state = const RunState(status: RunStatus.running);

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // update every 5 meters
      ),
    ).listen(_onPosition);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == RunStatus.running) {
        final elapsed = DateTime.now().difference(_startTime!).inSeconds - _pausedSeconds;
        final pace = state.distanceKm > 0
            ? (elapsed / 60) / state.distanceKm
            : 0.0;
        state = state.copyWith(elapsedSeconds: elapsed, paceMinPerKm: pace);
      }
    });
  }

  void _onPosition(Position pos) {
    if (state.status != RunStatus.running) return;

    final newPoint = RoutePoint(
      latitude: pos.latitude,
      longitude: pos.longitude,
      timestamp: DateTime.now(),
    );

    double addedDistance = 0;
    if (_lastPosition != null) {
      final distM = Geolocator.distanceBetween(
        _lastPosition!.latitude, _lastPosition!.longitude,
        pos.latitude, pos.longitude,
      );
      final dtSec = pos.timestamp
          .difference(_lastPosition!.timestamp)
          .inMilliseconds / 1000.0;

      if (!RunValidator.isAbnormalSpeed(distM, dtSec)) {
        addedDistance = distM / 1000.0;
      }
    }

    _lastPosition = pos;
    final newPoints = [...state.routePoints, newPoint];
    state = state.copyWith(
      distanceKm: state.distanceKm + addedDistance,
      routePoints: newPoints,
    );
  }

  void pauseRun() {
    if (state.status != RunStatus.running) return;
    _pauseStart = DateTime.now();
    state = state.copyWith(status: RunStatus.paused);
  }

  void resumeRun() {
    if (state.status != RunStatus.paused) return;
    if (_pauseStart != null) {
      _pausedSeconds += DateTime.now().difference(_pauseStart!).inSeconds;
    }
    state = state.copyWith(status: RunStatus.running);
  }

  /// Finish run and build RunRecord. Returns null if invalid.
  RunRecord? finishRun() {
    final elapsed = state.elapsedSeconds;
    final distance = state.distanceKm;

    final error = RunValidator.validate(distance, elapsed);
    if (error != null) {
      state = state.copyWith(status: RunStatus.idle, errorMessage: error);
      _cleanup();
      return null;
    }

    final startTime = _startTime ?? DateTime.now();
    final pace = elapsed > 0 && distance > 0 ? (elapsed / 60) / distance : 0.0;
    final exp = ExpCalculator.calcExp(distance, startTime);
    final coins = ExpCalculator.calcCoins(distance);
    final bonus = ExpCalculator.getBonusMultiplier(startTime, distance);

    final record = RunRecord(
      id: const Uuid().v4(),
      startedAt: startTime,
      endedAt: DateTime.now(),
      distanceKm: distance,
      durationSeconds: elapsed,
      averagePace: pace,
      expGained: exp,
      coinsGained: coins,
      appliedBonus: bonus,
      routePoints: state.routePoints,
    );

    state = state.copyWith(status: RunStatus.finished, finishedRecord: record);
    _cleanup();
    return record;
  }

  void _cleanup() {
    _positionSub?.cancel();
    _timer?.cancel();
    WakelockPlus.disable();
  }

  void reset() {
    _cleanup();
    _startTime = null;
    _pausedSeconds = 0;
    _lastPosition = null;
    state = const RunState();
  }
}

final runProvider = NotifierProvider<RunNotifier, RunState>(RunNotifier.new);
