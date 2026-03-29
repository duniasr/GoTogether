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
  // NUEVO: Controlador para el campo "Sobre mí"
  final TextEditingController _bioController = TextEditingController();
  
  bool _isSaveEnabled = false;
  bool _isLoading = false; 

  String? _photoUrl; 
  
  final List<String> _avataresDisponibles = [
    'assets/images/avatars/avatar1.png',
    'assets/images/avatars/avatar2.png',
    'assets/images/avatars/avatar3.png',
    'assets/images/avatars/avatar4.png',
    'assets/images/avatars/avatar5.png',
    'assets/images/avatars/avatar6.png',
    'assets/images/avatars/avatar7.png',
    'assets/images/avatars/avatar8.png',
    'assets/images/avatars/avatar9.png',
    'assets/images/avatars/avatar10.png',
    'assets/images/avatars/avatar11.png',
    'assets/images/avatars/avatar12.png',
    'assets/images/avatars/avatar13.png',
    'assets/images/avatars/avatar14.png',
    'assets/images/avatars/avatar15.png'
  ];

  @override
  void initState() {
    super.initState();
    _emailController.text = FirebaseAuth.instance.currentUser?.email ?? "";
    _cargarDatosUsuario();

    _nameController.addListener(_validateForm);
    _bioController.addListener(_validateForm); // Escuchamos si escribes en la biografía
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      // El botón de guardar se activa siempre que haya un nombre escrito
      _isSaveEnabled = _nameController.text.trim().isNotEmpty;
    });
  }

  Future<void> _cargarDatosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _nameController.text = doc.data()?['nombre'] ?? user.displayName ?? "";
          _emailController.text = doc.data()?['email'] ?? user.email ?? "";
          _photoUrl = doc.data()?['fotoUrl'] ?? user.photoURL;
          // NUEVO: Cargamos la biografía desde Firestore (si existe)
          _bioController.text = doc.data()?['bio'] ?? "";
        });
        _validateForm(); 
      }
    } catch (e) {
      debugPrint("Error al cargar perfil: $e");
    }
  }

  // --- SELECTOR DE AVATARES ---
  void _mostrarSelectorAvatar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg, 
          ),
          child: SingleChildScrollView( 
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Elige tu Avatar', style: AppTextStyles.headlineMedium),
                const SizedBox(height: AppSpacing.md),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, 
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                  ),
                  itemCount: _avataresDisponibles.length,
                  itemBuilder: (context, index) {
                    final avatarPath = _avataresDisponibles[index];
                    final isSelected = _photoUrl == avatarPath;

                    return GestureDetector(
                      onTap: () {
                        setState(() => _photoUrl = avatarPath);
                        _validateForm(); 
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: AppColors.surfaceAlt,
                          backgroundImage: AssetImage(avatarPath),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- GUARDADO BÁSICO (Nombre, Avatar y Biografía) ---
  Future<void> _guardarDatosBasicos() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final nuevoNombre = _nameController.text.trim();
      final nuevaBio = _bioController.text.trim(); // Cogemos el texto de "Sobre mí"

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'nombre': nuevoNombre,
        'bio': nuevaBio, // NUEVO: Guardamos la biografía en la base de datos
        if (_photoUrl != null) 'fotoUrl': _photoUrl, 
      });
      
      await user.updateDisplayName(nuevoNombre);
      if (_photoUrl != null) await user.updatePhotoURL(_photoUrl);

      await FirebaseFirestore.instance.collection('historial_perfiles').add({
        'userId': user.uid,
        'fecha': FieldValue.serverTimestamp(),
        'cambioNombre': nuevoNombre != user.displayName,
        'cambioFoto': true,
        'cambioBio': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Perfil actualizado con éxito"), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- MENSAJE DE ADVERTENCIA UNIVERSAL ---
  Future<bool> _pedirConfirmacionPeligrosa(String titulo, String mensaje) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(titulo, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          content: Text(mensaje, style: AppTextStyles.bodyLarge),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sí, estoy seguro'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // --- DIÁLOGO INDEPENDIENTE: CAMBIAR CORREO ---
  Future<void> _mostrarDialogoCambioCorreo() async {
    final currentPasswordController = TextEditingController();
    final newEmailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isChanging = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text("Cambiar Correo", style: AppTextStyles.headlineMedium),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Por seguridad, necesitamos tu contraseña actual para cambiar tu correo.", style: AppTextStyles.bodyMedium),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: currentPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Contraseña Actual'),
                        validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: newEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Nuevo Correo Electrónico'),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Requerido';
                          if (!value.contains('@')) return 'Correo no válido';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isChanging ? null : () => Navigator.of(context).pop(),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  onPressed: isChanging ? null : () async {
                    if (!formKey.currentState!.validate()) return;

                    final confirmado = await _pedirConfirmacionPeligrosa(
                      'Advertencia de Seguridad',
                      'Estás a punto de cambiar tu correo electrónico. Este cambio es definitivo y lo necesitarás para volver a iniciar sesión. \n\n¿Estás completamente seguro?',
                    );

                    if (!confirmado) return; 

                    setStateDialog(() => isChanging = true);
                    try {
                      final user = FirebaseAuth.instance.currentUser!;
                      
                      AuthCredential credential = EmailAuthProvider.credential(
                        email: user.email!, 
                        password: currentPasswordController.text
                      );
                      await user.reauthenticateWithCredential(credential);

                      final nuevoCorreo = newEmailController.text.trim();
                      await user.verifyBeforeUpdateEmail(nuevoCorreo);

                      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                        'email': nuevoCorreo,
                      });

                      setState(() {
                        _emailController.text = nuevoCorreo;
                      });

                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Revisa la bandeja de entrada de tu nuevo correo para verificarlo.'), backgroundColor: AppColors.success),
                        );
                      }
                    } on FirebaseAuthException catch (e) {
                      String mensaje = 'Error al cambiar correo.';
                      if (e.code == 'wrong-password' || e.code == 'invalid-credential') mensaje = 'La contraseña es incorrecta.';
                      if (e.code == 'email-already-in-use') mensaje = 'Ese correo ya está registrado.';
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: Colors.red));
                    } finally {
                      setStateDialog(() => isChanging = false);
                    }
                  },
                  child: isChanging 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- DIÁLOGO INDEPENDIENTE: CAMBIAR CONTRASEÑA ---
  Future<void> _mostrarDialogoCambioPassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isChanging = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text("Cambiar Contraseña", style: AppTextStyles.headlineMedium),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: currentPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Contraseña Actual'),
                        validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Nueva Contraseña'),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Requerido';
                          if (value.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Confirmar Nueva Contraseña'),
                        validator: (value) {
                          if (value != newPasswordController.text) return 'Las contraseñas no coinciden';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isChanging ? null : () => Navigator.of(context).pop(),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  onPressed: isChanging ? null : () async {
                    if (!formKey.currentState!.validate()) return;

                    final confirmado = await _pedirConfirmacionPeligrosa(
                      'Advertencia de Seguridad',
                      'Vas a cambiar tu contraseña de acceso. ¿Estás seguro de que quieres continuar con este cambio irreversible?',
                    );

                    if (!confirmado) return; 

                    setStateDialog(() => isChanging = true);
                    try {
                      final user = FirebaseAuth.instance.currentUser!;
                      
                      AuthCredential credential = EmailAuthProvider.credential(
                        email: user.email!, 
                        password: currentPasswordController.text
                      );
                      await user.reauthenticateWithCredential(credential);
                      await user.updatePassword(newPasswordController.text);

                      await FirebaseFirestore.instance.collection('historial_perfiles').add({
                        'userId': user.uid,
                        'fecha': FieldValue.serverTimestamp(),
                        'cambioPassword': true,
                      });

                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Contraseña cambiada con éxito.'), backgroundColor: AppColors.success),
                        );
                      }
                    } on FirebaseAuthException catch (e) {
                      String mensaje = 'Error al cambiar contraseña.';
                      if (e.code == 'wrong-password' || e.code == 'invalid-credential') mensaje = 'La contraseña actual es incorrecta.';
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: Colors.red));
                    } finally {
                      setStateDialog(() => isChanging = false);
                    }
                  },
                  child: isChanging 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text("Cambiar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- LÓGICA DE BORRADO DE CUENTA ---
  Future<void> _eliminarCuenta() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final db = FirebaseFirestore.instance;
      final eventsRef = db.collection('events');
      
      final queryByUid = await eventsRef.where('organizador', isEqualTo: user.uid).get();
      for (final doc in queryByUid.docs) {
        await doc.reference.delete();
      }

      try { await db.collection('users').doc(user.uid).delete(); } catch (e) {}

      await user.delete(); 

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuenta eliminada.'), backgroundColor: AppColors.error));
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes volver a iniciar sesión para borrar la cuenta.'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

// --- LÓGICA DE BORRADO DE CUENTA (HU-03 CORREGIDA) ---
  void _showDeleteConfirmationDialog() {
    final passwordController = TextEditingController();
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text("Eliminar cuenta", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("¿Estás seguro? Esta acción es irreversible.", style: AppTextStyles.bodyLarge),
                  const SizedBox(height: AppSpacing.md),
                  const Text("Por seguridad, confirma tu contraseña:", style: AppTextStyles.bodyMedium),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.of(context).pop(), 
                  child: const Text("Cancelar", style: TextStyle(color: AppColors.textSecondary))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                  onPressed: isDeleting ? null : () async {
                    if (passwordController.text.trim().isEmpty) return;

                    setStateDialog(() => isDeleting = true);
                    try {
                      final user = FirebaseAuth.instance.currentUser!;
                      
                      // 1. REAUTENTICAR AL USUARIO (Evita el error de "iniciar sesión de nuevo")
                      AuthCredential credential = EmailAuthProvider.credential(
                        email: user.email!, 
                        password: passwordController.text.trim()
                      );
                      await user.reauthenticateWithCredential(credential);

                      final db = FirebaseFirestore.instance;

                      // 2. ACTUALIZAR ESTADO DE LOS EVENTOS DEL USUARIO
                      // Buscamos por el nombre, ya que es lo que guarda ahora "organizador"
                      final queryByName = await db.collection('events').where('organizador', isEqualTo: _nameController.text.trim()).get();
                      for (final doc in queryByName.docs) {
                        // Cambiamos el estado a cancelada en lugar de borrarlo por completo
                        await doc.reference.update({'estado': 'cancelada'});
                      }

                      // 3. BORRAR DOCUMENTO DE FIRESTORE
                      try { await db.collection('users').doc(user.uid).delete(); } catch (e) {}

                      // 4. BORRAR USUARIO DE AUTHENTICATION
                      await user.delete(); 

                      // 5. REDIRECCIÓN (Si tu app tiene un AuthStateListener en main.dart, 
                      // al hacer user.delete() saltará automáticamente al Login)
                      if (mounted) {
                        Navigator.of(context).pop();
                        // Nota: Puede que este SnackBar no se llegue a ver porque la app te expulsará al Login casi al instante.
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuenta eliminada correctamente.'), backgroundColor: AppColors.success));
                      }
                    } on FirebaseAuthException catch (e) {
                      String mensaje = 'Error al eliminar la cuenta.';
                      if (e.code == 'wrong-password' || e.code == 'invalid-credential') mensaje = 'La contraseña es incorrecta.';
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: Colors.red));
                    } finally {
                      setStateDialog(() => isDeleting = false);
                    }
                  }, 
                  child: isDeleting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Text("Aceptar"),
                ),
              ],
            );
          }
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            GestureDetector(
              onTap: _mostrarSelectorAvatar, 
              child: Stack(
                alignment: Alignment.bottomRight, 
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty 
                        ? AssetImage(_photoUrl!) 
                        : null,
                    
                    child: _photoUrl == null || _photoUrl!.isEmpty
                        ? const Icon(Icons.person, size: 60, color: AppColors.primary)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.edit, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text("Toca para elegir avatar", style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)),
            const SizedBox(height: AppSpacing.xl),

            AppCard(
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre completo'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _emailController,
                    readOnly: true, 
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      hintText: 'Usa el botón de abajo para cambiarlo'
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // NUEVO: Campo Sobre mí
                  TextField(
                    controller: _bioController,
                    maxLines: 4, // Lo hace más alto, como un recuadro
                    maxLength: 150, // Límite de caracteres para que no escriban El Quijote
                    decoration: const InputDecoration(
                      labelText: 'Sobre mí',
                      hintText: 'Ej: Me encanta el senderismo y los juegos de mesa...',
                      alignLabelWithHint: true, // Alinea el texto "Sobre mí" arriba a la izquierda
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),

            AppPrimaryButton(
              label: 'Guardar Cambios',
              isLoading: _isLoading,
              onPressed: _isSaveEnabled && !_isLoading ? _guardarDatosBasicos : null,
            ),

            const SizedBox(height: AppSpacing.xxl),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            SizedBox(
              width: double.infinity, height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
                onPressed: _isLoading ? null : _mostrarDialogoCambioCorreo,
                icon: const Icon(Icons.email_outlined),
                label: const Text('Cambiar Correo Electrónico'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            SizedBox(
              width: double.infinity, height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
                onPressed: _isLoading ? null : _mostrarDialogoCambioPassword,
                icon: const Icon(Icons.lock_reset_rounded),
                label: const Text('Cambiar Contraseña'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            SizedBox(
              width: double.infinity, height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.textPrimary, side: const BorderSide(color: AppColors.textHint)),
                onPressed: _isLoading ? null : () async => await FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesión'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            SizedBox(
              width: double.infinity, height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                onPressed: _isLoading ? null : _showDeleteConfirmationDialog,
                child: const Text('Eliminar cuenta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}