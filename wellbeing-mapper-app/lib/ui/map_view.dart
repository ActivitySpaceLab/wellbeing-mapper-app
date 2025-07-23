import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:flutter_map/flutter_map.dart';
//import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

class MapView extends StatefulWidget {
  @override
  State createState() => MapViewState();
}

class MapViewState extends State<MapView>
    with AutomaticKeepAliveClientMixin<MapView> {
  @override
  bool get wantKeepAlive {
    return true;
  }

  late bg.Location _stationaryLocation;

  List<CircleMarker> _currentPosition = [];
  List<LatLng> _polyline = [];
  List<CircleMarker> _locations = [];
  List<CircleMarker> _stopLocations = [];
  List<Polyline> _motionChangePolylines = [];
  List<CircleMarker> _stationaryMarker = [];

  LatLng _center = new LatLng(51.5, -0.09);
  late MapController _mapController;
  late MapOptions _mapOptions;

  @override
  void initState() {
    super.initState();
    _mapOptions = new MapOptions(
      onMapEvent: _onPositionChanged, // Changed from onPositionChanged
      initialCenter: _center, // Changed from center
      initialZoom: 16.0,
    );
    _mapController = new MapController();

    bg.BackgroundGeolocation.onLocation(_onLocation);
    bg.BackgroundGeolocation.onMotionChange(_onMotionChange);
    bg.BackgroundGeolocation.onEnabledChange(_onEnabledChange);

    // Replace onReady with a different initialization approach
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _displayStoredLocations();
    });
  }

  void _displayStoredLocations() async {
    List allLocations = await bg.BackgroundGeolocation.locations;
    for (var thisLocation in allLocations) {
      _onLocation(bg.Location(thisLocation));
    }
  }

  void _onEnabledChange(bool enabled) {
    if (!enabled) {
//      _locations.clear();
//      _polyline.clear();
//      _stopLocations.clear();
//      _motionChangePolylines.clear();
      //     _stationaryMarker.clear();
    }
  }

  void _onMotionChange(bg.Location location) async {
    LatLng ll = new LatLng(location.coords.latitude, location.coords.longitude);

    _updateCurrentPositionMarker(ll);

    _mapController.move(ll, _mapOptions.initialZoom);

    // clear the big red stationaryRadius circle.
    _stationaryMarker.clear();

    if (location.isMoving) {
      //if (_stationaryLocation == null) { //TODO: The operand can't be null, so the condition is always false
      _stationaryLocation = location;
      //}
      // Add previous stationaryLocation as a small red stop-circle.
      _stopLocations.add(_buildStopCircleMarker(_stationaryLocation));
      // Create the green motionchange polyline to show where tracking engaged from.
      _motionChangePolylines
          .add(_buildMotionChangePolyline(_stationaryLocation, location));
    } else {
      // Save a reference to the location where we became stationary.
      _stationaryLocation = location;
      // Add the big red stationaryRadius circle.

      // TAKING THIS OUT FOR NOW
      //      bg.State state = await bg.BackgroundGeolocation.state;
      //     _stationaryMarker.add(_buildStationaryCircleMarker(location, state));
    }
  }

  void _onLocation(bg.Location location) {
    LatLng ll = new LatLng(location.coords.latitude, location.coords.longitude);
    // Only move if controller is ready
    if (_mapController != null) {
      _mapController.move(ll, _mapOptions.initialZoom);
    }
    print('hee 2');
    _updateCurrentPositionMarker(ll);

    if (location.sample == true) {
      return;
    }

    // Add a point to the tracking polyline.
    _polyline.add(ll);
    // Add a marker for the recorded location.
    //_locations.add(_buildLocationMarker(location));
    _locations.add(CircleMarker(point: ll, color: Colors.black, radius: 5.0));

    _locations.add(CircleMarker(point: ll, color: Colors.blue, radius: 4.0));
  }

  /// Update Big Blue current position dot.
  void _updateCurrentPositionMarker(LatLng ll) {
    _currentPosition.clear();

    // White background
    _currentPosition
        .add(CircleMarker(point: ll, color: Colors.white, radius: 10));
    // Blue foreground
    _currentPosition
        .add(CircleMarker(point: ll, color: Colors.blue, radius: 7));
  }

  /*CircleMarker _buildStationaryCircleMarker(
      bg.Location location, bg.State state) {
    return new CircleMarker(
        point: LatLng(location.coords.latitude, location.coords.longitude),
        color: Color.fromRGBO(255, 0, 0, 0.5),
        useRadiusInMeter: true,
        radius: (state.trackingMode == 1)
            ? 200
            : (state.geofenceProximityRadius! / 2));
  }*/

  Polyline _buildMotionChangePolyline(bg.Location from, bg.Location to) {
    return new Polyline(points: [
      LatLng(from.coords.latitude, from.coords.longitude),
      LatLng(to.coords.latitude, to.coords.longitude)
    ], strokeWidth: 10.0, color: Color.fromRGBO(22, 190, 66, 0.7));
  }

  CircleMarker _buildStopCircleMarker(bg.Location location) {
    return new CircleMarker(
        point: LatLng(location.coords.latitude, location.coords.longitude),
        color: Color.fromRGBO(200, 0, 0, 0.3),
        useRadiusInMeter: false,
        radius: 20);
  }

  //void _onPositionChanged(MapPosition pos, bool hasGesture) {
  //   _mapOptions.crs.scale(_mapController.zoom);
  // }

  void _onPositionChanged(MapEvent event) {
    if (event is MapEventMove) {
      _mapOptions.crs
          .scale(event.camera.zoom); // Use camera.zoom instead of zoom
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FlutterMap(
      mapController: _mapController,
      options: _mapOptions,
      children: [
        TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c']),
        if (_polyline.isNotEmpty)
          PolylineLayer(
            polylines: [
              new Polyline(
                points: _polyline,
                strokeWidth: 10.0,
                color: Color.fromRGBO(0, 179, 253, 0.8),
              ),
            ],
          ),
        // Big red stationary radius while in stationary state.
        if (_stationaryMarker.isNotEmpty)
          CircleLayer(circles: _stationaryMarker),
        // Polyline joining last stationary location to motionchange:true location.
        if (_motionChangePolylines.isNotEmpty)
          PolylineLayer(polylines: _motionChangePolylines),
        // Recorded locations.
        if (_locations.isNotEmpty) CircleLayer(circles: _locations),
        // Small, red circles showing where motionchange:false events fired.
        if (_stopLocations.isNotEmpty) CircleLayer(circles: _stopLocations),
        if (_currentPosition.isNotEmpty) CircleLayer(circles: _currentPosition),
      ],
    );
  }
}
