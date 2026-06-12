import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class RunStatsPanel extends StatelessWidget {
  final double distanceKm;
  final int elapsedSeconds;
  final double paceMinPerKm;
  final bool compact;

  const RunStatsPanel({
    super.key,
    required this.distanceKm,
    required this.elapsedSeconds,
    required this.paceMinPerKm,
    this.compact = false,
  });

  String get _timeStr {
    final h = elapsedSeconds ~/ 3600;
    final m = (elapsedSeconds % 3600) ~/ 60;
    final s = elapsedSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
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
    final valueFontSize = compact ? 22.0 : 26.0;
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: compact ? 12 : 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (!compact)
            _BigStat(
                label: '距離',
                value: distanceKm.toStringAsFixed(2),
                unit: 'km',
                fontSize: valueFontSize),
          if (!compact)
            Container(width: 1, height: 60, color: AppColors.surfaceLight),
          _BigStat(
              label: '時間',
              value: _timeStr,
              unit: '',
              fontSize: valueFontSize),
          Container(
              width: 1,
              height: compact ? 40 : 60,
              color: AppColors.surfaceLight),
          _BigStat(
              label: 'ペース',
              value: _paceStr,
              unit: '/km',
              fontSize: valueFontSize),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final double fontSize;

  const _BigStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold)),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 3, left: 2),
                child: Text(unit,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ),
          ],
        ),
      ],
    );
  }
}
