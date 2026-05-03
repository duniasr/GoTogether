import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../services/quedadas_service.dart';
import '../models/quedada.dart';
import '../app_theme.dart';
import 'home/widgets/event_card.dart';

class MapScreen extends StatefulWidget {
  final LatLng? initialCenter;

  const MapScreen({super.key, this.initialCenter});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  final QuedadasService _quedadasService = QuedadasService();

  // Definimos las coordenadas del centro de Las Palmas por defecto
  static const LatLng _centroLasPalmas = LatLng(28.1248, -15.4300);

  late LatLng _lastKnownPosition;
  bool _isLoadingLocation = true;
  double _currentZoom = 14.0;

  // Mapa para guardar la chincheta y su ancla (Offset) exacta
  // Ahora la clave incluye el zoom para regenerar cuando cambie
  final Map<String, (BitmapDescriptor, Offset)> _markersIcons = {};
  late Stream<List<Quedada>> _quedadasStream;

  @override
  void initState() {
    super.initState();
    if (widget.initialCenter != null) {
      _lastKnownPosition = widget.initialCenter!;
      _isLoadingLocation = false;
    } else {
      _lastKnownPosition = _centroLasPalmas;
      _determinePosition();
    }
    _quedadasStream = _quedadasService.escucharQuedadasFuturas();
  }

  Future<void> _generateIconForEvent(Quedada q, double zoom) async {
    // Usamos una clave que dependa del zoom (redondeado para no regenerar en exceso)
    final String cacheKey = "${q.id}_${zoom.round()}";
    
    if (_markersIcons.containsKey(cacheKey)) return;

    // Marcador vacío temporal para evitar llamadas múltiples
    _markersIcons[cacheKey] = (
      BitmapDescriptor.defaultMarker,
      const Offset(0.5, 1.0),
    );

    final markerData = await _createCustomPinWithText(
      q.titulo,
      q.esVerificado
          ? const Color(0xFFF59E0B)
          : const Color(0xFF1C63A6), // Naranja y Azul premium
      zoom,
    );

    if (mounted) {
      setState(() {
        _markersIcons[cacheKey] = markerData;
      });
    }
  }

  Future<(BitmapDescriptor, Offset)> _createCustomPinWithText(
    String text,
    Color color,
    double zoom,
  ) async {
    // Escala mucho más agresiva porque el usuario los sigue viendo pequeños
    // Base 2.8 en zoom 14.
    double scale = 2.8; 
    if (zoom > 14) {
      // Al acercarnos, reducimos pero mantenemos un tamaño mínimo generoso
      scale = 2.8 - (zoom - 14) * 0.25;
    } else if (zoom < 14) {
      // Al alejarnos, los hacemos gigantes para que se vean bien
      scale = 2.8 + (14 - zoom) * 0.4;
    }
    scale = scale.clamp(1.0, 6.0); // Tamaño mínimo 1.0, máximo 6.0

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // 1. Texto (escalado)
    TextSpan span = TextSpan(
      style: TextStyle(
        color: const Color(0xFF1E293B),
        fontSize: 18.0 * scale, // Aumentado de 16 a 18 base
        fontWeight: FontWeight.w900, // Más negrita aún
        letterSpacing: -0.2 * scale,
      ),
      text: text,
    );
    TextPainter tp = TextPainter(
      text: span,
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );
    tp.layout();

    // 2. Geometría (escalada)
    final double paddingX = 10.0 * scale; // Más padding
    final double paddingY = 6.0 * scale;
    final double pillTotalWidth = tp.width + (paddingX * 2);
    final double pinWidth = 32.0 * scale; // Pin más ancho

    final double totalWidth = pillTotalWidth + pinWidth + pillTotalWidth;
    final double totalHeight = 85.0 * scale; // Base 85 en lugar de 60

    final double pinBaseX = totalWidth / 2;
    final double pinBaseY = totalHeight;

    final Paint paint = Paint()..color = color;
    Path path = Path();
    path.moveTo(pinBaseX, pinBaseY);
    path.quadraticBezierTo(
      pinBaseX - (12 * scale),
      pinBaseY - (22 * scale),
      pinBaseX - (15 * scale),
      pinBaseY - (32 * scale),
    );
    path.arcToPoint(
      Offset(pinBaseX + (15 * scale), pinBaseY - (32 * scale)),
      radius: Radius.circular(15 * scale),
      clockwise: true,
    );
    path.quadraticBezierTo(pinBaseX + (12 * scale), pinBaseY - (22 * scale), pinBaseX, pinBaseY);

    canvas.drawShadow(
      path.shift(Offset(0, -1 * scale)),
      Colors.black87, // Sombra más fuerte
      6.0 * scale,
      false,
    );
    canvas.drawPath(path, paint);

    // Círculo blanco central (más grande)
    final double pinCentroY = pinBaseY - (32 * scale);
    canvas.drawCircle(
      Offset(pinBaseX, pinCentroY),
      7.0 * scale,
      Paint()..color = Colors.white,
    );

    // 3. Pastilla de fondo
    final double textStartX = pinBaseX + (18.0 * scale);
    final double textY = pinCentroY - (tp.height / 2);

    final RRect textBackground = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        textStartX,
        textY,
        pillTotalWidth,
        tp.height + (paddingY * 2),
      ),
      Radius.circular(12 * scale),
    );

    canvas.drawShadow(
      Path()..addRRect(textBackground),
      Colors.black45,
      5.0 * scale,
      false,
    );
    canvas.drawRRect(textBackground, Paint()..color = Colors.white);

    // 4. Pintar el texto
    tp.paint(canvas, Offset(textStartX + paddingX, textY + paddingY));

    // Generar imagen final
    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(
      totalWidth.toInt().clamp(1, 4000), // Aumentado límite
      totalHeight.toInt().clamp(1, 4000),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

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
      appBar: widget.initialCenter != null
          ? AppBar(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              title: const Text('Location on Map', style: AppTextStyles.headlineSmall),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
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
              _generateIconForEvent(q, _currentZoom);

              // Usamos el icono guardado y su ancla, o valores por defecto
              final String cacheKey = "${q.id}_${_currentZoom.round()}";
              final markerData = _markersIcons[cacheKey];
              final BitmapDescriptor markerIcon =
                  markerData?.$1 ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    q.esVerificado
                        ? BitmapDescriptor.hueOrange
                        : BitmapDescriptor.hueBlue,
                  );
              final Offset markerAnchor =
                  markerData?.$2 ?? const Offset(0.5, 1.0);

              return Marker(
                markerId: MarkerId(q.id),
                position: LatLng(q.ubicacion.latitude, q.ubicacion.longitude),
                icon: markerIcon,
                anchor: markerAnchor,
                onTap: () => _mostrarDetallesEvento(q.id),
              );
            }).toSet();
          }

          return GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _lastKnownPosition,
              zoom: _currentZoom,
            ),
            markers: markers,
            onCameraMove: (position) {
              if ((position.zoom - _currentZoom).abs() > 0.5) {
                setState(() {
                  _currentZoom = position.zoom;
                });
              }
            },
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

  void _mostrarDetallesEvento(String eventId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('events').doc(eventId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const SizedBox.shrink();
            if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();

            final q = Quedada.fromFirestore(snapshot.data!);
            final uid = FirebaseAuth.instance.currentUser?.uid;
            final email = FirebaseAuth.instance.currentUser?.email;
            final isOrganizer = (uid != null && uid == q.organizadorId) ||
                                uid == q.organizador ||
                                email == q.organizador;
            final isJoined = (uid != null && q.asistentesID.contains(uid)) || isOrganizer;

            return Container(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tirador para el modal
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  EventCard(
                    quedada: q,
                    isJoined: isJoined,
                    actionButton: isJoined
                        ? (isOrganizer
                            ? null
                            : ElevatedButton(
                                onPressed: () async {
                                  final confirmar = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Leave event'),
                                      content: Text('Are you sure you want to leave "${q.titulo}"?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(ctx).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                                          onPressed: () => Navigator.of(ctx).pop(true),
                                          child: const Text('Leave'),
                                        ),
                                      ],
                                    ),
                                  ) ?? false;

                                  if (!confirmar) return;

                                  try {
                                    await _quedadasService.abandonarQuedada(q.id);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('You have left the plan.')),
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error leaving: $e')),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error.withOpacity(0.1),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                ),
                                child: Text('Leave', style: AppTextStyles.button.copyWith(color: AppColors.error)),
                              ))
                        : ElevatedButton(
                            onPressed: (q.plazasLibres > 0 && q.estado == 'abierta')
                                ? () async {
                                    try {
                                      await _quedadasService.unirseAQuedada(q.id);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('You have joined the plan!'), backgroundColor: Colors.green),
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error joining: $e')),
                                      );
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor: AppColors.error.withOpacity(0.1),
                              disabledForegroundColor: AppColors.error,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              (q.plazasLibres > 0 && q.estado == 'abierta')
                                  ? 'Join'
                                  : (q.estado == 'cerrada' ? 'Closed' : 'Full'),
                              style: AppTextStyles.button.copyWith(color: (q.plazasLibres > 0 && q.estado == 'abierta') ? Colors.white : AppColors.error),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
