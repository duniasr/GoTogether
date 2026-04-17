import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/quedadas_service.dart';
import '../models/quedada.dart';
import '../app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  final QuedadasService _quedadasService = QuedadasService();
  
  // Definimos las coordenadas del centro de Las Palmas por defecto
  static const LatLng _centroLasPalmas = LatLng(28.1248, -15.4300);
  
  LatLng _lastKnownPosition = _centroLasPalmas;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  /// Determina la posición actual del usuario y centra el mapa.
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si el servicio de ubicación está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _isLoadingLocation = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _isLoadingLocation = false);
      return;
    } 

    // Obtener posición actual
    try {
      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _lastKnownPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        // Si el controlador ya está listo, movemos la cámara
        _mapController.animateCamera(
          CameraUpdate.newLatLngZoom(_lastKnownPosition, 14.0),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Si ya tenemos la posición al crear el mapa, nos centramos
    if (!_isLoadingLocation) {
      _mapController.moveCamera(
        CameraUpdate.newLatLngZoom(_lastKnownPosition, 14.0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Quedada>>(
        stream: _quedadasService.escucharQuedadasFuturas(),
        builder: (context, snapshot) {
          Set<Marker> markers = {};
          
          if (snapshot.hasError) {
            print('Error in StreamBuilder: ${snapshot.error}');
          }

          if (snapshot.hasData) {
            markers = snapshot.data!.map((q) {
              return Marker(
                markerId: MarkerId(q.id),
                position: LatLng(q.ubicacion.latitude, q.ubicacion.longitude),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  q.esVerificado ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueBlue,
                ),
                infoWindow: InfoWindow(
                  title: q.titulo,
                  snippet: 'By: ${q.organizador}',
                ),
              );
            }).toSet();
          }

          return GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _lastKnownPosition,
              zoom: 14.0,
            ),
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: true,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _determinePosition,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}