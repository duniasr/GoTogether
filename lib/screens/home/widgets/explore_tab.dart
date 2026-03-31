import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../app_theme.dart';
import '../../../models/quedada.dart';
import '../../../services/quedadas_service.dart';
import 'category_filter.dart';
import 'event_card.dart';
import '../../../utils/translations.dart';

class ExploreTab extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return StreamBuilder<List<Quedada>>(
      stream: service.escucharQuedadas(),
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

        final filtered = selectedCategory == 'Todos'
            ? allQuedadas
            : allQuedadas
                  .where(
                    (q) =>
                        q.tematica.toLowerCase() ==
                        selectedCategory.toLowerCase(),
                  )
                  .toList();

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(
              child: CategoryFilter(
                categories: categories,
                selectedCategory: selectedCategory,
                onCategorySelected: onCategorySelected,
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
                      selectedCategory == 'Todos'
                          ? 'Nearby Plans'
                          : translateCategory(selectedCategory),
                      style: AppTextStyles.headlineMedium,
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
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final q = filtered[index];
                      final isOrganizer = FirebaseAuth.instance.currentUser?.uid == q.organizador ||
                                          FirebaseAuth.instance.currentUser?.email == q.organizador;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: EventCard(
                          quedada: q,
                          onDelete: isOrganizer ? () async {
                            final confirmar = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete event'),
                                content: Text('Are you sure you want to delete "${q.titulo}"?'),
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
                              await service.eliminarQuedada(q.id);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Event deleted.')),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error deleting: $e')),
                              );
                            }
                          } : null,
                          actionButton: ElevatedButton(
                            onPressed: q.plazasLibres > 0
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
                              q.plazasLibres > 0 ? 'Join' : 'Full',
                              style: AppTextStyles.button.copyWith(
                                color: q.plazasLibres > 0 ? Colors.white : AppColors.textHint,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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
            'No plans in this category',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Be the first to create one.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
