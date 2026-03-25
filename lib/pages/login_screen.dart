import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _cifController = TextEditingController();

  bool _isLogin = true;
  bool _isVerifiedOrganizer = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _companyNameController.dispose();
    _cifController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'GoTogether · Acceso' : 'GoTogether · Registro'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLogin ? '¡Hola de nuevo!' : 'Únete a GoTogether',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _isLogin
                              ? 'Accede a tu cuenta para descubrir y crear planes.'
                              : 'Regístrate y empieza a organizar quedadas con el estilo de la app.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white.withOpacity(0.92),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isLogin ? 'Iniciar sesión' : 'Crear cuenta',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _isLogin
                              ? 'Introduce tu email y contraseña.'
                              : 'Completa tus datos para crear tu perfil.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (!_isLogin) ...[
                          TextField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Tu nombre',
                              hintText: 'Ejemplo: Náyade o Miguel',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'tu@email.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                            hintText: 'Mínimo 6 caracteres',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                        ),
                        if (!_isLogin) ...[
                          const SizedBox(height: AppSpacing.lg),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: SwitchListTile.adaptive(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              title: Text(
                                'Soy organizador verificado',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              subtitle: Text(
                                'Activa esta opción si registras una empresa u organización.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              value: _isVerifiedOrganizer,
                              onChanged: (value) {
                                setState(() {
                                  _isVerifiedOrganizer = value;
                                });
                              },
                            ),
                          ),
                          if (_isVerifiedOrganizer) ...[
                            const SizedBox(height: AppSpacing.md),
                            TextField(
                              controller: _companyNameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Nombre de la empresa',
                                prefixIcon: Icon(Icons.business_outlined),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextField(
                              controller: _cifController,
                              decoration: const InputDecoration(
                                labelText: 'CIF / NIF',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                            ),
                          ],
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        AppPrimaryButton(
                          label: _isLogin ? 'Iniciar sesión' : 'Registrarme',
                          icon: _isLogin
                              ? Icons.login_rounded
                              : Icons.person_add_alt_1_rounded,
                          isLoading: _isSubmitting,
                          onPressed: _isSubmitting ? null : _submit,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () {
                                  setState(() {
                                    _isLogin = !_isLogin;
                                    _isVerifiedOrganizer = false;
                                  });
                                },
                          child: Text(
                            _isLogin
                                ? '¿No tienes cuenta? Regístrate aquí'
                                : '¿Ya tienes cuenta? Inicia sesión',
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
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final companyName = _companyNameController.text.trim();
    final cif = _cifController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Introduce un email y una contraseña válidos.');
      return;
    }

    if (!_isLogin && name.isEmpty) {
      _showMessage('Introduce tu nombre para completar el registro.');
      return;
    }

    if (!_isLogin && _isVerifiedOrganizer && (companyName.isEmpty || cif.isEmpty)) {
      _showMessage('Completa el nombre de empresa y el CIF/NIF.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        _showMessage('Sesión iniciada correctamente.');
      } else {
        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await userCredential.user?.updateDisplayName(name);
        await userCredential.user?.sendEmailVerification();

        final userData = <String, dynamic>{
          'nombre': name,
          'email': email,
          'puntos': 0,
          'fechaRegistro': DateTime.now(),
          'rol': _isVerifiedOrganizer ? 'verificado' : 'usuario',
        };

        if (_isVerifiedOrganizer) {
          userData['nombreEmpresa'] = companyName;
          userData['cif'] = cif;
          userData['estadoVerificacion'] = 'pendiente';
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user?.uid)
            .set(userData);

        _showMessage(
          'Registro completado. Te hemos enviado un correo de verificación.',
        );
      }
    } on FirebaseAuthException catch (error) {
      _showMessage(_mapFirebaseAuthError(error));
    } catch (error) {
      _showMessage('Ha ocurrido un error inesperado: $error');
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  String _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'El formato del email no es válido.';
      case 'user-disabled':
        return 'Esta cuenta está deshabilitada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Las credenciales no son correctas.';
      case 'email-already-in-use':
        return 'Ese email ya está registrado.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      case 'too-many-requests':
        return 'Demasiados intentos. Inténtalo más tarde.';
      default:
        return error.message ?? 'No se pudo completar la operación.';
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
