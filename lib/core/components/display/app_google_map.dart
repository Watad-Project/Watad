import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  @override
  State<AppGoogleMap> createState() => _AppGoogleMapState();
}

class _AppGoogleMapState extends State<AppGoogleMap> {
  GoogleMapController? _controller;
  LatLng? _lastTarget;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
