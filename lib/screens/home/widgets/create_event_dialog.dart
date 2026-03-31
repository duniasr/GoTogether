import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Recuerda tener esto en pubspec.yaml
import '../../../app_theme.dart';
import '../../../services/quedadas_service.dart';

/// Muestra el diálogo de creación de evento usando un StatefulWidget
/// para garantizar el ciclo de vida correcto de los TextEditingController.
Future<void> showCreateEventDialog(
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

// ─────────────────────────────────────────────
//  Widget privado — gestiona los controllers
//  correctamente con initState / dispose
// ─────────────────────────────────────────────

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
  
  bool _intentado = false; 

  // Variables para fechas y horas
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController();
    _descripcionCtrl = TextEditingController();
    _cupoCtrl = TextEditingController();
    _latCtrl = TextEditingController();
    _lonCtrl = TextEditingController();

    _tituloCtrl.addListener(_onTextChanged);
    _descripcionCtrl.addListener(_onTextChanged);
    _cupoCtrl.addListener(_onTextChanged);
    _latCtrl.addListener(_onTextChanged);
    _lonCtrl.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_intentado) setState(() {});
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

  // --- MÉTODOS DE VALIDACIÓN INDIVIDUAL ---
  bool get _tituloInvalido => _intentado && _tituloCtrl.text.trim().isEmpty;
  bool get _descInvalido => _intentado && _descripcionCtrl.text.trim().isEmpty;
  bool get _cupoInvalido {
    if (!_intentado) return false;
    final val = int.tryParse(_cupoCtrl.text.trim());
    return val == null || val <= 0;
  }
  bool get _latInvalida {
    if (!_intentado) return false;
    final val = double.tryParse(_latCtrl.text.trim().replaceAll(',', '.'));
    return val == null || val < -90 || val > 90;
  }
  bool get _lonInvalida {
    if (!_intentado) return false;
    final val = double.tryParse(_lonCtrl.text.trim().replaceAll(',', '.'));
    return val == null || val < -180 || val > 180;
  }
  bool get _fechasInvalidas {
    if (!_intentado) return false;
    return _startDate == null || _startTime == null || _endDate == null || _endTime == null || !_fechasLogicas();
  }

  bool _fechasLogicas() {
    if (_startDate == null || _startTime == null || _endDate == null || _endTime == null) return false;
    final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day, _startTime!.hour, _startTime!.minute);
    final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, _endTime!.hour, _endTime!.minute);
    return end.isAfter(start);
  }

  // --- MÉTODOS PARA SELECCIONAR FECHA Y HORA ---
  Future<void> _selectDateTime({required bool isStart}) async {
    // 1. Pide la fecha
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && mounted) {
      // 2. Pide la hora inmediatamente después
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: isStart ? (_startTime ?? TimeOfDay.now()) : (_endTime ?? _startTime ?? TimeOfDay.now()),
      );

      if (pickedTime != null) {
        setState(() {
          if (isStart) {
            _startDate = pickedDate;
            _startTime = pickedTime;
            // Auto-ajustar fin si no hay o es anterior al inicio
            if (!_fechasLogicas()) {
              final startDT = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
              final autoEndDT = startDT.add(const Duration(hours: 2));
              _endDate = DateTime(autoEndDT.year, autoEndDT.month, autoEndDT.day);
              _endTime = TimeOfDay(hour: autoEndDT.hour, minute: autoEndDT.minute);
            }
          } else {
            _endDate = pickedDate;
            _endTime = pickedTime;
          }
        });
        _onTextChanged();
      }
    }
  }

  String _formatDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return 'Select Date & Time';
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    return DateFormat('dd MMM yyyy, HH:mm').format(dt);
  }
  // ------------------------------------------------

  Future<void> _submit() async {
    setState(() => _intentado = true); 

    final titulo = _tituloCtrl.text.trim();
    final descripcion = _descripcionCtrl.text.trim();
    final cupoMax = int.tryParse(_cupoCtrl.text.trim());
    final lat = double.tryParse(_latCtrl.text.trim().replaceAll(',', '.'));
    final lon = double.tryParse(_lonCtrl.text.trim().replaceAll(',', '.'));

    if (_tituloInvalido || _descInvalido || _cupoInvalido || _latInvalida || _lonInvalida || _fechasInvalidas) {
      setState(() {
        _errorMessage = 'Please review the highlighted fields. Ensure end time is after start time.';
      });
      return;
    }

    setState(() {
      _errorMessage = null; 
      _guardando = true;
    });

    try {
      final startTimestamp = DateTime(_startDate!.year, _startDate!.month, _startDate!.day, _startTime!.hour, _startTime!.minute);
      final endTimestamp = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, _endTime!.hour, _endTime!.minute);

      await widget.service.crearQuedada(
        titulo: titulo,
        descripcion: descripcion,
        organizador: '',
        tematica: _tematica,
        cupoMax: cupoMax!,
        latitud: lat!,
        longitud: lon!,
        estado: 'abierta',
        esVerificado: _esVerificado,
        fechaInicio: startTimestamp,
        fechaFin: endTimestamp,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.messenger.showSnackBar(
        const SnackBar(content: Text('Plan successfully created.'), backgroundColor: Colors.green),
      );
    } catch (e) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tituloCtrl,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Title *',
                prefixIcon: const Icon(Icons.title_rounded),
                errorText: _tituloInvalido ? 'Required field' : null, 
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descripcionCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description *',
                prefixIcon: const Icon(Icons.notes_rounded),
                errorText: _descInvalido ? 'Required field' : null,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _tematica,
              decoration: const InputDecoration(
                labelText: 'Category *',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: _tematicas
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: _guardando
                  ? null
                  : (v) {
                      if (v != null) setState(() => _tematica = v);
                    },
            ),
            const SizedBox(height: 12),
            
            // --- CALENDARIO INICIO Y FIN (MEJORADO VISUALMENTE) ---
            Text('Event Schedule *', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _guardando ? null : () => _selectDateTime(isStart: true),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: _fechasInvalidas ? AppColors.error : Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, size: 20, color: _startDate == null ? Colors.grey : AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Start: ${_formatDateTime(_startDate, _startTime)}',
                        style: TextStyle(color: _startDate == null ? Colors.grey.shade600 : AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _guardando ? null : () => _selectDateTime(isStart: false),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: _fechasInvalidas ? AppColors.error : Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_available_rounded, size: 20, color: _endDate == null ? Colors.grey : AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'End: ${_formatDateTime(_endDate, _endTime)}',
                        style: TextStyle(color: _endDate == null ? Colors.grey.shade600 : AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // --------------------------------------------------------

            TextField(
              controller: _cupoCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Max Participants *',
                prefixIcon: const Icon(Icons.groups_2_outlined),
                errorText: _cupoInvalido ? 'Must be > 0' : null,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Expanded(
                  child: TextField(
                    controller: _latCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                      labelText: 'Latitude *',
                      hintText: 'e.g. 28.1248',
                      prefixIcon: const Icon(Icons.place_outlined),
                      errorText: _latInvalida ? 'Invalid' : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _lonCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                      labelText: 'Longitude *',
                      hintText: 'e.g. -15.43',
                      prefixIcon: const Icon(Icons.explore_outlined),
                      errorText: _lonInvalida ? 'Invalid' : null,
                    ),
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