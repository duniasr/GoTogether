import 'package:flutter/material.dart';

import '../models/quedada.dart';
import '../services/quedadas_service.dart';
import '../app_theme.dart';

class QuedadasPage extends StatefulWidget {
  const QuedadasPage({super.key, QuedadasService? service})
      : _service = service;

  final QuedadasService? _service;

  @override
  State<QuedadasPage> createState() => _QuedadasPageState();
}

class _QuedadasPageState extends State<QuedadasPage> {
  static const List<String> _tematicas = <String>[
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

  static const List<String> _estados = <String>[
    'abierta',
    'cerrada',
    'cancelada',
  ];

  late final QuedadasService _service;

  @override
  void initState() {
    super.initState();
    _service = widget._service ?? QuedadasService();
  }

  Future<void> _mostrarFormularioCrearQuedada() async {
    final tituloController = TextEditingController();
    final descripcionController = TextEditingController();
    final organizadorController = TextEditingController();
    final cupoController = TextEditingController();
    final latitudController = TextEditingController();
    final longitudController = TextEditingController();

    String tematicaSeleccionada = _tematicas.first;
    String estadoSeleccionado = _estados.first;
    bool esVerificado = false;
    bool guardando = false;

    // Capturamos el messenger del contexto padre ANTES de abrir el bottom sheet
    final messenger = ScaffoldMessenger.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.md,
                top: AppSpacing.md,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Indicador de arrastrar
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.textHint.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Crear evento',
                        style: AppTextStyles.displayMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Completa los datos para publicar una nueva quedada universitaria.',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: tituloController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Título',
                          hintText: 'Ejemplo: Partido de pádel',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: descripcionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          hintText: 'Cuéntanos qué vais a hacer',
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: organizadorController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Organizador',
                          hintText: 'Si lo dejas vacío se usa tu usuario actual',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Temática', style: AppTextStyles.headlineSmall),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: _tematicas
                            .map(
                              (tematica) => CategoryChip(
                                category: tematica,
                                selected: tematica == tematicaSeleccionada,
                                onTap: () {
                                  setModalState(() {
                                    tematicaSeleccionada = tematica;
                                  });
                                },
                              ),
                            )
                            .toList(growable: false),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      DropdownButtonFormField<String>(
                        value: estadoSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Estado',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                        items: _estados
                            .map(
                              (estado) => DropdownMenuItem<String>(
                                value: estado,
                                child: Text(_capitalizar(estado)),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) return;
                          setModalState(() {
                            estadoSeleccionado = value;
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: cupoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cupo máximo',
                          hintText: 'Ejemplo: 12',
                          prefixIcon: Icon(Icons.groups_2_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: latitudController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Latitud',
                                hintText: '40.4168',
                                prefixIcon: Icon(Icons.place_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextField(
                              controller: longitudController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Longitud',
                                hintText: '-3.7038',
                                prefixIcon: Icon(Icons.explore_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: SwitchListTile.adaptive(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          title: Text('Evento verificado', style: AppTextStyles.labelLarge),
                          subtitle: Text(
                            'Marca esta opción si es un plan validado por la organización.',
                            style: AppTextStyles.bodyMedium,
                          ),
                          value: esVerificado,
                          onChanged: (value) {
                            setModalState(() {
                              esVerificado = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: guardando
                                  ? null
                                  : () => Navigator.of(sheetContext).pop(),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            flex: 2,
                            child: AppPrimaryButton(
                              label: 'Publicar evento',
                              icon: Icons.add_circle_outline_rounded,
                              isLoading: guardando,
                              onPressed: () async {
                                final titulo = tituloController.text.trim();
                                final descripcion = descripcionController.text.trim();
                                final organizador = organizadorController.text.trim();
                                final cupoMax = int.tryParse(cupoController.text.trim());
                                final latitud = double.tryParse(
                                  latitudController.text.trim().replaceAll(',', '.'),
                                );
                                final longitud = double.tryParse(
                                  longitudController.text.trim().replaceAll(',', '.'),
                                );

                                final ubicacionValida =
                                    latitud != null &&
                                    longitud != null &&
                                    latitud >= -90 &&
                                    latitud <= 90 &&
                                    longitud >= -180 &&
                                    longitud <= 180;

                                if (titulo.isEmpty ||
                                    descripcion.isEmpty ||
                                    cupoMax == null ||
                                    cupoMax <= 0 ||
                                    !ubicacionValida) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Rellena título, descripción, cupo válido y una ubicación correcta.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() {
                                  guardando = true;
                                });

                                try {
                                  await _service.crearQuedada(
                                    titulo: titulo,
                                    descripcion: descripcion,
                                    organizador: organizador,
                                    tematica: tematicaSeleccionada,
                                    cupoMax: cupoMax,
                                    latitud: latitud,
                                    longitud: longitud,
                                    estado: estadoSeleccionado,
                                    esVerificado: esVerificado,
                                  );

                                  if (!sheetContext.mounted) return;
                                  Navigator.of(sheetContext).pop();
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Evento creado correctamente.'),
                                    ),
                                  );
                                } catch (error) {
                                  setModalState(() {
                                    guardando = false;
                                  });
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Error al crear el evento: $error'),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    tituloController.dispose();
    descripcionController.dispose();
    organizadorController.dispose();
    cupoController.dispose();
    latitudController.dispose();
    longitudController.dispose();
  }

  Future<void> _eliminarQuedada(Quedada quedada) async {
    final confirmar = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Eliminar evento',
              style: AppTextStyles.headlineMedium,
            ),
            content: Text(
              '¿Seguro que quieres eliminar "${quedada.titulo}"?',
              style: AppTextStyles.bodyLarge,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmar) return;

    try {
      await _service.eliminarQuedada(quedada.id);
      _mostrarMensaje('Evento eliminado.');
    } catch (error) {
      _mostrarMensaje('Error al eliminar el evento: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GoTogether'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormularioCrearQuedada,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo evento'),
      ),
      body: Column(
        children: [
          // Banner de cabecera
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Planes universitarios con estilo',
                  style: AppTextStyles.displayMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Crea, organiza y gestiona eventos sociales desde una única pantalla.',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white.withOpacity(0.92),
                  ),
                ),
              ],
            ),
          ),
          // Lista de quedadas
          Expanded(
            child: StreamBuilder<List<Quedada>>(
              stream: _service.escucharQuedadas(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'Error cargando los eventos: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyLarge,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final quedadas = snapshot.data ?? const <Quedada>[];

                if (quedadas.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: AppCard(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              child: const Icon(
                                Icons.event_available_rounded,
                                color: AppColors.primary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const Text(
                              'Todavía no hay eventos',
                              style: AppTextStyles.headlineMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const Text(
                              'Pulsa en "Nuevo evento" para crear el primero.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: quedadas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final quedada = quedadas[index];
                    final categoryColor =
                        AppColors.categoryColors[quedada.tematica] ??
                            AppColors.textSecondary;

                    return AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      quedada.titulo.isEmpty
                                          ? 'Sin título'
                                          : quedada.titulo,
                                      style: AppTextStyles.headlineMedium,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Wrap(
                                      spacing: AppSpacing.sm,
                                      runSpacing: AppSpacing.sm,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.md,
                                            vertical: AppSpacing.xs + 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: categoryColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(
                                              AppRadius.full,
                                            ),
                                          ),
                                          child: Text(
                                            quedada.tematica,
                                            style: AppTextStyles.labelSmall.copyWith(
                                              color: categoryColor,
                                            ),
                                          ),
                                        ),
                                        _InfoPill(
                                          icon: Icons.flag_outlined,
                                          text: _capitalizar(quedada.estado),
                                        ),
                                        if (quedada.esVerificado)
                                          const _InfoPill(
                                            icon: Icons.verified_rounded,
                                            text: 'Verificado',
                                            color: AppColors.success,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Eliminar evento',
                                onPressed: () => _eliminarQuedada(quedada),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            quedada.descripcion.isEmpty
                                ? 'Sin descripción disponible.'
                                : quedada.descripcion,
                            style: AppTextStyles.bodyLarge,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.md,
                            runSpacing: AppSpacing.sm,
                            children: [
                              _DetailItem(
                                icon: Icons.person_outline_rounded,
                                label: 'Organizador',
                                value: quedada.organizador,
                              ),
                              _DetailItem(
                                icon: Icons.group_outlined,
                                label: 'Plazas',
                                value: '${quedada.plazasLibres}/${quedada.cupoMax} libres',
                              ),
                              _DetailItem(
                                icon: Icons.people_alt_outlined,
                                label: 'Asistentes',
                                value: '${quedada.asistentesActuales}',
                              ),
                              _DetailItem(
                                icon: Icons.location_on_outlined,
                                label: 'Ubicación',
                                value:
                                    '${quedada.ubicacion.latitude.toStringAsFixed(4)}, ${quedada.ubicacion.longitude.toStringAsFixed(4)}',
                              ),
                            ],
                          ),
                          if (quedada.contadorReportes > 0) ...[
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.report_gmailerrorred_rounded,
                                    color: AppColors.warning,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      '${quedada.contadorReportes} reportes registrados',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarMensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  static String _capitalizar(String valor) {
    if (valor.isEmpty) return valor;
    return valor[0].toUpperCase() + valor.substring(1);
  }
}

// ─────────────────────────────────────────────
//  Widgets privados de la página
// ─────────────────────────────────────────────

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.text,
    this.color = AppColors.primary,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: AppTextStyles.labelSmall),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.labelLarge),
            ],
          ),
        ],
      ),
    );
  }
}
