import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// TODO: Cambia esta ruta por la ruta real de tu archivo de estilos
import '../app_theme.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isSaveEnabled = false;
  bool _isLoading = false; // Añadimos estado de carga para no saturar botones

  @override
  void initState() {
    super.initState();
    // Cargamos los datos reales del usuario si existen
    final user = FirebaseAuth.instance.currentUser;
    _nameController.text = user?.displayName ?? "Usuario Estudiante"; 
    _emailController.text = user?.email ?? "usuario@correo.com";

    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    
    _validateForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isSaveEnabled = _nameController.text.trim().isNotEmpty && 
                       _emailController.text.trim().isNotEmpty;
    });
  }

  // --- LÓGICA BACKEND: HU-03 Borrado en cascada ---
  Future<void> _eliminarCuenta() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final db = FirebaseFirestore.instance;
      final batch = db.batch(); // Usamos un batch para ejecutar todo de golpe

      // 1. Buscar eventos activos del usuario y marcarlos como "Cancelado"
      // Nota: Buscamos tanto por UID como por email por seguridad, según cómo los guardéis
      final quedadasRef = db.collection('quedadas');
      
      final queryByUid = await quedadasRef.where('organizador', isEqualTo: user.uid).get();
      for (var doc in queryByUid.docs) {
        batch.update(doc.reference, {'estado': 'cancelado'});
      }

      final queryByEmail = await quedadasRef.where('organizador', isEqualTo: user.email).get();
      for (var doc in queryByEmail.docs) {
        batch.update(doc.reference, {'estado': 'cancelado'});
      }

      // 2. Eliminar el documento del usuario en Firestore (si tenéis colección 'users')
      final userDoc = db.collection('users').doc(user.uid);
      batch.delete(userDoc);

      // 3. Ejecutar todos los cambios en la base de datos
      await batch.commit();

      // 4. Eliminar el usuario de Firebase Auth
      await user.delete();
      
      // Al hacer delete(), el StreamBuilder del main.dart detectará la salida
      // y mandará al usuario al Login automáticamente, cumpliendo el último criterio.

      if (mounted) {
        Navigator.of(context).pop(); // Cerramos el cuadro de diálogo
        // El SnackBar puede que no se vea mucho tiempo porque viaja al login rápido, 
        // pero lo dejamos por consistencia y UX.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cuenta y datos eliminados correctamente.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Firebase a veces pide re-autenticar por seguridad antes de borrar una cuenta
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

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: !_isLoading, // Evita cerrar si está cargando
      builder: (BuildContext context) {
        return AlertDialog(
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
              onPressed: _isLoading ? null : _eliminarCuenta, // <-- Llamamos a la lógica
              child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Mi Perfil', style: AppTextStyles.headlineMedium),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.person, size: 60, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              "Toca para cambiar la foto", 
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
            ),
            
            const SizedBox(height: AppSpacing.xl),

            AppCard(
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    style: AppTextStyles.bodyLarge,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: AppTextStyles.bodyLarge,
                    readOnly: true, // Hacemos el email de solo lectura temporalmente
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: AppTextStyles.bodyLarge,
                    decoration: const InputDecoration(
                      labelText: 'Nueva Contraseña (opcional)',
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),

            AppPrimaryButton(
              label: 'Guardar Cambios',
              onPressed: _isSaveEnabled ? () {
                // TODO: HU-05 Guardar cambios
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Perfil actualizado con éxito"),
                    backgroundColor: AppColors.success,
                  ),
                );
              } : null,
            ),

            const SizedBox(height: AppSpacing.xxl),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onPressed: _isLoading ? null : _showDeleteConfirmationDialog,
                child: Text('Eliminar cuenta', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}