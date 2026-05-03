import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; 
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:profanity_filter/profanity_filter.dart';
import '../../../app_theme.dart';
import '../../../services/quedadas_service.dart';
import '../../../utils/translations.dart';
import '../../../widgets/date_time_picker.dart';
import '../../../utils/bad_words_es.dart';
import 'location_picker_screen.dart';
Future<void> showCreateEventDialog(
  // Muestra una ventana emergente para crear un plan nuevo
  BuildContext context,
  QuedadasService service,
) async {
  final messenger = ScaffoldMessenger.of(context);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => _CreateEventDialog(
      service: service,
      messenger: messenger,
    ),
  );
}

class _CreateEventDialog extends StatefulWidget {
  const _CreateEventDialog({
    required this.service,
    required this.messenger,
  });

  final QuedadasService service;
  final ScaffoldMessengerState messenger;

  @override
  State<_CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends State<_CreateEventDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tituloCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _cupoCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lonCtrl;
  late final TextEditingController _direccionCtrl;

  static const List<String> _tematicas = [
    'Deporte', 'Naturaleza', 'Estudio', 'Ocio', 'Cultura',
    'Gastronomía', 'Fiesta', 'Voluntariado', 'Viajes', 
    'Videojuegos', 'Música', 'Networking', 'Otros',
  ];

  String _tematica = 'Deporte';
  bool _esVerificado = false;
  bool _guardando = false;
  String? _errorMessage; 
  String? _successMessage;

  DateTime? _fechaInicio;
  DateTime? _fechaFin;

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
    _tituloCtrl = TextEditingController();
    _descripcionCtrl = TextEditingController();
    _cupoCtrl = TextEditingController();
    _latCtrl = TextEditingController();
    _lonCtrl = TextEditingController();
    _direccionCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _cupoCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _errorMessage = 'Please review the highlighted fields.');
      return;
    }

    final textoCompleto = '${_tituloCtrl.text} ${_descripcionCtrl.text}'.toLowerCase();
    
    final filter = ProfanityFilter.filterAdditionally(badWordsEs);
    final hasProfanity = filter.hasProfanity(textoCompleto);
    
    if (hasProfanity) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Inappropriate Content', style: TextStyle(color: Colors.red)),
            content: const Text('Inappropriate text detected.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Got it'),
              ),
            ],
          ),
        );
        return;
    }

    if (_fechaInicio == null || _fechaFin == null) {
      setState(() => _errorMessage = 'Please select both start and end dates.');
      return;
    }

    if (_fechaFin!.isBefore(_fechaInicio!) || _fechaFin!.isAtSameMomentAs(_fechaInicio!)) {
      setState(() => _errorMessage = 'End date must be strictly after start date.');
      return;
    }

    if (_fechaInicio!.isBefore(DateTime.now().subtract(const Duration(minutes: 5)))) {
      setState(() => _errorMessage = 'Start date cannot be in the past.');
      return;
    }

    final cupoMax = int.parse(_cupoCtrl.text.trim());
    final lat = double.parse(_latCtrl.text.trim().replaceAll(',', '.'));
    final lon = double.parse(_lonCtrl.text.trim().replaceAll(',', '.'));

    setState(() {
      _errorMessage = null; 
      _successMessage = null;
      _guardando = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final organizadorNombre = user?.displayName?.isNotEmpty == true ? user!.displayName! : (user?.email ?? 'Unknown');

      await widget.service.crearQuedada(
        titulo: _tituloCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
        organizador: organizadorNombre,
        tematica: _tematica,
        cupoMax: cupoMax,
        latitud: lat,
        longitud: lon,
        estado: 'abierta',
        esVerificado: _esVerificado,
        fechaInicio: _fechaInicio!,
        fechaFin: _fechaFin!,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.messenger.showSnackBar(
        const SnackBar(content: Text('Plan successfully created.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _errorMessage = 'Error creating plan: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Plan', style: AppTextStyles.headlineMedium),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _tituloCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required field';
                  if (!RegExp(r'[a-zA-ZáéíóúàèìòùÁÉÍÓÚüÜñÑ]').hasMatch(v.trim())) {
                    return 'Must include at least one letter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required field' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _tematica,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _tematicas
                    .map((t) => DropdownMenuItem(value: t, child: Text(translateCategory(t))))
                    .toList(),
                onChanged: _guardando
                    ? null
                    : (v) {
                        if (v != null) setState(() => _tematica = v);
                      },
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _esVerificado,
                onChanged: _guardando ? null : (v) => setState(() => _esVerificado = v ?? false),
                title: const Text('Verified Event'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 12),
              
              Text('Event Schedule *', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              DateTimePicker(
                label: 'Start (Min: Now)',
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
              const SizedBox(height: 8),
              DateTimePicker(
                label: 'End',
                value: _fechaFin,
                onPicked: (dt) => setState(() => _fechaFin = dt),
                onCleared: () => setState(() => _fechaFin = null),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _cupoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max Participants *',
                  prefixIcon: Icon(Icons.groups_2_outlined),
                ),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n <= 0) return 'Must be > 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
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
                          _successMessage = 'Location successfully selected';
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
                          _successMessage = 'Location successfully selected';
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
              const SizedBox(height: 8),

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
                child: TextButton(
                  onPressed: _guardando ? null : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _guardando ? null : _submit,
                child: _guardando
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Create Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}