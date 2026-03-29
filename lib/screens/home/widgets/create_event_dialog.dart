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
  // Controllers creados UNA VEZ en initState y liberados en dispose()
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _cupoCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lonCtrl;

  static const List<String> _tematicas = [
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

  String _tematica = 'Deporte';
  bool _esVerificado = false;
  bool _guardando = false;

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
    final titulo = _tituloCtrl.text.trim();
    final descripcion = _descripcionCtrl.text.trim();
    final cupoMax = int.tryParse(_cupoCtrl.text.trim());
    final lat = double.tryParse(_latCtrl.text.trim().replaceAll(',', '.'));
    final lon = double.tryParse(_lonCtrl.text.trim().replaceAll(',', '.'));

    final ubicacionValida = lat != null &&
        lon != null &&
        lat >= -90 &&
        lat <= 90 &&
        lon >= -180 &&
        lon <= 180;

    if (titulo.isEmpty ||
        descripcion.isEmpty ||
        cupoMax == null ||
        cupoMax <= 0 ||
        !ubicacionValida) {
      widget.messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, completa todos los campos correctamente.',
          ),
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      await widget.service.crearQuedada(
        titulo: titulo,
        descripcion: descripcion,
        organizador: '',
        tematica: _tematica,
        cupoMax: cupoMax,
        latitud: lat,
        longitud: lon,
        estado: 'abierta',
        esVerificado: _esVerificado,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.messenger.showSnackBar(
        const SnackBar(content: Text('Plan creado correctamente.')),
      );
    } catch (e) {
      if (mounted) setState(() => _guardando = false);
      widget.messenger.showSnackBar(
        SnackBar(content: Text('Error al crear el plan: $e')),
      );
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
              decoration: const InputDecoration(
                labelText: 'Título *',
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descripcionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción *',
                prefixIcon: Icon(Icons.notes_rounded),
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
              decoration: const InputDecoration(
                labelText: 'Cupo máximo *',
                prefixIcon: Icon(Icons.groups_2_outlined),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Latitud *',
                      hintText: 'Ej: 28.1248',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _lonCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Longitud *',
                      hintText: 'Ej: -15.43',
                      prefixIcon: Icon(Icons.explore_outlined),
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
      // Ajustamos los márgenes de los botones para que respiren bien
      actionsPadding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 0),
      actions: [
        SizedBox(
          width: double.infinity, // Hace que ocupe todo el ancho
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _guardando ? null : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: _guardando ? null : _submit,
                child: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Crear plan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
