import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';

// ─────────────────────────────────────────────
//  HomeScreen — Pantalla principal del MVP
//  Muestra: saludo, categorías, lista de
//  quedadas cercanas y FAB para crear plan.
// ─────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Todos';
  int _currentIndex = 0;

  // Categorías del filtro superior
  final List<String> _categories = [
    'Todos',
    'Fiesta',
    'Deporte',
    'Cultura',
    'Gastronomía',
    'Aire libre',
  ];

  // ── Datos de prueba (luego vendrán de Firestore) ──
  final List<Map<String, dynamic>> _mockEvents = [
    {
      'id': '1',
      'title': 'Fútbol en la playa de Las Canteras',
      'category': 'Deporte',
      'location': 'Playa de Las Canteras',
      'time': 'Hoy · 18:00',
      'spots': 4,
      'maxSpots': 10,
      'isVerified': false,
    },
    {
      'id': '2',
      'title': 'Noche de juegos — Café El Rincón',
      'category': 'Fiesta',
      'location': 'Café El Rincón, Triana',
      'time': 'Hoy · 20:30',
      'spots': 2,
      'maxSpots': 8,
      'isVerified': true,
    },
    {
      'id': '3',
      'title': 'Tour cultural por Vegueta',
      'category': 'Cultura',
      'location': 'Plaza de Santa Ana',
      'time': 'Mañana · 11:00',
      'spots': 7,
      'maxSpots': 15,
      'isVerified': true,
    },
    {
      'id': '4',
      'title': 'Senderismo Pico Bandama',
      'category': 'Aire libre',
      'location': 'Caldera de Bandama',
      'time': 'Sábado · 09:00',
      'spots': 5,
      'maxSpots': 12,
      'isVerified': false,
    },
    {
      'id': '5',
      'title': 'Cata de papas arrugadas y mojos',
      'category': 'Gastronomía',
      'location': 'Mercado del Puerto',
      'time': 'Sábado · 13:00',
      'spots': 3,
      'maxSpots': 6,
      'isVerified': false,
    },
  ];

  // Nombre del usuario actual (simplificado)
  String get _userName {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!.split(' ').first;
    }
    return 'viajero';
  }

  // Filtra los eventos según la categoría seleccionada
  List<Map<String, dynamic>> get _filteredEvents {
    if (_selectedCategory == 'Todos') return _mockEvents;
    return _mockEvents
        .where((e) => e['category'] == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _currentIndex == 0
            ? _buildExploreTab()
            : _buildPlaceholderTab(_currentIndex),
      ),
      // ── FAB: Crear quedada ──
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

      // ── Bottom Navigation ──
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ────────────────────────────────────────────
  //  TAB: Explorar
  // ────────────────────────────────────────────
  Widget _buildExploreTab() {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(child: _buildHeader()),

        // Chips de categoría
        SliverToBoxAdapter(child: _buildCategoryFilter()),

        // Título sección
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
                Text(
                  '${_filteredEvents.length} planes',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ),

        // Lista de eventos
        _filteredEvents.isEmpty
            ? SliverToBoxAdapter(child: _buildEmptyState())
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  100, // espacio para el FAB
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _buildEventCard(_filteredEvents[index]),
                    ),
                    childCount: _filteredEvents.length,
                  ),
                ),
              ),
      ],
    );
  }

  // ── Header con saludo y botón de perfil ──
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, $_userName! 👋',
                  style: AppTextStyles.displayMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '¿Qué plan te apetece hoy?',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
          // Avatar / perfil
          GestureDetector(
            onTap: _onProfileTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Chips de filtro horizontal ──
  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;

          if (cat == 'Todos') {
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = 'Todos'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  'Todos',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }

          return CategoryChip(
            category: cat,
            selected: isSelected,
            onTap: () => setState(() => _selectedCategory = cat),
          );
        },
      ),
    );
  }

  // ── Tarjeta de evento ──
  Widget _buildEventCard(Map<String, dynamic> event) {
    final int spots = event['spots'] as int;
    final int maxSpots = event['maxSpots'] as int;
    final double fillRatio = (maxSpots - spots) / maxSpots;
    final bool almostFull = spots <= 2;
    final bool isVerified = event['isVerified'] as bool;
    final Color catColor =
        AppColors.categoryColors[event['category']] ?? AppColors.textSecondary;

    return AppCard(
      onTap: () {
        /* TODO: Navegar al detalle del evento */
      },
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila superior: categoría + badge verificado
          Row(
            children: [
              CategoryChip(category: event['category'] as String),
              const Spacer(),
              if (isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: AppColors.accent,
                        size: 12,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Verificado',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm + 2),

          // Título
          Text(event['title'] as String, style: AppTextStyles.headlineSmall),

          const SizedBox(height: AppSpacing.sm),

          // Lugar y hora
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  event['location'] as String,
                  style: AppTextStyles.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 4),
              Text(event['time'] as String, style: AppTextStyles.bodyMedium),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Barra de aforo
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    almostFull ? '🔥 ¡Casi lleno!' : '$spots plazas libres',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: almostFull
                          ? AppColors.error
                          : AppColors.textSecondary,
                      fontWeight: almostFull
                          ? FontWeight.w700
                          : FontWeight.w500,
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
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Botón de unirse
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: spots > 0
                  ? () {
                      /* TODO: HU-11 Inscripción */
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

  // ── Estado vacío ──
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
            '¡Sé el primero en crear uno!',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Placeholder para las otras pestañas ──
  Widget _buildPlaceholderTab(int index) {
    final data = [
      {'icon': Icons.map_rounded, 'label': 'Mapa'},
      {'icon': Icons.event_note_rounded, 'label': 'Mis planes'},
      {'icon': Icons.person_rounded, 'label': 'Perfil'},
    ];
    final item = data[index - 1];
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item['icon'] as IconData, size: 56, color: AppColors.textHint),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${item['label']} — próximamente',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Navigation Bar ──
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

  // ── Handlers ──
  void _onCreateEvent() {
    // TODO: HU-06 Navegar al formulario de crear quedada
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Crear plan — próximamente'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }

  void _onProfileTap() {
    // TODO: Navegar al perfil / ajustes (con opción de cerrar sesión)
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => _buildProfileSheet(),
    );
  }

  Widget _buildProfileSheet() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Mi cuenta', style: AppTextStyles.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          Text(
            FirebaseAuth.instance.currentUser?.email ?? '',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          // Cerrar sesión
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await FirebaseAuth.instance.signOut();
              },
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              label: Text(
                'Cerrar sesión',
                style: AppTextStyles.button.copyWith(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
