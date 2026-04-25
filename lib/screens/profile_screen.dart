import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final bool showScaffold;

  const ProfileScreen({super.key, this.showScaffold = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _cifController = TextEditingController();

  final GlobalKey<FormState> _emailFormKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordForEmailController = TextEditingController();
  final TextEditingController _newEmailInputController = TextEditingController();
  bool _isChangingEmail = false;

  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordForPwdController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isChangingPassword = false;
  bool _isVerificationLoading = false;
  String? _passwordAuthErrorForPwd;
  String? _passwordAuthErrorForEmail;
  String? _emailBackendError;

  bool _obscurePwdEmail = true;
  bool _obscureCurrentPwd = true;
  bool _obscureNewPwd = true;
  bool _obscureConfirmPwd = true;

  bool _isSaveEnabled = false;
  bool _isLoading = false;

  String? _photoUrl;
  String _rol = 'usuario';
  String? _estadoVerificacion;

  final List<String> _avataresDisponibles = [
    'assets/images/avatars/avatar1.png',
    'assets/images/avatars/avatar2.png',
    'assets/images/avatars/avatar3.png',
    'assets/images/avatars/avatar4.png',
    'assets/images/avatars/avatar5.png',
    'assets/images/avatars/avatar6.png',
  ];

  @override
  void initState() {
    super.initState();
    _emailController.text = FirebaseAuth.instance.currentUser?.email ?? '';
    _cargarDatosUsuario();

    _nameController.addListener(_validateForm);
    _bioController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _companyNameController.dispose();
    _cifController.dispose();
    _currentPasswordForEmailController.dispose();
    _newEmailInputController.dispose();
    _currentPasswordForPwdController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isSaveEnabled = _nameController.text.trim().isNotEmpty;
    });
  }

  Future<void> _cargarDatosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data() ?? {};
        setState(() {
          _nameController.text = data['nombre'] ?? user.displayName ?? '';
          _emailController.text = data['email'] ?? user.email ?? '';
          _photoUrl = data['fotoUrl'] ?? user.photoURL;
          _bioController.text = data['bio'] ?? '';
          _companyNameController.text = data['nombreEmpresa'] ?? '';
          _cifController.text = data['cif'] ?? '';
          _rol = data['rol'] ?? 'usuario';
          _estadoVerificacion = data['estadoVerificacion'];
        });
        _validateForm();
      }
    } catch (e) {
      debugPrint('Error al cargar perfil: $e');
    }
  }

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
                const Text('Choose your Avatar', style: AppTextStyles.headlineMedium),
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

  Future<void> _guardarDatosBasicos() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final previousName = user.displayName;
      final previousPhoto = user.photoURL;
      final nuevoNombre = _nameController.text.trim();
      final nuevaBio = _bioController.text.trim();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'nombre': nuevoNombre,
        'bio': nuevaBio,
        if (_photoUrl != null) 'fotoUrl': _photoUrl,
      });

      await user.updateDisplayName(nuevoNombre);
      if (_photoUrl != null) await user.updatePhotoURL(_photoUrl);

      await FirebaseFirestore.instance.collection('historial_perfiles').add({
        'userId': user.uid,
        'fecha': FieldValue.serverTimestamp(),
        'cambioNombre': nuevoNombre != previousName,
        'cambioFoto': _photoUrl != previousPhoto,
        'cambioBio': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _pedirConfirmacionPeligrosa(String titulo, String mensaje) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text(
                titulo,
                style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
              ),
              content: Text(mensaje, style: AppTextStyles.bodyLarge),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes, I am sure'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _actualizarCorreo() async {
    if (!_emailFormKey.currentState!.validate()) return;

    final confirmado = await _pedirConfirmacionPeligrosa(
      'Change Email',
      'Are you sure you want to change your email address?',
    );

    if (!confirmado) return;

    setState(() => _isChangingEmail = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final nuevoCorreo = _newEmailInputController.text.trim();

      final existingUsers = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: nuevoCorreo)
          .get();

      if (existingUsers.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This email is already registered to another account.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isChangingEmail = false);
        }
        return;
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordForEmailController.text,
      );
      await user.reauthenticateWithCredential(credential);

      await user.verifyBeforeUpdateEmail(nuevoCorreo);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'email': nuevoCorreo,
      });

      setState(() {
        _emailController.text = nuevoCorreo;
        _currentPasswordForEmailController.clear();
        _newEmailInputController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check your new email inbox to verify it.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        setState(() => _passwordAuthErrorForEmail = 'Incorrect password.');
        _emailFormKey.currentState!.validate();
      } else {
        String mensaje = 'Error changing email.';
        if (e.code == 'email-already-in-use') {
          mensaje = 'This email is already registered to another account.';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isChangingEmail = false);
    }
  }

  Future<void> _actualizarPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    final confirmado = await _pedirConfirmacionPeligrosa(
      'Change Password',
      'Are you sure you want to change your password?',
    );

    if (!confirmado) return;

    setState(() => _isChangingPassword = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordForPwdController.text,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPasswordController.text);

      await FirebaseFirestore.instance.collection('historial_perfiles').add({
        'userId': user.uid,
        'fecha': FieldValue.serverTimestamp(),
        'cambioPassword': true,
      });

      setState(() {
        _currentPasswordForPwdController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        setState(() => _passwordAuthErrorForPwd = 'Current password is incorrect.');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error changing password: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      _passwordFormKey.currentState!.validate();
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  Future<void> _submitVerificationRequest() async {
    if (_companyNameController.text.trim().isEmpty || _cifController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes completar el nombre de empresa y el CIF/NIF.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isVerificationLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'nombreEmpresa': _companyNameController.text.trim(),
        'cif': _cifController.text.trim(),
        'rol': 'usuario',
        'estadoVerificacion': 'pendiente',
        'fechaSolicitudVerificacion': FieldValue.serverTimestamp(),
        'revisadoPor': FieldValue.delete(),
        'fechaRevision': FieldValue.delete(),
      });

      if (mounted) {
        setState(() {
          _rol = 'usuario';
          _estadoVerificacion = 'pendiente';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud enviada correctamente.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enviando la solicitud: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerificationLoading = false);
    }
  }

  Future<void> _confirmLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, log out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

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
              title: const Text(
                'Delete account',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Are you sure? This action is irreversible.',
                    style: AppTextStyles.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'For security, confirm your password:',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          if (passwordController.text.trim().isEmpty) return;

                          setStateDialog(() => isDeleting = true);
                          try {
                            final user = FirebaseAuth.instance.currentUser!;

                            AuthCredential credential = EmailAuthProvider.credential(
                              email: user.email!,
                              password: passwordController.text.trim(),
                            );
                            await user.reauthenticateWithCredential(credential);

                            final db = FirebaseFirestore.instance;

                            final queryByName = await db
                                .collection('quedadas')
                                .where('organizador', isEqualTo: _nameController.text.trim())
                                .get();
                            for (final doc in queryByName.docs) {
                              await doc.reference.delete();
                            }

                            try {
                              await db.collection('users').doc(user.uid).delete();
                            } catch (_) {}

                            await user.delete();

                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Account deleted successfully.'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } on FirebaseAuthException catch (e) {
                            String mensaje = 'Error deleting account.';
                            if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
                              mensaje = 'Incorrect password.';
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
                            );
                          } finally {
                            setStateDialog(() => isDeleting = false);
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Accept'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildVerificationSection() {
    final isVerified = _rol == 'verificado' || _estadoVerificacion == 'aprobado';
    final isPending = _estadoVerificacion == 'pendiente';
    final isRejected = _estadoVerificacion == 'rechazado';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Solicitud de verificación',
                style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.normal),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (isVerified) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.10),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified, color: AppColors.success),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Tu cuenta ya está verificada.',
                      style: AppTextStyles.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            if (isPending)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_top, color: AppColors.warning),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Tu solicitud está pendiente de revisión por un administrador.',
                        style: AppTextStyles.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            if (isRejected)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: AppColors.error),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Tu solicitud fue rechazada. Puedes corregir los datos y volver a enviarla.',
                          style: AppTextStyles.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const Text(
              'Completa estos datos para solicitar la verificación como organizador.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _companyNameController,
              enabled: !isPending && !_isVerificationLoading,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Empresa',
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _cifController,
              enabled: !isPending && !_isVerificationLoading,
              decoration: const InputDecoration(
                labelText: 'CIF / NIF',
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppPrimaryButton(
              label: isRejected ? 'Reenviar solicitud' : 'Enviar solicitud',
              isLoading: _isVerificationLoading,
              onPressed: isPending || _isVerificationLoading ? null : _submitVerificationRequest,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          if (!widget.showScaffold)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('My Profile', style: AppTextStyles.headlineMedium),
              ),
            ),
          GestureDetector(
            onTap: _mostrarSelectorAvatar,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty
                      ? (_photoUrl!.startsWith('http')
                          ? NetworkImage(_photoUrl!) as ImageProvider
                          : AssetImage(_photoUrl!))
                      : const AssetImage('assets/images/avatars/default_avatar.png'),
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
          Text(
            'Tap to choose avatar',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _emailController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'Use the section below to change it',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _bioController,
                  maxLines: 4,
                  maxLength: 150,
                  decoration: const InputDecoration(
                    labelText: 'About me',
                    hintText: 'e.g., I love hiking and board games...',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppPrimaryButton(
            label: 'Save Changes',
            isLoading: _isLoading,
            onPressed: _isSaveEnabled && !_isLoading ? _guardarDatosBasicos : null,
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildVerificationSection(),
          const SizedBox(height: AppSpacing.xl),
          const Divider(),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(
                'Change Email',
                style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.normal),
              ),
              leading: const Icon(Icons.email_outlined, color: AppColors.primary),
              iconColor: AppColors.primary,
              childrenPadding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Form(
                  key: _emailFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'For security, enter your current password to confirm.',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _currentPasswordForEmailController,
                        obscureText: _obscurePwdEmail,
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePwdEmail ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.textHint,
                            ),
                            onPressed: () => setState(() => _obscurePwdEmail = !_obscurePwdEmail),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (_passwordAuthErrorForEmail != null) return _passwordAuthErrorForEmail;
                          return null;
                        },
                        onChanged: (val) {
                          if (_passwordAuthErrorForEmail != null) {
                            setState(() => _passwordAuthErrorForEmail = null);
                          }
                          if (_emailBackendError != null) {
                            setState(() => _emailBackendError = null);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _newEmailInputController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'New Email Address'),
                        validator: (value) {
                          if (_emailBackendError != null) return _emailBackendError;
                          if (value == null || value.isEmpty) return 'Required';
                          if (!value.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppPrimaryButton(
                        label: 'Update Email',
                        isLoading: _isChangingEmail,
                        onPressed: _isChangingEmail ? null : _actualizarCorreo,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text(
                'Change Password',
                style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.normal),
              ),
              leading: const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
              iconColor: AppColors.primary,
              childrenPadding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Form(
                  key: _passwordFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _currentPasswordForPwdController,
                        obscureText: _obscureCurrentPwd,
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCurrentPwd ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.textHint,
                            ),
                            onPressed: () => setState(() => _obscureCurrentPwd = !_obscureCurrentPwd),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (_passwordAuthErrorForPwd != null) return _passwordAuthErrorForPwd;
                          return null;
                        },
                        onChanged: (val) {
                          if (_passwordAuthErrorForPwd != null) {
                            setState(() => _passwordAuthErrorForPwd = null);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNewPwd,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPwd ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.textHint,
                            ),
                            onPressed: () => setState(() => _obscureNewPwd = !_obscureNewPwd),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (value.length < 6) return 'Minimum 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPwd,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPwd ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.textHint,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPwd = !_obscureConfirmPwd),
                          ),
                        ),
                        validator: (value) {
                          if (value != _newPasswordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppPrimaryButton(
                        label: 'Update Password',
                        isLoading: _isChangingPassword,
                        onPressed: _isChangingPassword ? null : _actualizarPassword,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.textHint),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                onPressed: _isLoading ? null : _confirmLogout,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Log out', style: TextStyle(fontSize: 14)),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                onPressed: _isLoading ? null : _showDeleteConfirmationDialog,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Delete account', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showScaffold) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('My Profile', style: AppTextStyles.headlineMedium),
          elevation: 0,
        ),
        body: _buildContent(),
      );
    }

    return Container(
      color: AppColors.background,
      child: _buildContent(),
    );
  }
}
