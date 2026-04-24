import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../app_theme.dart';

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  bool _isLoading = false;

  Future<void> _eliminarCuenta() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final db = FirebaseFirestore.instance;
      final batch = db.batch(); 

      final quedadasRef = db.collection('quedadas');
      final notifRef = db.collection('notificaciones');
      
      final queryByUid = await quedadasRef.where('organizador', isEqualTo: user.uid).get();
      for (var doc in queryByUid.docs) {
        batch.update(doc.reference, {'estado': 'cancelado'});
        
        final data = doc.data();
        final asistentes = data['asistentesID'] as List<dynamic>? ?? [];
        final titulo = data['titulo'] ?? 'Unnamed Plan';
        final fechaRaw = data['fechaInicio'];
        String infoFecha = '';
        if (fechaRaw is Timestamp) {
          infoFecha = ' (${DateFormat('dd/MM/yyyy HH:mm').format(fechaRaw.toDate())})';
        }
        
        for (final asistenteId in asistentes) {
          final newNotifRef = notifRef.doc();
          batch.set(newNotifRef, {
            'userId': asistenteId,
            'mensaje': 'The plan "$titulo"$infoFecha has been cancelled because the organizer closed their account.',
            'fecha': FieldValue.serverTimestamp(),
            'leida': false,
            'eventoId': doc.id,
          });
        }
      }

      final queryByEmail = await quedadasRef.where('organizador', isEqualTo: user.email).get();
      for (var doc in queryByEmail.docs) {
        batch.update(doc.reference, {'estado': 'cancelado'});

        final data = doc.data();
        final asistentes = data['asistentesID'] as List<dynamic>? ?? [];
        final titulo = data['titulo'] ?? 'Unnamed Plan';
        final fechaRaw = data['fechaInicio'];
        String infoFecha = '';
        if (fechaRaw is Timestamp) {
          infoFecha = ' (${DateFormat('dd/MM/yyyy HH:mm').format(fechaRaw.toDate())})';
        }
        
        for (final asistenteId in asistentes) {
          final newNotifRef = notifRef.doc();
          batch.set(newNotifRef, {
            'userId': asistenteId,
            'mensaje': 'The plan "$titulo"$infoFecha has been cancelled because the organizer closed their account.',
            'fecha': FieldValue.serverTimestamp(),
            'leida': false,
            'eventoId': doc.id,
          });
        }
      }

      final userDoc = db.collection('users').doc(user.uid);
      batch.delete(userDoc);

      await batch.commit();
      await user.delete();

      if (mounted) {
        Navigator.of(context).pop(); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cuenta y datos eliminados correctamente.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        String mensaje = 'Error al eliminar la cuenta.';
        if (e.code == 'requires-recent-login') {
          mensaje = 'Por seguridad, debes cerrar sesión y volver a entrar antes de eliminar tu cuenta.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inesperado: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      child: AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text("Eliminar cuenta", style: AppTextStyles.headlineMedium),
        content: const Text(
          "¿Estás seguro? Esta acción es irreversible.",
          style: AppTextStyles.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: Text(
              "Cancelar",
              style: AppTextStyles.labelLarge.copyWith(
                color: _isLoading ? AppColors.textHint : AppColors.textSecondary
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            onPressed: _isLoading ? null : _eliminarCuenta,
            child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Aceptar"),
          ),
        ],
      ),
    );
  }
}
