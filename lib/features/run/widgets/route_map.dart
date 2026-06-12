import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/route_point.dart';

class RouteMap extends StatelessWidget {
  final List<RoutePoint> points;
  final bool isLive; // show current position marker if true

  const RouteMap({super.key, required this.points, this.isLive = true});

  @override
  Widget build(BuildContext context) {
    final latLngPoints = points.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final hasPoints = latLngPoints.isNotEmpty;
    final center = hasPoints ? latLngPoints.last : const LatLng(35.6812, 139.7671);

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 16,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.running_monster',
        ),
        if (hasPoints)
          PolylineLayer(
            polylines: [
              Polyline(
                points: latLngPoints,
                color: AppColors.primary,
                strokeWidth: 4,
              ),
            ],
          ),
        if (hasPoints && isLive)
          MarkerLayer(
            markers: [
              Marker(
                point: latLngPoints.last,
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
