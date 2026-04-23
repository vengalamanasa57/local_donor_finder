// ============================================================
// LOCAL DONOR FINDER — sos_map_screen.dart  (FIXED)
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class SOSMapScreen extends StatefulWidget {
  const SOSMapScreen({super.key});

  @override
  State<SOSMapScreen> createState() => _SOSMapScreenState();
}

class _SOSMapScreenState extends State<SOSMapScreen> {
  // ── Map controller ─────────────────────────────────────────
  final Completer<GoogleMapController> _mapControllerCompleter =
      Completer<GoogleMapController>();

  // ── Marker set ─────────────────────────────────────────────
  final Set<Marker> _markers = {};

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(17.3850, 78.4867), // Hyderabad
    zoom: 12.0,
  );

  bool _hasMovedCameraToData = false;

  late final Stream<QuerySnapshot> _emergenciesStream;

  @override
  void initState() {
    super.initState();
    _emergenciesStream = FirebaseFirestore.instance
        .collection('emergencies')
        .where('status', isEqualTo: 'active')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Set<Marker> _buildMarkersFromSnapshot(QuerySnapshot snapshot) {
    final Set<Marker> newMarkers = {};

    for (final doc in snapshot.docs) {
  final data = doc.data() as Map<String, dynamic>;
  final geoPoint = data['location'] as GeoPoint;
  final name = data['patientName'] ?? data['name'] ?? 'Unknown';
  final bloodType = data['bloodType'] ?? '?';

  final phone = data['phoneNumber'] ?? doc['phone']?? ''; 

  newMarkers.add(Marker(
    markerId: MarkerId(doc.id),
    position: LatLng(geoPoint.latitude, geoPoint.longitude),
    infoWindow: InfoWindow(
      title: '$name  ·  $bloodType',
      snippet: 'Active SOS request',
      onTap: () => _onMarkerInfoTapped(doc.id, name, bloodType, phone,geoPoint.latitude,
  geoPoint.longitude),
    ),
    onTap: () => _onMarkerInfoTapped(doc.id, name, bloodType, phone,geoPoint.latitude,
  geoPoint.longitude),
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
  ));
}

    return newMarkers;
  }

  Future<void> _moveCameraToFirstMarker(QuerySnapshot snapshot) async {
    if (_hasMovedCameraToData) return;
    if (snapshot.docs.isEmpty) return;

    final data = snapshot.docs.first.data() as Map<String, dynamic>;
    final geoPoint = data['location'];
    if (geoPoint == null || geoPoint is! GeoPoint) return;

    // Only set the flag AFTER we know there's valid data
    _hasMovedCameraToData = true;

    // Await the controller — safe even if the map isn't ready yet.
    // The Completer will resolve once onMapCreated fires.
    final controller = await _mapControllerCompleter.future;

    // Guard against the widget being disposed while we awaited
    if (!mounted) return;

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(geoPoint.latitude, geoPoint.longitude),
          zoom: 13.0,
        ),
      ),
    );
  }

  Future<void> _animateCameraTo(LatLng target, {double zoom = 15.0}) async {
    final controller = await _mapControllerCompleter.future;
    if (!mounted) return;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  void _onMarkerInfoTapped(String docId, String name, String bloodType, String phone, double lat, double lng) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _MarkerDetailSheet(
      docId: docId,
      name: name,
      bloodType: bloodType,
      phone: phone,
      lat: lat,
      lng: lng,
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('SOS Map',
            style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: _emergenciesStream,
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$count active',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ),
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _emergenciesStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final updatedMarkers =
                _buildMarkersFromSnapshot(snapshot.data!);

            // Only call setState if the marker set actually changed
            if (!_setEquals(_markers, updatedMarkers)) {
              // Schedule after build — safe way to call setState
              // from inside a build method
              Future.microtask(() {
                if (mounted) {
                  setState(() {
                    _markers
                      ..clear()
                      ..addAll(updatedMarkers);
                  });
                }
              });
            }

            // Move camera to data on first load only (Bug 3 fix)
            _moveCameraToFirstMarker(snapshot.data!);
          }

          return Stack(
            children: [
              GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  if (!_mapControllerCompleter.isCompleted) {
                    _mapControllerCompleter.complete(controller);
                  }
                },
                initialCameraPosition: _defaultPosition,

                markers: _markers,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: true,
                myLocationEnabled: false,
              ),

              // Loading overlay — first load only
              if (snapshot.connectionState == ConnectionState.waiting &&
                  _markers.isEmpty)
                Container(
                  color: Colors.white.withOpacity(0.6),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFC62828)),
                        SizedBox(height: 12),
                        Text('Loading SOS requests...',
                            style: TextStyle(
                              color: Color(0xFFC62828),
                              fontWeight: FontWeight.w500,
                            )),
                      ],
                    ),
                  ),
                ),

              // Error banner
              if (snapshot.hasError)
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Error loading markers: ${snapshot.error}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ),

              // Legend pill
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_pin,
                            color: Color(0xFFC62828), size: 18),
                        SizedBox(width: 6),
                        Text('Tap a pin to see donor info',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'my_location',
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFFC62828),
            onPressed: () => _animateCameraTo(
              const LatLng(17.3850, 78.4867),
              zoom: 12.0,
            ),
            tooltip: 'Reset to Hyderabad',
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'fit_markers',
            backgroundColor: const Color(0xFFC62828),
            foregroundColor: Colors.white,
            onPressed: _fitAllMarkers,
            tooltip: 'Show all SOS requests',
            child: const Icon(Icons.zoom_out_map),
          ),
        ],
      ),
    );
  }
  bool _setEquals(Set<Marker> a, Set<Marker> b) {
    if (a.length != b.length) return false;
    final aIds = a.map((m) => m.markerId.value).toSet();
    final bIds = b.map((m) => m.markerId.value).toSet();
    return aIds.containsAll(bIds);
  }

  Future<void> _fitAllMarkers() async {
    if (_markers.isEmpty) return;
    final controller = await _mapControllerCompleter.future;
    if (!mounted) return;

    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;

    for (final marker in _markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80.0,
      ),
    );
  }
}

// ============================================================
// _MarkerDetailSheet — bottom sheet on marker tap
// ============================================================

class _MarkerDetailSheet extends StatelessWidget {
  final String docId;
  final String name;
  final String bloodType;
  final String phone;
  final double lat; 
  final double lng;

  const _MarkerDetailSheet({
    super.key,
    required this.docId,
    required this.name,
    required this.bloodType,
    required this.phone,
    required this.lat,
    required this.lng,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFFFEBEE),
                child: Text(bloodType,
                    style: const TextStyle(
                      color: Color(0xFFC62828),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    )),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('Active SOS · $bloodType needed',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // --- DIRECTIONS BUTTON ---
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text('Directions'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC62828),
                    side: const BorderSide(color: Color(0xFFC62828)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
            final String googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
          final Uri mapUri = Uri.parse(googleMapsUrl);
  
        if (await canLaunchUrl(mapUri)) {
        await launchUrl(mapUri, mode: LaunchMode.externalApplication);
        }
        },
                ),
              ),
              const SizedBox(width: 12),
              
              // I Can Help Button .....
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No phone number provided'))
                      );
                      return;
                    }

                    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
                    if (await canLaunchUrl(phoneUri)) {
                      await launchUrl(phoneUri);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Connecting you to $name...'),
                          backgroundColor: const Color(0xFFC62828),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.favorite, size: 18),
                  label: const Text('I Can Help'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC62828),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
