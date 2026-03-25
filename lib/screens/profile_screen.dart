import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _nameController.text = "Usuario Estudiante"; 
    _emailController.text = "usuario@correo.com";

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

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface, // Fondo blanco puro
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg), // Bordes redondeados del sistema
          ),
          title: const Text("Eliminar cuenta", style: AppTextStyles.headlineMedium),
          content: const Text(
            "¿Estás seguro? Esta acción es irreversible.",
            style: AppTextStyles.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "Cancelar",
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error, // Rojo del sistema
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); 
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Cuenta eliminada correctamente.'),
                    backgroundColor: AppColors.error, // Rojo del sistema
                  ),
                );
              },
              child: const Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Fondo gris suave del sistema
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Mi Perfil', style: AppTextStyles.headlineMedium),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg), // Espaciado del sistema
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- FOTO DE PERFIL ---
            const CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.primaryLight, // Azul clarito del sistema
              child: Icon(Icons.person, size: 60, color: AppColors.primary), // Azul principal
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              "Toca para cambiar la foto", 
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint), // Texto gris
            ),
            
            const SizedBox(height: AppSpacing.xl),

            // --- TARJETA DE FORMULARIO (Usa tu AppCard) ---
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

            // --- BOTÓN PRIMARIO (Usa tu AppPrimaryButton) ---
            AppPrimaryButton(
              label: 'Guardar Cambios',
              // Si el botón no está habilitado, pasamos null para que se desactive
              onPressed: _isSaveEnabled ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Perfil actualizado con éxito"),
                    backgroundColor: AppColors.success, // Verde del sistema
                  ),
                );
              } : null,
            ),

            const SizedBox(height: AppSpacing.xxl),

            // --- BOTÓN ELIMINAR CUENTA ---
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error, // Rojo del sistema
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onPressed: _showDeleteConfirmationDialog,
                child: Text('Eliminar cuenta', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}