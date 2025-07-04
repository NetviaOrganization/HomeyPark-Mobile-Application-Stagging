import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:homeypark_mobile_application/config/constants/constants.dart';
import 'package:homeypark_mobile_application/model/parking_location.dart';
import 'package:homeypark_mobile_application/model/parking.dart';
import 'package:homeypark_mobile_application/screens/parking_detail_screen.dart';
import 'package:homeypark_mobile_application/services/parking_service.dart';
import 'package:homeypark_mobile_application/utils/user_location.dart';
import 'package:homeypark_mobile_application/widgets/navigation_menu.dart';
import 'package:homeypark_mobile_application/widgets/nearby_parking_sheet.dart';
import 'package:http/http.dart' as http;

const DEFAULT_CENTER = LatLng(DEFAULT_POSITION_MAP_LAT, DEFAULT_POSITION_MAP_LNG);

class PlacePrediction {
  final String description;
  final String placeId;
  PlacePrediction({required this.description, required this.placeId});
  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      description: json['description'],
      placeId: json['place_id'],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Completer<GoogleMapController> _controllerCompleter = Completer();
  final TextEditingController _searchQueryController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isMapLoading = true;
  LatLng _cameraCenter = DEFAULT_CENTER;
  Set<Marker> _markers = {};

  List<PlacePrediction> _predictions = [];
  bool _isSearchLoading = false;
  bool _showPredictions = false;
  Timer? _debounce;
  int _updateNearbyTrigger = 0;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchQueryController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    
    try {
      final results = await Future.wait([
        getUserLocation(),
        ParkingService.getParkingsLocations(),
      ]);

      
      
      final position = results[0] as ({double latitude, double longitude});
      final parkings = results[1] as List<ParkingLocation>;
     final userPos = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _cameraCenter = userPos;
          _markers = _buildMarkersFromLocations(parkings);
          _isMapLoading = false; // Datos listos, ocultar spinner
        });
        
        // Animamos la cámara a la posición del usuario una vez que el mapa esté listo
        final controller = await _controllerCompleter.future;
        controller.animateCamera(CameraUpdate.newLatLngZoom(userPos, 16.0));
      }
    } catch (e) {
      debugPrint("Error inicializando el mapa: $e. Cargando datos por defecto.");
      try {
        final parkings = await ParkingService.getParkingsLocations();
        if (mounted) {
          setState(() {
            _cameraCenter = DEFAULT_CENTER;
            _markers = _buildMarkersFromLocations(parkings);
            _isMapLoading = false;
          });
        }
      } catch (e2) {
        debugPrint("Error cargando parkings por defecto: $e2");
        if (mounted) {
          setState(() { _isMapLoading = false; });
        }
      }
    }
  }

Set<Marker> _buildMarkersFromLocations(List<ParkingLocation> locations) {
    return locations.where((p) => p.id != null).map((parking) => Marker(
      markerId: MarkerId('parking_${parking.id}'),
      position: LatLng(parking.latitude, parking.longitude),
      onTap: () => _navigateToParkingDetail(parking.id),
    )).toSet();
  }

  Set<Marker> _buildMarkers(List<ParkingLocation> parkings) {
    return parkings
        .where((p) => p.id != null)
        .map((parking) => Marker(
              markerId: MarkerId('parking_${parking.id}'),
              position: LatLng(parking.latitude, parking.longitude),
              onTap: () => _navigateToParkingDetail(parking.id),
            ))
        .toSet();
  }

  Future<void> _centerOnUserLocation() async {
    try {
      final position = await getUserLocation();
      final userPos = LatLng(position.latitude, position.longitude);
      final controller = await _controllerCompleter.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(userPos, 16.0));
      if (mounted) {
        setState(() {
          _cameraCenter = userPos;
          _updateNearbyTrigger++;
        });
        if (_searchQueryController.text.isNotEmpty) {
          _searchQueryController.clear();
          setState(() => _showPredictions = false);
        }
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se pudo obtener la ubicación.")));
      }
    }
  }

  Future<void> _getPlacePredictions(String input) async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (input.length < 3) {
        if (mounted) setState(() => _predictions = []);
        return;
      }
      if (mounted) setState(() => _isSearchLoading = true);
      
      final apiKey = dotenv.env['MAPS_API_KEY'] ?? '';
      final url = Uri.parse('https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&components=country:pe&language=es&types=address&key=$apiKey');

      try {
        final response = await http.get(url);
        if (mounted && response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK') {
            final predictions = (data['predictions'] as List).map((p) => PlacePrediction.fromJson(p)).toList();
            setState(() => _predictions = predictions);
          } else {
            setState(() => _predictions = []);
          }
        }
      } catch (e) {
        debugPrint("Error en predicciones de lugar: $e");
        if (mounted) setState(() => _predictions = []);
      } finally {
        if (mounted) setState(() => _isSearchLoading = false);
      }
    });
  }

  Future<void> _selectPlace(PlacePrediction prediction) async {
    _searchFocusNode.unfocus();
    setState(() {
      _showPredictions = false;
      _searchQueryController.text = prediction.description;
    });

    final apiKey = dotenv.env['MAPS_API_KEY'] ?? '';
    final url = Uri.parse('https://maps.googleapis.com/maps/api/place/details/json?place_id=${prediction.placeId}&fields=geometry,formatted_address&key=$apiKey');

    try {
      final response = await http.get(url);
      if (mounted && response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];
          final location = result['geometry']['location'];
          final newPosition = LatLng(location['lat'], location['lng']);
          final formattedAddress = result['formatted_address'];

          final controller = await _controllerCompleter.future;
          controller.animateCamera(CameraUpdate.newLatLngZoom(newPosition, 16.0));

          setState(() {
            _cameraCenter = newPosition;
            _searchQueryController.text = formattedAddress;
            _updateNearbyTrigger++;
          });
        }
      }
    } catch (e) {
      debugPrint("Error en detalles de lugar: $e");
    }
  }

  void _navigateToParkingDetail(int? parkingId) {
    if (parkingId == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => ParkingDetailScreen(parkingId: parkingId)));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
          setState(() => _showPredictions = false);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const NavigationMenu(),
        body: Stack(
          children: [
            if (_isMapLoading)
              const Center(child: CircularProgressIndicator())
            else
              GoogleMap(
                onMapCreated: (controller) {
                  if (!_controllerCompleter.isCompleted) {
                    _controllerCompleter.complete(controller);
                  }
                },
                initialCameraPosition: CameraPosition(target: _cameraCenter, zoom: 16.0),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onCameraMove: (position) {
                  _cameraCenter = position.target;
                },
                onCameraIdle: () {
                  if (mounted) {
                    setState(() => _updateNearbyTrigger++);
                  }
                },
              ),
            _buildMapUI(),
            FutureBuilder<List<Parking>>(
              key: ValueKey('parking_nearby_$_updateNearbyTrigger'),
              future: ParkingService.getNearbyParkings(_cameraCenter.latitude, _cameraCenter.longitude),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }
                return NearbyParkingSheet(
                  parkings: snapshot.data!,
                  onTapParking: (parking) => _navigateToParkingDetail(parking.id),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapUI() {
    return Stack(
      children: [
        Positioned(
          right: 15,
          bottom: MediaQuery.of(context).size.height * 0.28,
          child: FloatingActionButton(
            onPressed: _centerOnUserLocation,
            backgroundColor: Colors.white,
            mini: true,
            child: Icon(Icons.my_location, color: Theme.of(context).primaryColor),
          ),
        ),
        Positioned(
          top: 50,
          left: 15,
          right: 15,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: _showPredictions ? const BorderRadius.vertical(top: Radius.circular(12)) : BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.1), blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
                    Expanded(
                      child: TextField(
                        controller: _searchQueryController,
                        focusNode: _searchFocusNode,
                        onChanged: _getPlacePredictions,
                        onTap: () => setState(() => _showPredictions = true),
                        decoration: const InputDecoration(
                          hintText: "Buscar por dirección",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_showPredictions)
                Material(
                  color: Colors.white,
                  elevation: 4.0,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: _isSearchLoading
                        ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
                        : _predictions.isEmpty
                            ? const Padding(padding: EdgeInsets.all(16.0), child: Text("No se encontraron resultados"))
                            : ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: _predictions.length,
                                itemBuilder: (context, index) {
                                  final prediction = _predictions[index];
                                  return ListTile(
                                    title: Text(prediction.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                                    onTap: () => _selectPlace(prediction),
                                  );
                                },
                              ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}