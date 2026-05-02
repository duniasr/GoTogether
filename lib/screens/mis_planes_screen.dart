import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/quedada.dart';
import '../services/quedadas_service.dart';
import 'home/widgets/create_event_dialog.dart';
import '../utils/translations.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'home/widgets/location_picker_screen.dart';
import '../widgets/date_time_picker.dart';
import 'home/widgets/event_card.dart';

class MisPlanesScreen extends StatefulWidget {
  const MisPlanesScreen({super.key});

  @override
  State<MisPlanesScreen> createState() => _MisPlanesScreenState();
}

class _MisPlanesScreenState extends State<MisPlanesScreen> {
  final _service = QuedadasService();
  // Streams para mantener la pantalla actualizada si hay cambios en base de datos
  late final Stream<List<Quedada>> _creadosStream;
  late final Stream<List<Quedada>> _unidosStream;

  @override
  void initState() {
    super.initState();
    _creadosStream = _service.escucharMisQuedadas();
    _unidosStream = _service.escucharQuedadasUnidas();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Dos pestañas: "Creados" y "Unidos"
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF12467A), // AppColors.primaryDark
                      AppColors.primary,
                      Color(0xFF2E85D4), // Slightly lighter blue
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.sm,
                      ),
                      child: Text(
                        'My Plans',
                        style: AppTextStyles.displayMedium.copyWith(color: Colors.white),
                      ),
                    ),
                    const TabBar(
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(text: 'Created'),
                        Tab(text: 'Joined'),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _PlanesTab(
                      stream: _creadosStream,
                      service: _service,
                      esCreador: true,
                      textoVacio: 'You haven\'t created any plans yet',
                    ),
                    _PlanesTab(
                      stream: _unidosStream,
                      service: _service,
                      esCreador: false,
                      textoVacio: 'You haven\'t joined any plans yet',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanesTab extends StatefulWidget {
  final Stream<List<Quedada>> stream;
  final QuedadasService service;
  final bool esCreador;
  final String textoVacio;

  const _PlanesTab({
    required this.stream,
    required this.service,
    required this.esCreador,
    required this.textoVacio,
  });

  @override
  State<_PlanesTab> createState() => _PlanesTabState();
}

class _PlanesTabState extends State<_PlanesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Llama al servicio para borrar este evento que hemos creado
  Future<void> _eliminar(BuildContext context, Quedada q) async {
    final confirmar =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            title: const Text('Delete plan'),
            content: Text(
              'Are you sure you want to delete "${q.titulo}"?\nThis action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmar) return;

    try {
      await widget.service.eliminarQuedada(q.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Plan deleted.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Nos desapunta de un evento creado por otra persona
  Future<void> _abandonar(BuildContext context, Quedada q) async {
    final confirmar =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            title: const Text('Leave plan'),
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
        ) ??
        false;

    if (!confirmar) return;

    try {
      await widget.service.abandonarQuedada(q.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You have left the plan.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _editar(BuildContext context, Quedada q) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => _EditDialog(
        quedada: q,
        service: widget.service,
        messenger: messenger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<List<Quedada>>(
      stream: widget.stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final planes = snap.data ?? [];
        if (planes.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_busy_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(widget.textoVacio, style: AppTextStyles.bodyMedium),
              ],
            ),
          );
        }

        final now = DateTime.now();
        final activePlanes = planes.where((q) => q.fechaFin.isAfter(now)).toList();
        final pastPlanes = planes.where((q) => q.fechaFin.isBefore(now) || q.fechaFin.isAtSameMomentAs(now)).toList();

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final q = activePlanes[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: EventCard(
                        quedada: q,
                        isJoined: true,
                        onDelete: widget.esCreador ? () => _eliminar(context, q) : null,
                        actionButton: ElevatedButton(
                          onPressed: widget.esCreador
                              ? () => _editar(context, q)
                              : () => _abandonar(context, q),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.esCreador
                                ? AppColors.primary
                                : AppColors.error.withOpacity(0.12),
                            foregroundColor: widget.esCreador
                                ? Colors.white
                                : AppColors.error,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            widget.esCreador ? 'Modify' : 'Leave',
                            style: AppTextStyles.button.copyWith(
                              color: widget.esCreador ? Colors.white : AppColors.error,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: activePlanes.length,
                ),
              ),
            ),
            if (pastPlanes.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                  child: Text(
                    'Past Plans',
                    style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            if (pastPlanes.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final q = pastPlanes[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Opacity(
                          opacity: 0.65,
                          child: EventCard(
                            quedada: q,
                            isJoined: true,
                            onDelete: null,
                            actionButton: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: const Text(
                                'Past Event (Read Only)',
                                style: TextStyle(color: AppColors.textHint, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: pastPlanes.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EditDialog extends StatefulWidget {
  final Quedada quedada;
  final QuedadasService service;
  final ScaffoldMessengerState messenger;

  const _EditDialog({
    required this.quedada,
    required this.service,
    required this.messenger,
  });

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  static const _tematicas = [
    'Deporte',
    'Naturaleza',
    'Estudio',
    'Ocio',
    'Cultura',
    'Gastronomía',
    'Fiesta',
    'Voluntariado',
    'Viajes',
    'Videojuegos',
    'Música',
    'Networking',
    'Otros',
  ];
  static const _estados = ['abierta', 'cerrada', 'cancelada'];

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titulo;
  late final TextEditingController _descripcion;
  late final TextEditingController _cupo;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lonCtrl;
  late final TextEditingController _direccionCtrl;

  late String _tematica;
  late String _estado;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _guardando = false;
  String? _errorMessage;
  String? _successMessage;

  int get _asistentesActuales => widget.quedada.asistentesID.length;

  Future<String?> _fallbackGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon');
      final response = await http.get(url, headers: {'User-Agent': 'GoTogetherApp_FallbackGeocoding'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null) {
          final addr = data['address'] ?? {};
          final exactName = data['name'] ?? '';
          final road = addr['road'] ?? addr['pedestrian'] ?? addr['path'] ?? addr['suburb'] ?? '';
          final houseNumber = addr['house_number'] ?? '';
          final city = addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['municipality'] ?? '';

          final parts = <String>[];
          if (exactName.toString().isNotEmpty) {
            parts.add(exactName.toString());
          } else {
            String streetName = road.toString();
            if (houseNumber.toString().isNotEmpty) {
              streetName += ' $houseNumber';
            }
            if (streetName.trim().isNotEmpty) {
              parts.add(streetName.trim());
            }
          }

          if (city.toString().isNotEmpty && (parts.isEmpty || !parts.last.contains(city.toString()))) {
            parts.add(city.toString());
          }

          if (parts.isNotEmpty) return parts.join(', ');
        }
      }
    } catch (_) {}
    return null;
  }

  Future<LatLng?> _forwardGeocode(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (_) {}
    
    // Fallback to OpenStreetMap
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1');
      final response = await http.get(url, headers: {'User-Agent': 'GoTogetherApp_SearchFallback'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat'].toString());
          final lon = double.parse(data[0]['lon'].toString());
          return LatLng(lat, lon);
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  void initState() {
    super.initState();
    final q = widget.quedada;
    _titulo = TextEditingController(text: q.titulo);
    _descripcion = TextEditingController(text: q.descripcion);
    _cupo = TextEditingController(text: q.cupoMax.toString());
    _tematica = _tematicas.contains(q.tematica) ? q.tematica : _tematicas.first;
    _estado = _estados.contains(q.estado) ? q.estado : _estados.first;
    _fechaInicio = q.fechaInicio;
    _fechaFin = q.fechaFin;

    _latCtrl = TextEditingController(text: q.ubicacion.latitude.toStringAsFixed(6));
    _lonCtrl = TextEditingController(text: q.ubicacion.longitude.toStringAsFixed(6));
    _direccionCtrl = TextEditingController(text: '${q.ubicacion.latitude.toStringAsFixed(4)}, ${q.ubicacion.longitude.toStringAsFixed(4)}');
    
    _initAddress(q.ubicacion.latitude, q.ubicacion.longitude);
  }

  Future<void> _initAddress(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          if (p.street?.isNotEmpty == true) p.street!,
          if (p.name?.isNotEmpty == true && p.name != p.street) p.name!,
          if (p.subLocality?.isNotEmpty == true) p.subLocality!,
          if (p.locality?.isNotEmpty == true) p.locality!,
          if (p.country?.isNotEmpty == true) p.country!,
        ];
        final addr = parts.join(', ');
        if (addr.isNotEmpty && mounted) {
          setState(() => _direccionCtrl.text = addr);
        }
      }
    } catch (e) {
      final fallback = await _fallbackGeocode(lat, lon);
      if (fallback != null && mounted) {
        setState(() => _direccionCtrl.text = fallback);
      }
    }
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    _cupo.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _errorMessage = 'Please review the highlighted fields.');
      return;
    }

    if (_fechaInicio == null || _fechaFin == null) {
      setState(() => _errorMessage = 'Please select both start and end dates.');
      return;
    }

    if (_fechaFin!.isBefore(_fechaInicio!) ||
        _fechaFin!.isAtSameMomentAs(_fechaInicio!)) {
      setState(() => _errorMessage = 'End date must be after start date.');
      return;
    }

    final cupo = int.parse(_cupo.text.trim());
    final lat = double.parse(_latCtrl.text.trim().replaceAll(',', '.'));
    final lon = double.parse(_lonCtrl.text.trim().replaceAll(',', '.'));

    setState(() {
      _guardando = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await widget.service.actualizarQuedada(
        eventoId: widget.quedada.id,
        titulo: _titulo.text,
        descripcion: _descripcion.text,
        tematica: _tematica,
        cupoMax: cupo,
        estado: _estado,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        latitud: lat,
        longitud: lon,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.messenger.showSnackBar(
        const SnackBar(content: Text('Plan updated.')),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _errorMessage = 'Error updating plan: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: const Text('Edit plan', style: AppTextStyles.headlineMedium),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titulo,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Title cannot be empty';
                  if (!RegExp(
                    r'[a-zA-ZáéíóúàèìòùÁÉÍÓÚüÜñÑ]',
                  ).hasMatch(v.trim())) {
                    return 'Must include at least one letter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _descripcion,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description cannot be empty'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),

              DropdownButtonFormField<String>(
                value: _tematica,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _tematicas
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(translateCategory(t)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _tematica = v);
                },
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _cupo,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max participants',
                ),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null) return 'Enter a valid number';
                  if (n <= 0) return 'Capacity must be greater than 0';
                  if (n < _asistentesActuales) {
                    return 'Minimum $_asistentesActuales (people already joined)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              DateTimePicker(
                label: 'Start',
                value: _fechaInicio,
                onPicked: (dt) {
                  setState(() {
                    _fechaInicio = dt;
                    if (_fechaFin == null || _fechaFin!.isBefore(dt)) {
                      _fechaFin = dt.add(const Duration(hours: 2));
                    }
                  });
                },
                onCleared: () => setState(() => _fechaInicio = null),
              ),

              const SizedBox(height: AppSpacing.md),
              DateTimePicker(
                label: 'End',
                value: _fechaFin,
                onPicked: (dt) => setState(() => _fechaFin = dt),
                onCleared: () => setState(() => _fechaFin = null),
              ),
              const SizedBox(height: AppSpacing.md),

              DropdownButtonFormField<String>(
                initialValue: _estado,
                decoration: const InputDecoration(labelText: 'Status'),
                items: _estados
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(translateStatus(e)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _estado = v);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Location *', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
                  TextButton.icon(
                    onPressed: () async {
                      LatLng? initialLoc;
                      final lat = double.tryParse(_latCtrl.text.replaceAll(',', '.'));
                      final lon = double.tryParse(_lonCtrl.text.replaceAll(',', '.'));
                      if (lat != null && lon != null) {
                        initialLoc = LatLng(lat, lon);
                      }
                      final LatLng? picked = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LocationPickerScreen(initialLocation: initialLoc),
                        ),
                      );
                      if (picked != null) {
                        setState(() {
                          _latCtrl.text = picked.latitude.toStringAsFixed(6);
                          _lonCtrl.text = picked.longitude.toStringAsFixed(6);
                          _direccionCtrl.text = 'Loading address...';
                          _errorMessage = null;
                          _successMessage = 'Location successfully updated';
                        });
                        try {
                          List<Placemark> placemarks = await placemarkFromCoordinates(picked.latitude, picked.longitude);
                          if (placemarks.isNotEmpty) {
                            final p = placemarks.first;
                            final parts = [
                              if (p.street?.isNotEmpty == true) p.street!,
                              if (p.name?.isNotEmpty == true && p.name != p.street) p.name!,
                              if (p.subLocality?.isNotEmpty == true) p.subLocality!,
                              if (p.locality?.isNotEmpty == true) p.locality!,
                              if (p.country?.isNotEmpty == true) p.country!,
                            ];
                            final addr = parts.join(', ');
                            if (addr.isNotEmpty) {
                              setState(() => _direccionCtrl.text = addr);
                            } else {
                              throw Exception('Empty address computed');
                            }
                          } else {
                            throw Exception('No placemarks found');
                          }
                        } catch(e) {
                          // Fallback to nominatim
                          final fallback = await _fallbackGeocode(picked.latitude, picked.longitude);
                          setState(() {
                            _direccionCtrl.text = fallback ?? '${picked.latitude.toStringAsFixed(4)}, ${picked.longitude.toStringAsFixed(4)}';
                          });
                        }
                      }
                    },
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Pick on map'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _direccionCtrl,
                decoration: InputDecoration(
                  labelText: 'Address or Location *',
                  hintText: 'Type address and click search icon, or pick on map',
                  prefixIcon: const Icon(Icons.place_outlined),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: AppColors.primary),
                    onPressed: () async {
                      if (_guardando) return;
                      final query = _direccionCtrl.text.trim();
                      if (query.isEmpty) return;
                      
                      setState(() => _guardando = true);
                      final coords = await _forwardGeocode(query);
                      setState(() => _guardando = false);
                      
                      if (!mounted) return;
                      
                      if (coords != null) {
                        setState(() {
                          _latCtrl.text = coords.latitude.toStringAsFixed(6);
                          _lonCtrl.text = coords.longitude.toStringAsFixed(6);
                          _errorMessage = null;
                          _successMessage = 'Location successfully updated';
                        });
                      } else {
                        setState(() {
                          _successMessage = null;
                          _errorMessage = 'Location not found. Try using "Pick on map"';
                        });
                      }
                    },
                  )
                ),
                onChanged: (v) {
                  _latCtrl.clear();
                  _lonCtrl.clear();
                  if (_successMessage != null) {
                    setState(() {
                      _successMessage = null;
                    });
                  }
                },
                validator: (v) {
                  if (_latCtrl.text.isEmpty || _lonCtrl.text.isEmpty) {
                    return 'Please click the search icon or pick on map';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 0),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1), 
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1), 
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _guardando ? null : _guardar,
                      child: _guardando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Update'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
