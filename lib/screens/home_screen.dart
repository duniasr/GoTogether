import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../models/quedada.dart';
import '../services/quedadas_service.dart';
import 'profile_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Todos';
  int _currentIndex = 0;

  // Servicio de quedadas conectado a Firebase
  final QuedadasService _service = QuedadasService();

  // Temáticas de configuración
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

  final List<String> _categories = [
    'Todos',
    'Fiesta',
    'Deporte',
    'Cultura',
    'Gastronomía',
    'Aire libre',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
       body: SafeArea(
        child: _currentIndex == 0
            ? _buildExploreTab()
            : _buildPlaceholderTab(_currentIndex),
      ),
      floatingActionButton: _currentIndex == 0
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppShadows.button,
              ),
              child: FloatingActionButton.extended(
                onPressed: _onCreateEvent,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded, size: 22),
                label: Text(
                  'Crear plan',
                  style: AppTextStyles.button.copyWith(color: Colors.white),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildExploreTab() {
    return StreamBuilder<List<Quedada>>(
      stream: _service.escucharQuedadas(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Error cargando los planes: ${snapshot.error}',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final allQuedadas = snapshot.data ?? const [];
        final isLoading =
            snapshot.connectionState == ConnectionState.waiting &&
            allQuedadas.isEmpty;

        final filtered = _selectedCategory == 'Todos'
            ? allQuedadas
            : allQuedadas
                  .where(
                    (q) =>
                        q.tematica.toLowerCase() ==
                        _selectedCategory.toLowerCase(),
                  )
                  .toList();

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildCategoryFilter()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCategory == 'Todos'
                          ? 'Planes cercanos'
                          : _selectedCategory,
                      style: AppTextStyles.headlineMedium,
                    ),
                    if (!isLoading)
                      Text(
                        '${filtered.length} planes',
                        style: AppTextStyles.bodyMedium,
                      ),
                  ],
                ),
              ),
            ),
            if (isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (filtered.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  100,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _buildEventCard(filtered[index]),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Text(
        'GoTogether',
        style: AppTextStyles.displayMedium.copyWith(color: AppColors.primary),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final selected = cat == _selectedCategory;
          return CategoryChip(
            category: cat,
            selected: selected,
            onTap: () => setState(() => _selectedCategory = cat),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(Quedada quedada) {
    final spots = quedada.plazasLibres;
    final maxSpots = quedada.cupoMax;
    final fillRatio = maxSpots > 0
        ? ((maxSpots - spots) / maxSpots).clamp(0.0, 1.0)
        : 0.0;
    final almostFull = spots <= 2 && spots > 0;
    final catColor =
        AppColors.categoryColors[quedada.tematica] ?? AppColors.textSecondary;

    final isCurrentUserOrganizer =
        FirebaseAuth.instance.currentUser?.uid == quedada.organizador ||
        FirebaseAuth.instance.currentUser?.email == quedada.organizador;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  quedada.titulo.isEmpty ? 'Sin título' : quedada.titulo,
                  style: AppTextStyles.headlineSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (quedada.esVerificado) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFFFFAA00),
                  size: 20,
                ),
              ],
              if (isCurrentUserOrganizer) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _confirmarEliminarQuedada(quedada),
                  child: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              CategoryChip(category: quedada.tematica),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  _capitalizar(quedada.estado),
                  style: AppTextStyles.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          if (quedada.descripcion.isNotEmpty)
            Text(
              quedada.descripcion,
              style: AppTextStyles.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  quedada.organizador,
                  style: AppTextStyles.labelSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                spots > 0
                    ? '$spots ${spots == 1 ? 'plaza libre' : 'plazas libres'}'
                    : 'Sin plazas',
                style: AppTextStyles.labelSmall.copyWith(
                  color: almostFull ? AppColors.error : AppColors.textSecondary,
                  fontWeight: almostFull ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              Text('$maxSpots máx.', style: AppTextStyles.labelSmall),
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

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: spots > 0
                  ? () {
                      // TODO: Implementar lógica de inscripción (HU-11)
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.surfaceAlt,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                elevation: 0,
              ),
              child: Text(
                spots > 0 ? 'Unirme' : 'Completo',
                style: AppTextStyles.button.copyWith(
                  color: spots > 0 ? Colors.white : AppColors.textHint,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarEliminarQuedada(Quedada quedada) async {
    final confirmar =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar evento'),
            content: Text('¿Seguro que quieres eliminar "${quedada.titulo}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Evento eliminado.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
    }
  }

  Future<void> _onCreateEvent() async {
    final tituloCtrl = TextEditingController();
    final descripcionCtrl = TextEditingController();
    final cupoCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lonCtrl = TextEditingController();

    String tematica = _tematicas.first;
    bool esVerificado = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Nuevo plan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: tituloCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Título *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descripcionCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: tematica,
                      decoration: const InputDecoration(
                        labelText: 'Temática *',
                        border: OutlineInputBorder(),
                      ),
                      items: _tematicas
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setStateDialog(() => tematica = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cupoCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cupo máximo *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: latCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Latitud *',
                        hintText: 'Ej: 28.1248',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lonCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Longitud *',
                        hintText: 'Ej: -15.4300',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Evento verificado'),
                      value: esVerificado,
                      onChanged: (v) => setStateDialog(() => esVerificado = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    final titulo = tituloCtrl.text.trim();
                    final descripcion = descripcionCtrl.text.trim();
                    final cupoMax = int.tryParse(cupoCtrl.text.trim());
                    final lat = double.tryParse(
                      latCtrl.text.trim().replaceAll(',', '.'),
                    );
                    final lon = double.tryParse(
                      lonCtrl.text.trim().replaceAll(',', '.'),
                    );

                    final ubicacionValida =
                        lat != null &&
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Por favor, completa todos los campos correctamente.',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      await _service.crearQuedada(
                        titulo: titulo,
                        descripcion: descripcion,
                        organizador: '',
                        tematica: tematica,
                        cupoMax: cupoMax,
                        latitud: lat,
                        longitud: lon,
                        estado: 'abierta',
                        esVerificado: esVerificado,
                      );

                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Plan creado correctamente.'),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al crear el plan: $e')),
                      );
                    }
                  },
                  child: const Text('Crear plan'),
                ),
              ],
            );
          },
        );
      },
    );

    tituloCtrl.dispose();
    descripcionCtrl.dispose();
    cupoCtrl.dispose();
    latCtrl.dispose();
    lonCtrl.dispose();
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxl,
        horizontal: AppSpacing.lg,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 56,
            color: AppColors.textHint,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No hay planes de esta categoría',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Sé el primero en crear uno.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab(int index) {
    // Si el usuario toca el índice 3 (la 4ª pestaña, "Perfil")
    if (index == 3) {
      return const ProfileScreen(); // ¡Llamamos a tu pantalla!
    }

    // Para Mapa (1) y Mis planes (2), mostramos un texto de aviso
    return Center(
      child: Text(
        'Próximamente...',
        style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textHint),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: Color(0xFFEBEFF5), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        selectedLabelStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: AppTextStyles.labelSmall,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore_rounded),
            label: 'Explorar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map_rounded),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note_rounded),
            label: 'Mis planes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  static String _capitalizar(String valor) {
    if (valor.isEmpty) return valor;
    return valor[0].toUpperCase() + valor.substring(1);
  }
}
