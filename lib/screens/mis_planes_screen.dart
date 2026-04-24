import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/quedada.dart';
import '../services/quedadas_service.dart';
import 'home/widgets/create_event_dialog.dart';
import '../utils/translations.dart';
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
        floatingActionButton: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadows.button,
          ),
          child: FloatingActionButton.extended(
            onPressed: () => showCreateEventDialog(context, _service),
            backgroundColor: AppColors.warning,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded, size: 22),
            label: Text(
              'Create Plan',
              style: AppTextStyles.button.copyWith(color: Colors.white),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  0,
                ),
                child: Text(
                  'My Plans',
                  style: AppTextStyles.displayMedium.copyWith(color: const Color(0xFFF59E0B)),
                ),
              ),
              const TabBar(
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: [
                  Tab(text: 'Created'),
                  Tab(text: 'Joined'),
                ],
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
                const Icon(
                  Icons.event_busy_outlined,
                  size: 52,
                  color: AppColors.textHint,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(widget.textoVacio, style: AppTextStyles.bodyMedium),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            100,
          ),
          itemCount: planes.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, i) {
            final q = planes[i];
            return EventCard(
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
                    borderRadius: BorderRadius.circular(AppRadius.sm),
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
            );
          },
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
  late String _tematica;
  late String _estado;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _guardando = false;

  int get _asistentesActuales => widget.quedada.asistentesID.length;

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
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    _cupo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fechaInicio == null || _fechaFin == null) {
      widget.messenger.showSnackBar(
        const SnackBar(
          content: Text('Please select both start and end dates.'),
        ),
      );
      return;
    }

    if (_fechaFin!.isBefore(_fechaInicio!) ||
        _fechaFin!.isAtSameMomentAs(_fechaInicio!)) {
      widget.messenger.showSnackBar(
        const SnackBar(content: Text('End date must be after start date.')),
      );
      return;
    }

    final cupo = int.parse(_cupo.text.trim());
    setState(() => _guardando = true);
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
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.messenger.showSnackBar(
        const SnackBar(content: Text('Plan updated.')),
      );
    } catch (_) {
      if (mounted) setState(() => _guardando = false);
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
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
    );
  }
}
