import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/quedada.dart';
import '../services/quedadas_service.dart';
import '../l10n/app_localizations.dart';
import 'home/widgets/event_card.dart';

class AdminReportsTab extends StatelessWidget {
  const AdminReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final service = QuedadasService();

    return StreamBuilder<List<Quedada>>(
      stream: service.escucharQuedadasReportadas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                '${AppLocalizations.get('error')}: ${snapshot.error}',
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final eventos = snapshot.data ?? [];

        if (eventos.isEmpty) {
          return Center(
            child: Text(
              AppLocalizations.get('no_reported_events'),
              style: AppTextStyles.bodyLarge,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: eventos.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final quedada = eventos[index];

            return AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.error.withOpacity(0.15),
                  child: const Icon(Icons.report_problem_rounded, color: AppColors.error),
                ),
                title: Text(quedada.titulo.isEmpty ? AppLocalizations.get('no_title') : quedada.titulo),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${AppLocalizations.get('organized_by')}: ${quedada.organizador}\n${quedada.contadorReportes} ${AppLocalizations.get('reports_count')}',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                  ),
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _mostrarDetalleReporte(context, quedada, service);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarDetalleReporte(BuildContext context, Quedada quedada, QuedadasService service) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(AppSpacing.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EventCard(
                      quedada: quedada,
                      isJoined: false, 
                    ),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.lg)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                              ),
                              onPressed: () async {
                                final confirm = await _pedirConfirmacion(
                                  dialogContext, 
                                  AppLocalizations.get('dismiss_reports'), 
                                  "¿Estás seguro de que quieres ignorar estos reportes?" // TODO translate later if needed
                                );
                                if (confirm == true) {
                                  Navigator.pop(dialogContext);
                                  await service.desestimarReportes(quedada.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(AppLocalizations.get('dismissed_success')), backgroundColor: AppColors.success),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.check_circle_outline),
                              label: Text(AppLocalizations.get('dismiss_reports')),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.error,
                              ),
                              onPressed: () async {
                                final confirm = await _pedirConfirmacion(
                                  dialogContext, 
                                  AppLocalizations.get('delete_event_title'), 
                                  AppLocalizations.get('confirm_delete_event')
                                );
                                if (confirm == true) {
                                  Navigator.pop(dialogContext);
                                  await service.eliminarQuedada(quedada.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(AppLocalizations.get('event_deleted_msg')), backgroundColor: AppColors.success),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.delete_outline),
                              label: Text(AppLocalizations.get('delete_event_title')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _pedirConfirmacion(BuildContext context, String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.get('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppLocalizations.get('accept')),
          ),
        ],
      ),
    );
  }
}
