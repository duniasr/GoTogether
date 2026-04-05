import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../../../app_theme.dart';
import '../../../services/quedadas_service.dart';
import '../../../utils/translations.dart';
import '../../../widgets/date_time_picker.dart';

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

  static const List<String> _tematicas = [
    'Deporte', 'Naturaleza', 'Estudio', 'Ocio', 'Cultura',
    'Gastronomía', 'Fiesta', 'Voluntariado', 'Viajes', 
    'Videojuegos', 'Música', 'Networking', 'Otros',
  ];

  String _tematica = 'Deporte';
  bool _esVerificado = false;
  bool _guardando = false;
  String? _errorMessage; 

  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController();
    _descripcionCtrl = TextEditingController();
    _cupoCtrl = TextEditingController();
    _latCtrl = TextEditingController();
    _lonCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _cupoCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _errorMessage = 'Please review the highlighted fields.');
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
      _guardando = true;
    });

    try {
      await widget.service.crearQuedada(
        titulo: _tituloCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
        organizador: '',
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
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(
                        labelText: 'Latitude *',
                        hintText: 'e.g. 28.1248',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                      validator: (v) {
                        final val = double.tryParse(v?.trim().replaceAll(',', '.') ?? '');
                        if (val == null || val < -90 || val > 90) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _lonCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(
                        labelText: 'Longitude *',
                        hintText: 'e.g. -15.43',
                        prefixIcon: Icon(Icons.explore_outlined),
                      ),
                      validator: (v) {
                        final val = double.tryParse(v?.trim().replaceAll(',', '.') ?? '');
                        if (val == null || val < -180 || val > 180) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  title: const Text('Verified Event', style: AppTextStyles.labelLarge),
                  subtitle: const Text('Event validated by organization.', style: AppTextStyles.bodyMedium),
                  value: _esVerificado,
                  onChanged: _guardando
                      ? null
                      : (v) => setState(() => _esVerificado = v),
                ),
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