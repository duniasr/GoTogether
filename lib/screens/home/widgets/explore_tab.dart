import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../models/quedada.dart';
import '../../../services/quedadas_service.dart';
import 'category_filter.dart';
import 'event_card.dart';

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
                          ? 'Planes cercanos'
                          : selectedCategory,
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
                      child: EventCard(
                        quedada: filtered[index],
                        service: service,
                      ),
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
}
