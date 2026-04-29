import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app_theme.dart';
import '../../../models/quedada.dart';
import '../../../utils/translations.dart';
import '../../../services/quedadas_service.dart';

class EventCard extends StatelessWidget {
  final Quedada quedada;
  final VoidCallback? onDelete;
  final Widget? actionButton;
  final bool isJoined; // <--- Añadido para saber si el usuario está en el plan

  const EventCard({
    super.key,
    required this.quedada,
    this.onDelete,
    this.actionButton,
    this.isJoined = false, // <--- Por defecto es falso para que no rompa el resto de la app
  });

  @override
  Widget build(BuildContext context) {
    final spots = quedada.plazasLibres;
    final maxSpots = quedada.cupoMax;
    final fillRatio = maxSpots > 0
        ? ((maxSpots - spots) / maxSpots).clamp(0.0, 1.0)
        : 0.0;
    final almostFull = spots <= 2 && spots > 0;
    final catColor =
        AppColors.categoryColors[quedada.tematica] ?? AppColors.textSecondary;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  quedada.titulo.isEmpty ? 'No title' : quedada.titulo,
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
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Delete plan',
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: onDelete,
                      child: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Tooltip(
                message: 'Report event',
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _mostrarDialogoReporte(context),
                    child: const Icon(
                      Icons.report_problem_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              CategoryChip(category: quedada.tematica),
              Builder(
                builder: (context) {
                  final bool isOpen = quedada.estado == 'abierta' && spots > 0;
                  final bool isFull = spots <= 0 && quedada.estado != 'cerrada' && quedada.estado != 'cancelada';
                  final String statusText = isFull ? 'Full' : translateStatus(quedada.estado);
                  final Color bgColor = isOpen ? AppColors.success.withOpacity(0.15) : AppColors.error.withOpacity(0.15);
                  final Color textColor = isOpen ? AppColors.success : AppColors.error;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      statusText,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${DateFormat('dd MMM yyyy, HH:mm').format(quedada.fechaInicio)} - ${DateFormat('HH:mm').format(quedada.fechaFin)}',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
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
          
          // === INICIO LÓGICA HU-11 (AFOROS) ===
          if (actionButton != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: actionButton!,
            ),
          ] else if (spots <= 0 && !isJoined) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Text(
                'Fully Booked',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          // === FIN LÓGICA HU-11 ===
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoReporte(BuildContext context) async {
    String motivoSeleccionado = 'Spam';
    final motivos = ['Spam', 'Inappropriate', 'Dangerous'];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (stateContext, setStateDialog) {
            return AlertDialog(
              title: const Text('Report event', style: AppTextStyles.headlineMedium),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Please, select a reason for the report:'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: motivoSeleccionado,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: motivos.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setStateDialog(() => motivoSeleccionado = v);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    try {
                      final service = QuedadasService();
                      await service.reportarQuedada(quedada.id, motivoSeleccionado);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thank you for reporting'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString().replaceAll('Exception: ', '')),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Submit report'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
