import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../app_theme.dart';
import '../../../models/quedada.dart';
import '../../../services/quedadas_service.dart';
import '../../../utils/translations.dart';

class EventCard extends StatefulWidget {
  final Quedada quedada;
  final QuedadasService service;

  const EventCard({
    super.key,
    required this.quedada,
    required this.service,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  static String _capitalizar(String valor) {
    if (valor.isEmpty) return valor;
    return valor[0].toUpperCase() + valor.substring(1);
  }

  Future<void> _confirmarEliminarQuedada() async {
    final confirmar = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete event'),
            content: Text('Are you sure you want to delete "${widget.quedada.titulo}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmar) return;

    try {
      await widget.service.eliminarQuedada(widget.quedada.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quedada = widget.quedada;
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
              if (isCurrentUserOrganizer) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _confirmarEliminarQuedada,
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
                  translateStatus(quedada.estado),
                  style: AppTextStyles.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // --- MOSTRAR FECHAS ---
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
                spots > 0 ? 'Join' : 'Full',
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
}
