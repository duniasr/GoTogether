import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../app_theme.dart';
import '../../../models/quedada.dart';
import '../../../services/quedadas_service.dart';
import 'category_filter.dart';
import 'event_card.dart';
import '../../../utils/translations.dart';
import 'package:geolocator/geolocator.dart';

class ExploreTab extends StatefulWidget {
  final QuedadasService service;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final List<String> categories;

  const ExploreTab({
    super.key,
    required this.service,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.categories,
  });

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      // Ignore exceptions if location cannot be fetched
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Quedada>>(
      stream: widget.service.escucharQuedadasFuturas(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Error loading plans: ${snapshot.error}',
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

        final filteredByCategory = widget.selectedCategory == 'All'
            ? allQuedadas
            : allQuedadas
                  .where(
                    (q) =>
                        q.tematica.toLowerCase() ==
                        widget.selectedCategory.toLowerCase() ||
                        translateCategory(q.tematica).toLowerCase() == 
                        widget.selectedCategory.toLowerCase(),
                  )
                  .toList();

        final filtered = filteredByCategory.where((q) {
          if (_searchQuery.isEmpty) return true;
          return q.titulo.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        if (_currentPosition != null) {
          filtered.sort((a, b) {
            final distA = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              a.ubicacion.latitude,
              a.ubicacion.longitude,
            );
            final distB = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              b.ubicacion.latitude,
              b.ubicacion.longitude,
            );
            return distA.compareTo(distB);
          });
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF12467A), // AppColors.primaryDark
                      AppColors.primary,
                      Color(0xFF2E85D4), // Slightly lighter blue
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    _buildSearchBar(),
                    const SizedBox(height: AppSpacing.sm),
                    CategoryFilter(
                      categories: widget.categories,
                      selectedCategory: widget.selectedCategory,
                      onCategorySelected: widget.onCategorySelected,
                    ),
                  ],
                ),
              ),
            ),
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
                      widget.selectedCategory == 'All'
                          ? 'Upcoming Plans Near You'
                          : translateCategory(widget.selectedCategory),
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: widget.selectedCategory == 'All'
                            ? const Color(0xFFF59E0B)
                            : (AppColors.categoryColors[widget
                                      .selectedCategory] ??
                                  const Color(0xFFF59E0B)),
                      ),
                    ),
                    if (!isLoading)
                      Text(
                        '${filtered.length} plans',
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
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final q = filtered[index];
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    final email = FirebaseAuth.instance.currentUser?.email;
                    final isOrganizer =
                        (uid != null && uid == q.organizadorId) ||
                        uid == q.organizador ||
                        email == q.organizador;
                    final isJoined =
                        (uid != null && q.asistentesID.contains(uid)) ||
                        isOrganizer;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: EventCard(
                        quedada: q,
                        isJoined: isJoined,
                        onDelete: isOrganizer
                            ? () async {
                                final confirmar =
                                    await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete event'),
                                        content: Text(
                                          'Are you sure you want to delete "${q.titulo}"?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          FilledButton(
                                            style: FilledButton.styleFrom(
                                              backgroundColor: AppColors.error,
                                            ),
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(true),
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Event deleted.'),
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error deleting: $e'),
                                    ),
                                  );
                                }
                              }
                            : null,
                        actionButton: isJoined
                            ? (isOrganizer
                                ? null
                                : ElevatedButton(
                                    onPressed: () async {
                                      final confirmar =
                                          await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Leave event'),
                                              content: Text(
                                                'Are you sure you want to leave "${q.titulo}"?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(ctx).pop(false),
                                                  child: const Text('Cancel'),
                                                ),
                                                FilledButton(
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor: AppColors.error,
                                                  ),
                                                  onPressed: () =>
                                                      Navigator.of(ctx).pop(true),
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
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('You have left the plan.')),
                                        );
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error leaving: $e')),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.error.withOpacity(0.1),
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppRadius.md),
                                      ),
                                    ),
                                    child: Text(
                                      'Leave',
                                      style: AppTextStyles.button.copyWith(color: AppColors.error),
                                    ),
                                  ))
                            : ElevatedButton(
                                onPressed:
                                    (q.plazasLibres > 0 &&
                                        q.estado == 'abierta')
                                    ? () async {
                                        try {
                                          await widget.service.unirseAQuedada(
                                            q.id,
                                          );
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'You have joined the plan!',
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error joining: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  disabledBackgroundColor: AppColors.error,
                                  disabledForegroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  (q.plazasLibres > 0 && q.estado == 'abierta')
                                      ? 'Join'
                                      : (q.estado == 'cerrada'
                                            ? 'Closed'
                                            : 'Full'),
                                  style: AppTextStyles.button.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                      ),
                    );
                  }, childCount: filtered.length),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Image.asset(
              'assets/images/Logo.png',
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'GoTogether',
            style: AppTextStyles.displayMedium.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search plan by name...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textHint,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textHint),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: AppSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
            borderSide: const BorderSide(color: Color(0xFFEBEFF5), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
            borderSide: const BorderSide(color: AppColors.primary, width: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchQuery.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxl,
        horizontal: AppSpacing.lg,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearching ? Icons.search_off_rounded : Icons.event_busy_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isSearching ? 'No plans found' : 'No plans in this category',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isSearching
                ? 'Try a different search term.'
                : 'Be the first to create one.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
