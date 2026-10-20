import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:watad/core/theme/app_spacing.dart';

/// Moves an [AppGoogleMap] from outside, e.g. to a place the user searched.
/// The page owns it, passes it as [AppGoogleMap.camera] and disposes it.
class AppMapCamera extends ChangeNotifier {
  ({
    double latitude,
    double longitude,
    ({double south, double west, double north, double east})? area,
  })?
  _target;

  /// Shows [latitude], [longitude] on the map: the whole [area] when given
  /// (a city is wide, a street narrow), or close up around the point.
  void show({
    required double latitude,
    required double longitude,
    ({double south, double west, double north, double east})? area,
  }) {
    _target = (latitude: latitude, longitude: longitude, area: area);
    notifyListeners();
  }
}

/// Reusable Google Map component following Clean Architecture (APP_ARCHITECTURE.md §6).
///
/// Features never import `google_maps_flutter` directly; they use `AppGoogleMap`.
class AppGoogleMap extends StatefulWidget {
  const AppGoogleMap({
    super.key,
    this.initialLatitude = 24.7136, // Riyadh coordinates by default
    this.initialLongitude = 46.6753,
    this.initialZoom = 14.0,
    this.onTap,
    this.onCameraMove,
    this.onCameraIdle,
    this.markers = const {},
    this.myLocationButtonEnabled = false,
    this.zoomControlsEnabled = false,
    this.camera,
  });

  final double initialLatitude;
  final double initialLongitude;
  final double initialZoom;
  final void Function(LatLng)? onTap;
  final void Function(CameraPosition)? onCameraMove;
  final void Function(LatLng)? onCameraIdle;
  final Set<Marker> markers;
  final bool myLocationButtonEnabled;
  final bool zoomControlsEnabled;

  /// Moves the map when told to; the user still drags it as usual.
  final AppMapCamera? camera;

  @override
  State<AppGoogleMap> createState() => _AppGoogleMapState();
}

class _AppGoogleMapState extends State<AppGoogleMap> {
  GoogleMapController? _controller;
  LatLng? _lastTarget;

  /// How close a point without an area is shown: a few streets around it.
  static const double _pointZoom = 16;

  @override
  void initState() {
    super.initState();
    widget.camera?.addListener(_moveCamera);
  }

  @override
  void didUpdateWidget(AppGoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.camera != widget.camera) {
      oldWidget.camera?.removeListener(_moveCamera);
      widget.camera?.addListener(_moveCamera);
    }
  }

  @override
  void dispose() {
    widget.camera?.removeListener(_moveCamera);
    _controller?.dispose();
    super.dispose();
  }

  void _moveCamera() {
    final target = widget.camera?._target;
    if (target == null) return;
    final area = target.area;
    _controller?.animateCamera(
      area == null
          ? CameraUpdate.newLatLngZoom(
              LatLng(target.latitude, target.longitude),
              _pointZoom,
            )
          : CameraUpdate.newLatLngBounds(
              LatLngBounds(
                southwest: LatLng(area.south, area.west),
                northeast: LatLng(area.north, area.east),
              ),
              AppSpacing.xl,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(widget.initialLatitude, widget.initialLongitude),
        zoom: widget.initialZoom,
      ),
      onMapCreated: (controller) => _controller = controller,
      onTap: widget.onTap,
      onCameraMove: (pos) {
        _lastTarget = pos.target;
        widget.onCameraMove?.call(pos);
      },
      onCameraIdle: () {
        if (_lastTarget != null) {
          widget.onCameraIdle?.call(_lastTarget!);
        }
      },
      markers: widget.markers,
      myLocationButtonEnabled: widget.myLocationButtonEnabled,
      zoomControlsEnabled: widget.zoomControlsEnabled,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      tiltGesturesEnabled: true,
      rotateGesturesEnabled: true,
      gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
      },
      compassEnabled: false,
      mapToolbarEnabled: false,
    );
  }
}
