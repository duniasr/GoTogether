import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;

  // Coordenadas del centro de Las Palmas de Gran Canaria
  final LatLng _centroLasPalmas = const LatLng(28.1248, -15.4300);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _centroLasPalmas,
          zoom: 14.0, // Nivel de zoom inicial 
        ),
        // Vamos a poner un pin de prueba para ver que funciona
        markers: {
          const Marker(
            markerId: MarkerId('marcador_prueba'),
            position: LatLng(28.1350, -15.4320), // Por la zona de Las Canteras
            infoWindow: InfoWindow(
              title: 'Your first pin!',
              snippet: 'The map works perfectly.',
            ),
          ),
        },
      ),
    );
  }
}