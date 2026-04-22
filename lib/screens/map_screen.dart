import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../services/quedadas_service.dart';
import '../models/quedada.dart';
import '../app_theme.dart';
import 'home/widgets/event_card.dart';

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

  // Mapa para guardar la chincheta y su ancla (Offset) exacta
  final Map<String, (BitmapDescriptor, Offset)> _markersIcons = {};
  late Stream<List<Quedada>> _quedadasStream;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _quedadasStream = _quedadasService.escucharQuedadasFuturas();
  }

  Future<void> _generateIconForEvent(Quedada q) async {
    // Si ya lo creamos antes para este evento, no lo repetimos
    if (_markersIcons.containsKey(q.id)) return;
    
    // Marcador vacío temporal
    _markersIcons[q.id] = (BitmapDescriptor.defaultMarker, const Offset(0.5, 1.0)); 

    final markerData = await _createCustomPinWithText(
      q.titulo, 
      q.esVerificado ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6), // Naranja y Azul premium
    );
    
    if (mounted) {
      setState(() {
        _markersIcons[q.id] = markerData;
      });
    }
  }

  Future<(BitmapDescriptor, Offset)> _createCustomPinWithText(String text, Color color) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // 1. Texto
    TextSpan span = TextSpan(
      style: const TextStyle(
        color: Color(0xFF1E293B),
        fontSize: 16.0,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
      text: text,
    );
    TextPainter tp = TextPainter(
      text: span,
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );
    tp.layout();

    // 2. Geometría Simétrica Segura
    // Para evitar que Google Maps "rote" o "descoloque" el ancla en Web al alejar,
    // debemos hacer que el lienzo (canvas) sea PERFECTAMENTE simétrico.
    // Así podremos usar el ancla universal por defecto: Offset(0.5, 1.0) -> Centro Abajo.
    final double paddingX = 8.0;
    final double paddingY = 4.0;
    final double pillTotalWidth = tp.width + (paddingX * 2);
    final double pinWidth = 28.0; 
    
    // Añadimos vacío a la izquierda igual a lo que ocupe la tarjeta a la derecha
    final double totalWidth = pillTotalWidth + pinWidth + pillTotalWidth;
    final double totalHeight = 50.0;

    final double pinBaseX = totalWidth / 2; // Centro matemático absoluto
    final double pinBaseY = totalHeight; // Base matemática absoluta (toca el límite inferior)

    final Paint paint = Paint()..color = color;
    Path path = Path();
    path.moveTo(pinBaseX, pinBaseY); // Punta en la base exacta
    path.quadraticBezierTo(pinBaseX - 10, pinBaseY - 18, pinBaseX - 12, pinBaseY - 26); 
    path.arcToPoint(Offset(pinBaseX + 12, pinBaseY - 26), radius: const Radius.circular(12), clockwise: true); 
    path.quadraticBezierTo(pinBaseX + 10, pinBaseY - 18, pinBaseX, pinBaseY); 

    // Pintamos la sombra ligeramente desplazada hacia arriba para que no sobrepase el lienzo
    canvas.drawShadow(path.shift(const Offset(0, -1)), Colors.black54, 4.0, false);
    canvas.drawPath(path, paint);

    // Círculo blanco central
    final double pinCentroY = pinBaseY - 26; 
    canvas.drawCircle(Offset(pinBaseX, pinCentroY), 5.5, Paint()..color = Colors.white);

    // 3. Pastilla de fondo a la derecha de la chincheta
    final double textStartX = pinBaseX + 14.0; 
    final double textY = pinCentroY - (tp.height / 2);

    final RRect textBackground = RRect.fromRectAndRadius(
      Rect.fromLTWH(textStartX, textY, pillTotalWidth, tp.height + (paddingY * 2)),
      const Radius.circular(10),
    );
    
    canvas.drawShadow(Path()..addRRect(textBackground), Colors.black26, 3.0, false);
    canvas.drawRRect(textBackground, Paint()..color = Colors.white);

    // 4. Pintar el texto
    tp.paint(canvas, Offset(textStartX + paddingX, textY + paddingY));

    // Generar imagen final
    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(totalWidth.toInt(), totalHeight.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    // Al ser el lienzo simétrico, el ancla nativa (0.5, 1.0) encajará perfectamente
    // sin crear artefactos visuales flotantes al alterar el zoom en Flutter Web.
    final Offset anchor = const Offset(0.5, 1.0);

    return (BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List()), anchor);
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
        stream: _quedadasStream,
        builder: (context, snapshot) {
          Set<Marker> markers = {};
          
          if (snapshot.hasError) {
            print('Error in StreamBuilder: ${snapshot.error}');
          }

          if (snapshot.hasData) {
            markers = snapshot.data!.map((q) {
              
              // Pedimos que se genere el icono con texto (es asíncrono)
              _generateIconForEvent(q);
              
              // Usamos el icono guardado y su ancla, o valores por defecto
              final markerData = _markersIcons[q.id];
              final BitmapDescriptor markerIcon = markerData?.$1 ?? BitmapDescriptor.defaultMarkerWithHue(
                q.esVerificado ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueBlue,
              );
              final Offset markerAnchor = markerData?.$2 ?? const Offset(0.5, 1.0);

              return Marker(
                markerId: MarkerId(q.id),
                position: LatLng(q.ubicacion.latitude, q.ubicacion.longitude),
                icon: markerIcon,
                anchor: markerAnchor,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (BuildContext context) {
                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            EventCard(
                              quedada: q,
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ),
                      );
                    },
                  );
                },
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