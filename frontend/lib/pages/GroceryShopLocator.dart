import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class GroceryShopLocator extends StatefulWidget {
  const GroceryShopLocator({super.key});

  @override
  _GroceryShopLocatorState createState() => _GroceryShopLocatorState();
}

class _GroceryShopLocatorState extends State<GroceryShopLocator> {
  final TextEditingController _locationController = TextEditingController();
  final String _apiKey = 'AIzaSyB35FpbKNByelQDc_uV64iYfBeBHkNak2U';
  late GoogleMapController _mapController;
  LocationData? _currentLocation;
  final Location _locationService = Location();
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<dynamic> _nearbyShops = [];
  LatLng? _selectedLocation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      _currentLocation = await _locationService.getLocation();
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          14,
        ),
      );
      _findNearbyShops(_currentLocation!.latitude!, _currentLocation!.longitude!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _findNearbyShops(double lat, double lng) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=1500&type=grocery_or_supermarket&key=$_apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _nearbyShops = data['results'];
          _updateMarkers();
        });
      } else {
        throw Exception('Failed to load nearby shops');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error finding shops: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateMarkers() {
    _markers.clear();
    
    // Add current location marker
    if (_currentLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Add shop markers
    for (var shop in _nearbyShops) {
      final lat = shop['geometry']['location']['lat'];
      final lng = shop['geometry']['location']['lng'];
      
      _markers.add(
        Marker(
          markerId: MarkerId(shop['place_id']),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: shop['name'],
            snippet: shop['vicinity'],
          ),
          onTap: () {
            setState(() => _selectedLocation = LatLng(lat, lng));
          },
        ),
      );
    }
  }

// Future<void> _getDirections() async {
//   if (_currentLocation == null || _selectedLocation == null) return;

//   setState(() => _isLoading = true);
//   try {
//     final polylinePoints = PolylinePoints();
//     final result = await polylinePoints.getRouteBetweenCoordinates(
//       request: PolylineRequest(
//         origin: PointLatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
//         destination: PointLatLng(_selectedLocation!.latitude, _selectedLocation!.longitude),
//         mode: TravelMode.driving, // You can specify travel mode (e.g., TravelMode.walking)
//       ),
//       googleApiKey: _apiKey,
//     );

//     if (result.points.isNotEmpty) {
//       _polylines.clear();
//       _polylines.add(
//         Polyline(
//           polylineId: const PolylineId('directions'),
//           color: Colors.blue,
//           width: 5,
//           points: result.points
//               .map((point) => LatLng(point.latitude, point.longitude))
//               .toList(),
//         ),
//       );

//       final bounds = LatLngBounds(
//         southwest: LatLng(
//           min(_currentLocation!.latitude!, _selectedLocation!.latitude),
//           min(_currentLocation!.longitude!, _selectedLocation!.longitude),
//         ),
//         northeast: LatLng(
//           max(_currentLocation!.latitude!, _selectedLocation!.latitude),
//           max(_currentLocation!.longitude!, _selectedLocation!.longitude),
//         ),
//       );

//       _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No route found')),
//       );
//     }
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Error getting directions: $e')),
//     );
//   } finally {
//     setState(() => _isLoading = false);
//   }
// }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery Shop Locator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'Enter location or use current',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onSubmitted: (value) async {
                      if (value.isEmpty) return;
                      
                      setState(() => _isLoading = true);
                      try {
                        final response = await http.get(
                          Uri.parse(
                            'https://maps.googleapis.com/maps/api/geocode/json?address=$value&key=$_apiKey',
                          ),
                        );

                        if (response.statusCode == 200) {
                          final data = json.decode(response.body);
                          if (data['results'].isNotEmpty) {
                            final location = data['results'][0]['geometry']['location'];
                            final lat = location['lat'];
                            final lng = location['lng'];
                            
                            _mapController.animateCamera(
                              CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14),
                            );
                            _findNearbyShops(lat, lng);
                          }
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error searching location: $e')),
                        );
                      } finally {
                        setState(() => _isLoading = false);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: (controller) => _mapController = controller,
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(0, 0), // Will be updated with real location
                    zoom: 14,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  compassEnabled: true,
                ),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}