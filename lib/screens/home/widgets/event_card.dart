import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../app_theme.dart';
import '../../../models/quedada.dart';
import '../../../utils/translations.dart';
import '../../../services/quedadas_service.dart';
import '../../map_screen.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';

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
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapScreen(
                          initialCenter: LatLng(quedada.ubicacion.latitude, quedada.ubicacion.longitude),
                        ),
                      ),
                    );
                  },
                  child: FutureBuilder<String>(
                    future: _obtenerDireccion(quedada.ubicacion.latitude, quedada.ubicacion.longitude),
                    builder: (context, snapshot) {
                      final locationText = snapshot.data ?? 'Ver ubicación';
                      return Text(
                        locationText,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ),
              ),
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).get(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data?['rol'] == 'admin') {
                    return IconButton(
                      icon: const Icon(Icons.edit_location_alt_rounded, color: AppColors.primary, size: 20),
                      tooltip: 'Admin: Edit Location',
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () => _mostrarDialogoModificarUbicacion(context),
                    );
                  }
                  return const SizedBox.shrink();
                },
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
              if (quedada.organizadorId == FirebaseAuth.instance.currentUser?.uid)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _mostrarAsistentes(context),
                  icon: const Icon(Icons.people_outline, size: 16, color: AppColors.primary),
                  label: Text(
                    'Attendees (${quedada.asistentesID.length})',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
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

  void _mostrarDialogoModificarUbicacion(BuildContext context) {
    final latController = TextEditingController(text: quedada.ubicacion.latitude.toString());
    final lonController = TextEditingController(text: quedada.ubicacion.longitude.toString());

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Admin: Edit Location', style: AppTextStyles.headlineMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: latController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Latitude'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: lonController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Longitude'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            FilledButton(
              onPressed: () async {
                final lat = double.tryParse(latController.text.trim());
                final lon = double.tryParse(lonController.text.trim());
                if (lat == null || lon == null) return;

                await FirebaseFirestore.instance.collection('events').doc(quedada.id).update({
                  'ubicacion': GeoPoint(lat, lon),
                });

                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Location updated by Admin'), backgroundColor: AppColors.success),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarAsistentes(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Attendees List', style: AppTextStyles.headlineMedium),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .where(FieldPath.documentId, whereIn: quedada.asistentesID.isEmpty ? ['dummy'] : quedada.asistentesID)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty || quedada.asistentesID.isEmpty) {
                  return const Center(
                    child: Text('No attendees yet.', style: AppTextStyles.bodyMedium),
                  );
                }

                final users = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index].data() as Map<String, dynamic>?;
                    final nombre = user?['nombre'] ?? 'Anónimo';
                    final email = user?['email'] ?? 'No email';
                    final fotoUrl = user?['fotoUrl'];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: fotoUrl != null && fotoUrl.toString().startsWith('http')
                            ? NetworkImage(fotoUrl) as ImageProvider
                            : (fotoUrl != null && fotoUrl.toString().isNotEmpty
                                ? AssetImage(fotoUrl) as ImageProvider
                                : const AssetImage('assets/images/avatars/default_avatar.png')),
                      ),
                      title: Text(nombre, style: AppTextStyles.bodyLarge),
                      subtitle: Text(email, style: AppTextStyles.labelSmall),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<String> _obtenerDireccion(double lat, double lon) async {
    if (kIsWeb) {
      try {
        final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon');
        final response = await http.get(url, headers: {
          'User-Agent': 'GoTogetherApp/1.0'
        }).timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final displayName = data['display_name'] as String?;
          if (displayName != null && displayName.isNotEmpty) {
            final parts = displayName.split(',');
            if (parts.length > 2) {
              return '${parts[0].trim()}, ${parts[1].trim()}';
            }
            return displayName;
          }
        }
      } catch (_) {}
      return 'Lat: ${lat.toStringAsFixed(4)}, Lon: ${lon.toStringAsFixed(4)}';
    } else {
      try {
        final placemarks = await placemarkFromCoordinates(lat, lon);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final street = p.street ?? "";
          final locality = p.locality ?? "";
          if (street.isNotEmpty && locality.isNotEmpty) {
            return '$street, $locality';
          } else if (street.isNotEmpty) {
            return street;
          } else if (locality.isNotEmpty) {
            return locality;
          }
        }
      } catch (_) {}
      return 'Lat: ${lat.toStringAsFixed(4)}, Lon: ${lon.toStringAsFixed(4)}';
    }
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
