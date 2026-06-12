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

// Distinct GPS error codes surfaced to UI
enum GpsErrorType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
}

class RunState {
  final RunStatus status;
  final double distanceKm;
  final int elapsedSeconds;
  final double paceMinPerKm;
  final List<RoutePoint> routePoints;
  final String? errorMessage;
  final GpsErrorType? gpsErrorType;
  final RunRecord? finishedRecord;
  final bool gpsAcquired;

  const RunState({
    this.status = RunStatus.idle,
    this.distanceKm = 0,
    this.elapsedSeconds = 0,
    this.paceMinPerKm = 0,
    this.routePoints = const [],
    this.errorMessage,
    this.gpsErrorType,
    this.finishedRecord,
    this.gpsAcquired = false,
  });

  RunState copyWith({
    RunStatus? status,
    double? distanceKm,
    int? elapsedSeconds,
    double? paceMinPerKm,
    List<RoutePoint>? routePoints,
    String? errorMessage,
    GpsErrorType? gpsErrorType,
    RunRecord? finishedRecord,
    bool? gpsAcquired,
  }) =>
      RunState(
        status: status ?? this.status,
        distanceKm: distanceKm ?? this.distanceKm,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        paceMinPerKm: paceMinPerKm ?? this.paceMinPerKm,
        routePoints: routePoints ?? this.routePoints,
        errorMessage: errorMessage,
        gpsErrorType: gpsErrorType,
        finishedRecord: finishedRecord ?? this.finishedRecord,
        gpsAcquired: gpsAcquired ?? this.gpsAcquired,
      );
}

class RunNotifier extends Notifier<RunState> {
  StreamSubscription<Position>? _positionSub;
  Timer? _timer;
  Timer? _gpsTimeoutTimer;
  Position? _lastPosition;
  DateTime? _startTime;
  int _pausedSeconds = 0;
  DateTime? _pauseStart;

  static const _gpsTimeoutSeconds = 20;

  @override
  RunState build() => const RunState();

  Future<void> startRun() async {
    // 1. Check if location service is enabled at OS level
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(
        errorMessage: '位置情報サービスをONにしてください（設定 → プライバシーとセキュリティ → 位置情報サービス）',
        gpsErrorType: GpsErrorType.serviceDisabled,
      );
      return;
    }

    // 2. Check and request permission
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.deniedForever) {
      state = state.copyWith(
        errorMessage: '位置情報の許可が永久に拒否されています。設定アプリから許可してください。',
        gpsErrorType: GpsErrorType.permissionDeniedForever,
      );
      return;
    }
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm != LocationPermission.always && perm != LocationPermission.whileInUse) {
      state = state.copyWith(
        errorMessage: '位置情報の許可が必要です',
        gpsErrorType: GpsErrorType.permissionDenied,
      );
      return;
    }

    await WakelockPlus.enable();
    _startTime = DateTime.now();
    _pausedSeconds = 0;
    _lastPosition = null;

    state = const RunState(status: RunStatus.running, gpsAcquired: false);

    // 3. GPS signal timeout — show warning if no position within N seconds
    _gpsTimeoutTimer = Timer(const Duration(seconds: _gpsTimeoutSeconds), () {
      if (_lastPosition == null && state.status == RunStatus.running) {
        state = state.copyWith(
          errorMessage: 'GPS信号を取得できませんでした。屋外で再試行してください。',
          gpsErrorType: GpsErrorType.timeout,
          status: RunStatus.idle,
        );
        _cleanup();
      }
    });

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(
      _onPosition,
      onError: (e) {
        state = state.copyWith(
          errorMessage: 'GPS接続エラーが発生しました。再試行してください。',
          status: RunStatus.idle,
        );
        _cleanup();
      },
    );

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

    _gpsTimeoutTimer?.cancel();

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
      gpsAcquired: true,
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
    _gpsTimeoutTimer?.cancel();
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
