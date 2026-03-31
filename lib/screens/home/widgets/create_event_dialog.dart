import 'package:flutter/material.dart';
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
  
  // NUEVO: Chivato para saber si ya le ha dado al botón de Crear
  bool _intentado = false; 

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController();
    _descripcionCtrl = TextEditingController();
    _cupoCtrl = TextEditingController();
    _latCtrl = TextEditingController();
    _lonCtrl = TextEditingController();

    // Añadimos un listener para que el rojo desaparezca en cuanto escriban
    _tituloCtrl.addListener(_onTextChanged);
    _descripcionCtrl.addListener(_onTextChanged);
    _cupoCtrl.addListener(_onTextChanged);
    _latCtrl.addListener(_onTextChanged);
    _lonCtrl.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    // Si ya han intentado guardar y están corrigiendo, actualizamos la pantalla
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

  // --- MÉTODOS DE VALIDACIÓN INDIVIDUAL (Para poner los campos en rojo) ---
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
  // -------------------------------------------------------------------------

  Future<void> _submit() async {
    setState(() => _intentado = true); // Marcamos que ha intentado guardar

    final titulo = _tituloCtrl.text.trim();
    final descripcion = _descripcionCtrl.text.trim();
    final cupoMax = int.tryParse(_cupoCtrl.text.trim());
    final lat = double.tryParse(_latCtrl.text.trim().replaceAll(',', '.'));
    final lon = double.tryParse(_lonCtrl.text.trim().replaceAll(',', '.'));

    if (_tituloInvalido || _descInvalido || _cupoInvalido || _latInvalida || _lonInvalida) {
      setState(() {
        _errorMessage = 'Por favor, revisa los campos en rojo.';
      });
      return;
    }

    setState(() {
      _errorMessage = null; 
      _guardando = true;
    });

    try {
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
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.messenger.showSnackBar(
        const SnackBar(content: Text('Plan creado correctamente.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() {
        _guardando = false;
        _errorMessage = 'Error al crear el plan: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Nuevo plan', style: AppTextStyles.headlineMedium),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _tituloCtrl,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Título *',
                prefixIcon: const Icon(Icons.title_rounded),
                errorText: _tituloInvalido ? 'Campo requerido' : null, // ¡Magia roja!
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descripcionCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Descripción *',
                prefixIcon: const Icon(Icons.notes_rounded),
                errorText: _descInvalido ? 'Campo requerido' : null,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _tematica,
              decoration: const InputDecoration(
                labelText: 'Temática *',
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
            TextField(
              controller: _cupoCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Cupo máximo *',
                prefixIcon: const Icon(Icons.groups_2_outlined),
                errorText: _cupoInvalido ? 'Debe ser mayor que 0' : null,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Alinea arriba por si uno da error y otro no
              children: [
                Expanded(
                  child: TextField(
                    controller: _latCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                      labelText: 'Latitud *',
                      hintText: 'Ej: 28.1248',
                      prefixIcon: const Icon(Icons.place_outlined),
                      errorText: _latInvalida ? 'Invalida' : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _lonCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                      labelText: 'Longitud *',
                      hintText: 'Ej: -15.43',
                      prefixIcon: const Icon(Icons.explore_outlined),
                      errorText: _lonInvalida ? 'Invalida' : null,
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
                title: const Text('Evento verificado', style: AppTextStyles.labelLarge),
                subtitle: const Text('Evento validado por la organización.', style: AppTextStyles.bodyMedium),
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
                    'Cancelar',
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
                    : const Text('Crear plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}