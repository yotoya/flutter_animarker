import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animarker/flutter_map_marker_animation.dart';
import 'package:flutter_animarker/lat_lng_interpolation.dart';
import 'package:flutter_animarker/models/lat_lng_delta.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'extensions.dart';

const startPosition = LatLng(18.488213, -69.959186);

class FlutterMapMarkerAnimationRealTimeExample extends StatefulWidget {
  @override
  _FlutterMapMarkerAnimationExampleState createState() =>
      _FlutterMapMarkerAnimationExampleState();
}

class _FlutterMapMarkerAnimationExampleState extends State<FlutterMapMarkerAnimationRealTimeExample> {

  //Markers collection, proper way
  final Map<MarkerId, Marker> _markers = Map<MarkerId, Marker>();

  MarkerId sourceId = MarkerId("SourcePin");
  MarkerId source2Id = MarkerId("SourcePin2");
  MarkerId source3Id = MarkerId("SourcePin3");

  LatLngInterpolationStream _latLngStream = LatLngInterpolationStream();

  StreamGroup<LatLngDelta> subscriptions = StreamGroup<LatLngDelta>();

  StreamSubscription<Position> positionStream;

  final Completer<GoogleMapController> _controller = Completer();

  final CameraPosition _kSantoDomingo = CameraPosition(
    target: startPosition,
    zoom: 15,
  );

  @override
  void initState() {

    subscriptions.add(_latLngStream.getAnimatedPosition(sourceId.value));
    subscriptions.add(_latLngStream.getAnimatedPosition(source2Id.value));
    subscriptions.add(_latLngStream.getAnimatedPosition(source3Id.value));

    subscriptions.stream.listen((LatLngDelta delta) {
      //Update the marker with animation
      setState(() {
        var markerId = MarkerId(delta.markerId);
        Marker sourceMarker = Marker(
          markerId: markerId,
          rotation: delta.rotation,
          position: LatLng(
            delta.from.latitude,
            delta.from.longitude,
          ),
        );
        _markers[markerId] = sourceMarker;

      });
    });

    positionStream = Geolocator.getPositionStream(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 10,
    ).listen((Position position) {
      double latitude = position.latitude;
      double longitude = position.longitude;

      //Push new location changes
      _latLngStream.addLatLng(LatLngInfo(latitude, longitude, sourceId.value));
      _latLngStream.addLatLng(LatLngInfo(latitude+0.1, longitude+0.1, source2Id.value));
      _latLngStream.addLatLng(LatLngInfo(latitude+0.2, longitude+0.2, source3Id.value));
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Maps Markers Animation Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        body: SafeArea(
          child: GoogleMap(
            mapType: MapType.normal,
            markers: Set<Marker>.of(_markers.values),
            initialCameraPosition: _kSantoDomingo,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              setState(() {
                Marker sourceMarker = Marker(
                  markerId: sourceId,
                  position: startPosition,
                );
                _markers[sourceId] = sourceMarker;

                Marker source2Marker = Marker(
                  markerId: source2Id,
                  position: startPosition,
                );
                _markers[source2Id] = source2Marker;


                Marker source3Marker = Marker(
                  markerId: source3Id,
                  position: startPosition,
                );
                _markers[source3Id] = source3Marker;
              });

              _latLngStream.addLatLng(startPosition.toLatLngInfo(sourceId.value));
              _latLngStream.addLatLng(startPosition.toLatLngInfo(source2Id.value));
              _latLngStream.addLatLng(startPosition.toLatLngInfo(source3Id.value));
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    subscriptions.close();
    positionStream.cancel();
    super.dispose();
  }
}