import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class RunStatsPanel extends StatelessWidget {
  final double distanceKm;
  final int elapsedSeconds;
  final double paceMinPerKm; // 0 if not moving

  const RunStatsPanel({
    super.key,
    required this.distanceKm,
    required this.elapsedSeconds,
    required this.paceMinPerKm,
  });

  String get _timeStr {
    final h = elapsedSeconds ~/ 3600;
    final m = (elapsedSeconds % 3600) ~/ 60;
    final s = elapsedSeconds % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _paceStr {
    if (paceMinPerKm <= 0 || paceMinPerKm.isInfinite) return "--'--\"";
    final min = paceMinPerKm.floor();
    final sec = ((paceMinPerKm - min) * 60).round();
    return "$min'${sec.toString().padLeft(2, '0')}\"";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BigStat(label: '距離', value: distanceKm.toStringAsFixed(2), unit: 'km'),
          Container(width: 1, height: 60, color: AppColors.surfaceLight),
          _BigStat(label: '時間', value: _timeStr, unit: ''),
          Container(width: 1, height: 60, color: AppColors.surfaceLight),
          _BigStat(label: 'ペース', value: _paceStr, unit: '/km'),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _BigStat({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 3, left: 2),
                child: Text(unit,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
          ],
        ),
      ],
    );
  }
}
