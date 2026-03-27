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
  bool _isLoading = false; 

  @override
  void initState() {
    super.initState();
    // Ponemos el email rápido sacándolo de Auth
    _emailController.text = FirebaseAuth.instance.currentUser?.email ?? "";
    
    // Llamamos a Firebase para traer el nombre real guardado en el Registro
    _cargarDatosUsuario();

    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
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

  // --- NUEVA LÓGICA: Cargar el nombre desde Firestore ---
  Future<void> _cargarDatosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          // Buscamos el campo 'nombre' que guardaste en el login
          _nameController.text = doc.data()?['nombre'] ?? user.displayName ?? "";
        });
        _validateForm(); // Re-validamos el botón tras cargar el dato
      }
    } catch (e) {
      debugPrint("Error al cargar perfil: $e");
    }
  }

  // --- NUEVA LÓGICA: HU-05 Guardar Cambios ---
  Future<void> _guardarCambios() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final nuevoNombre = _nameController.text.trim();

      // 1. Guardamos el nuevo nombre en la base de datos (Firestore)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'nombre': nuevoNombre,
      });

      // 2. Lo actualizamos en Auth para que HomeScreen pueda decir "¡Hola, [Nombre]!"
      await user.updateDisplayName(nuevoNombre);

      // 3. (Opcional) Si el usuario escribió una nueva contraseña, la actualizamos
      if (_passwordController.text.isNotEmpty) {
        await user.updatePassword(_passwordController.text);
        _passwordController.clear(); // Limpiamos el campo tras cambiarla
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Perfil actualizado con éxito"),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String mensaje = 'Error al actualizar.';
        if (e.code == 'requires-recent-login') {
          mensaje = 'Por seguridad, cierra sesión y vuelve a entrar para cambiar tu contraseña.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inesperado: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LÓGICA BACKEND: HU-03 Borrado en cascada ---
  Future<void> _eliminarCuenta() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      // La colección correcta es 'events' (igual que QuedadasService)
      // El organizador se guarda siempre como uid desde QuedadasService
      final eventsRef = db.collection('events');
      final queryByUid = await eventsRef
          .where('organizador', isEqualTo: user.uid)
          .get();
      for (final doc in queryByUid.docs) {
        batch.delete(doc.reference); // Eliminamos, no actualizamos
      }

      // Eliminamos también el documento del usuario en Firestore
      batch.delete(db.collection('users').doc(user.uid));

      await batch.commit();
      await user.delete(); // Eliminamos la cuenta de Firebase Auth

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta y datos eliminados correctamente.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        String mensaje = 'Error al eliminar la cuenta.';
        if (e.code == 'requires-recent-login') {
          mensaje = 'Por seguridad, cierra sesión y vuelve a entrar antes de eliminar tu cuenta.';
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
      barrierDismissible: !_isLoading, 
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
              onPressed: _isLoading ? null : _eliminarCuenta, 
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
                    readOnly: true, 
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
              isLoading: _isLoading, // Muestra indicador de carga al guardar
              onPressed: _isSaveEnabled && !_isLoading ? _guardarCambios : null,
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