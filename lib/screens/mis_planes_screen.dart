import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/quedada.dart';
import '../services/quedadas_service.dart';
import 'home/widgets/create_event_dialog.dart';
import '../utils/translations.dart';

class MisPlanesScreen extends StatefulWidget {
  const MisPlanesScreen({super.key});

  @override
  State<MisPlanesScreen> createState() => _MisPlanesScreenState();
}

class _MisPlanesScreenState extends State<MisPlanesScreen> {
  final _service = QuedadasService();
  late final Stream<List<Quedada>> _creadosStream;
  late final Stream<List<Quedada>> _unidosStream;

  @override
  void initState() {
    super.initState();
    _creadosStream = _service.escucharMisQuedadas();
    _unidosStream  = _service.escucharQuedadasUnidas();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
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
                    AppSpacing.md, AppSpacing.lg, AppSpacing.md, 0),
                child: Text('My Plans', style: AppTextStyles.displayMedium),
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

// ─────────────────────────────────────────────
//  Tab genérico con keepAlive para evitar
//  re-suscripciones al cambiar de pestaña.
// ─────────────────────────────────────────────
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
                const Icon(Icons.event_busy_outlined,
                    size: 52, color: AppColors.textHint),
                const SizedBox(height: AppSpacing.md),
                Text(widget.textoVacio, style: AppTextStyles.bodyMedium),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, 100),
          itemCount: planes.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, i) => _MiPlanCard(
            quedada: planes[i],
            service: widget.service,
            esCreador: widget.esCreador,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  Tarjeta de plan propio — misma estructura
//  visual que EventCard pero con botones
//  distintos según si es creador o asistente.
// ─────────────────────────────────────────────
class _MiPlanCard extends StatefulWidget {
  final Quedada quedada;
  final QuedadasService service;
  final bool esCreador;

  const _MiPlanCard({
    required this.quedada,
    required this.service,
    required this.esCreador,
  });

  @override
  State<_MiPlanCard> createState() => _MiPlanCardState();
}

class _MiPlanCardState extends State<_MiPlanCard> {
  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  // ── Borrar (solo creador) ──────────────────
  Future<void> _eliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Delete plan'),
        content: Text(
          'Are you sure you want to delete "${widget.quedada.titulo}"?\nThis action cannot be undone.',
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
    ) ?? false;

    if (!confirmar) return;

    try {
      await widget.service.eliminarQuedada(widget.quedada.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ── Abandonar (solo asistente) ────────────
  Future<void> _abandonar() async {
    try {
      await widget.service.abandonarQuedada(widget.quedada.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have left the plan.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ── Editar (solo creador) ─────────────────
  void _editar() {
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => _EditDialog(
        quedada: widget.quedada,
        service: widget.service,
        messenger: messenger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quedada;
    final spots = q.plazasLibres;
    final maxSpots = q.cupoMax;
    final fillRatio =
        maxSpots > 0 ? ((maxSpots - spots) / maxSpots).clamp(0.0, 1.0) : 0.0;
    final almostFull = spots <= 2 && spots > 0;
    final catColor =
        AppColors.categoryColors[q.tematica] ?? AppColors.textSecondary;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabecera: título + icono basura ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  q.titulo.isEmpty ? 'No title' : q.titulo,
                  style: AppTextStyles.headlineSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (q.esVerificado) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified_rounded,
                    color: AppColors.warning, size: 20),
              ],
              if (widget.esCreador) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _eliminar,
                  child: const Icon(Icons.delete_outline,
                      color: AppColors.error, size: 20),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Chips ────────────────────────────
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              CategoryChip(category: q.tematica),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(translateStatus(q.estado), style: AppTextStyles.labelSmall),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Descripción ───────────────────────
          if (q.descripcion.isNotEmpty)
            Text(q.descripcion,
                style: AppTextStyles.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSpacing.sm),

          // ── Organizador ───────────────────────
          Row(
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(q.organizador,
                    style: AppTextStyles.labelSmall,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),

          // ── Barra de plazas ───────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                spots > 0
                    ? '$spots ${spots == 1 ? 'spot left' : 'spots left'}'
                    : 'No spots left',
                style: AppTextStyles.labelSmall.copyWith(
                  color: almostFull ? AppColors.error : AppColors.textSecondary,
                  fontWeight: almostFull ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              Text('Max $maxSpots', style: AppTextStyles.labelSmall),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: fillRatio,
              minHeight: 6,
              backgroundColor: AppColors.surfaceAlt,
              color: almostFull ? AppColors.error : catColor,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Botón principal ───────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.esCreador ? _editar : _abandonar,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.esCreador
                    ? AppColors.primary
                    : AppColors.error.withOpacity(0.12),
                foregroundColor:
                    widget.esCreador ? Colors.white : AppColors.error,
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
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Diálogo de edición (solo creador)
// ─────────────────────────────────────────────
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
    'Deporte', 'Naturaleza', 'Estudio', 'Ocio', 'Cultura',
    'Gastronomía', 'Fiesta', 'Voluntariado', 'Viajes',
    'Videojuegos', 'Música', 'Networking', 'Otros',
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

  // Número de asistentes actuales (cupo mínimo permitido)
  int get _asistentesActuales => widget.quedada.asistentesId.length;

  @override
  void initState() {
    super.initState();
    final q = widget.quedada;
    _titulo      = TextEditingController(text: q.titulo);
    _descripcion = TextEditingController(text: q.descripcion);
    _cupo        = TextEditingController(text: q.cupoMax.toString());
    _tematica = _tematicas.contains(q.tematica) ? q.tematica : _tematicas.first;
    _estado   = _estados.contains(q.estado) ? q.estado : _estados.first;
    _fechaInicio = q.fechaInicio;
    _fechaFin    = q.fechaFin;
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
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      title: const Text('Edit plan', style: AppTextStyles.headlineMedium),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título
              TextFormField(
                controller: _titulo,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Title cannot be empty';
                  if (!RegExp(r'[a-zA-ZáéíóúàèìòùÁÉÍÓÚüÜñÑ]').hasMatch(v.trim())) {
                    return 'Must include at least one letter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Descripción
              TextFormField(
                controller: _descripcion,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Description cannot be empty' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Temática (dropdown, siempre válido)
              DropdownButtonFormField<String>(
                value: _tematica,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _tematicas
                    .map((t) => DropdownMenuItem(value: t, child: Text(translateCategory(t))))
                    .toList(),
                onChanged: (v) { if (v != null) setState(() => _tematica = v); },
              ),
              const SizedBox(height: AppSpacing.md),

              // Cupo máximo
              TextFormField(
                controller: _cupo,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max participants'),
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
              // Fecha de inicio
              const SizedBox(height: AppSpacing.md),
              _DateTimePicker(
                label: 'Start',
                value: _fechaInicio,
                onPicked: (dt) => setState(() => _fechaInicio = dt),
                onCleared: () => setState(() => _fechaInicio = null),
              ),

              // Fecha de fin
              const SizedBox(height: AppSpacing.md),
              _DateTimePicker(
                label: 'End',
                value: _fechaFin,
                onPicked: (dt) => setState(() => _fechaFin = dt),
                onCleared: () => setState(() => _fechaFin = null),
              ),
              const SizedBox(height: AppSpacing.md),

              // Estado
              DropdownButtonFormField<String>(
                value: _estado,
                decoration: const InputDecoration(labelText: 'Status'),
                items: _estados
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(translateStatus(e)),
                        ))
                    .toList(),
                onChanged: (v) { if (v != null) setState(() => _estado = v); },
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
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('Update'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Picker reutilizable de fecha + hora
// ─────────────────────────────────────────────
class _DateTimePicker extends StatefulWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;
  final VoidCallback onCleared;

  const _DateTimePicker({
    required this.label,
    required this.value,
    required this.onPicked,
    required this.onCleared,
  });

  @override
  State<_DateTimePicker> createState() => _DateTimePickerState();
}

class _DateTimePickerState extends State<_DateTimePicker> {
  static String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}  '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

  Future<void> _pick() async {
    final hoy = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: widget.value ?? hoy,
      firstDate: DateTime(hoy.year - 1),
      lastDate: DateTime(hoy.year + 5),
    );
    if (fecha == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: widget.value != null
          ? TimeOfDay.fromDateTime(widget.value!)
          : TimeOfDay.now(),
    );
    if (hora == null || !mounted) return;

    widget.onPicked(DateTime(
        fecha.year, fecha.month, fecha.day, hora.hour, hora.minute));
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: _pick,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: '${widget.label} Date',
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          suffixIcon: widget.value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: widget.onCleared,
                )
              : null,
        ),
        child: Text(
          widget.value != null ? _fmt(widget.value!) : 'No date',
          style: AppTextStyles.bodyMedium.copyWith(
            color: widget.value != null ? null : AppColors.textHint,
          ),
        ),
      ),
    );
  }
}
