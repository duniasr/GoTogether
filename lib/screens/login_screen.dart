import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _adminSecretCode = '1515453820';

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _cifController = TextEditingController();
  final TextEditingController _adminCodeController = TextEditingController();

  bool _isLogin = true;
  bool _isVerifiedOrganizer = false;
  bool _isAdmin = false;
  bool _isLoading = false;

  String? _backendEmailError;
  String? _backendPasswordError;
  String? _backendAdminCodeError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyNameController.dispose();
    _cifController.dispose();
    _adminCodeController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9-]+\.[a-zA-Z]+")
        .hasMatch(email);
  }

  Future<void> _submit() async {
    setState(() {
      _backendEmailError = null;
      _backendPasswordError = null;
      _backendAdminCodeError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        UserCredential user = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (_isAdmin && _adminCodeController.text.trim() != _adminSecretCode) {
          await user.user?.delete();
          setState(() {
            _backendAdminCodeError = 'Código de administrador incorrecto';
          });
          _formKey.currentState!.validate();
          return;
        }

        await user.user!.sendEmailVerification();

        final Map<String, dynamic> userData = {
          'nombre': _nameController.text.trim(),
          'email': email,
          'puntos': 0,
          'fechaRegistro': FieldValue.serverTimestamp(),
          'rol': _isAdmin ? 'admin' : 'usuario',
        };

        if (_isAdmin) {
          userData['estadoVerificacion'] = null;
        } else if (_isVerifiedOrganizer) {
          userData['nombreEmpresa'] = _companyNameController.text.trim();
          userData['cif'] = _cifController.text.trim();
          userData['estadoVerificacion'] = 'pendiente';
          userData['fechaSolicitudVerificacion'] = FieldValue.serverTimestamp();
        }

        await FirebaseFirestore.instance.collection('users').doc(user.user!.uid).set(userData);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _backendEmailError = 'Email inválido';
        } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _backendPasswordError = 'Contraseña incorrecta';
        } else if (e.code == 'invalid-email') {
          _backendEmailError = 'Email inválido';
        } else if (e.code == 'email-already-in-use') {
          _backendEmailError = 'Ese email ya está registrado';
        } else {
          _showError('Ocurrió un error: ${e.message}');
        }
      });
      _formKey.currentState!.validate();
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleAuthMode() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _companyNameController.clear();
    _cifController.clear();
    _adminCodeController.clear();

    setState(() {
      _backendEmailError = null;
      _backendPasswordError = null;
      _backendAdminCodeError = null;
      _isVerifiedOrganizer = false;
      _isAdmin = false;
      _isLogin = !_isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isLogin ? 'GoTogether - Acceso' : 'GoTogether - Registro'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/Logo.png',
                    height: 160,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (!_isLogin)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tu Nombre',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (!_isLogin && (value == null || value.trim().isEmpty)) {
                          return 'El nombre es obligatorio';
                        }
                        return null;
                      },
                    ),
                  ),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  onChanged: (value) {
                    if (_backendEmailError != null || _backendPasswordError != null) {
                      setState(() {
                        _backendEmailError = null;
                        _backendPasswordError = null;
                      });
                      _formKey.currentState!.validate();
                    }
                  },
                  validator: (value) {
                    if (_backendEmailError != null) {
                      return _backendEmailError;
                    }
                    if (value == null || value.trim().isEmpty) {
                      return 'El email es obligatorio';
                    }
                    if (!_isValidEmail(value.trim())) {
                      return 'Formato inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  onChanged: (value) {
                    if (_backendPasswordError != null) {
                      setState(() {
                        _backendPasswordError = null;
                      });
                      _formKey.currentState!.validate();
                    }
                  },
                  validator: (value) {
                    if (_backendPasswordError != null) {
                      return _backendPasswordError;
                    }
                    if (value == null || value.isEmpty) {
                      return 'La contraseña es obligatoria';
                    }
                    if (!_isLogin && value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                if (!_isLogin)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar Contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (!_isLogin) {
                          if (value == null || value.isEmpty) {
                            return 'Confirma tu contraseña';
                          }
                          if (value != _passwordController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                if (!_isLogin) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: AppShadows.card,
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text(
                            'Soy Organizador Verificado',
                            style: AppTextStyles.labelLarge,
                          ),
                          value: _isVerifiedOrganizer,
                          activeColor: AppColors.primary,
                          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          onChanged: (bool value) {
                            setState(() {
                              _isVerifiedOrganizer = value;
                              if (value) {
                                _isAdmin = false;
                                _adminCodeController.clear();
                                _backendAdminCodeError = null;
                              }
                            });
                          },
                        ),
                        SwitchListTile(
                          title: const Text(
                            'Soy Administrador',
                            style: AppTextStyles.labelLarge,
                          ),
                          value: _isAdmin,
                          activeColor: AppColors.primary,
                          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          onChanged: (bool value) {
                            setState(() {
                              _isAdmin = value;
                              if (value) {
                                _isVerifiedOrganizer = false;
                                _companyNameController.clear();
                                _cifController.clear();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_isVerifiedOrganizer)
                    Column(
                      children: [
                        TextFormField(
                          controller: _companyNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de la Empresa',
                            prefixIcon: Icon(Icons.business),
                          ),
                          validator: (value) {
                            if (_isVerifiedOrganizer && (value == null || value.trim().isEmpty)) {
                              return 'El nombre de la empresa es obligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _cifController,
                          decoration: const InputDecoration(
                            labelText: 'CIF / NIF',
                            prefixIcon: Icon(Icons.badge),
                          ),
                          validator: (value) {
                            if (_isVerifiedOrganizer && (value == null || value.trim().isEmpty)) {
                              return 'El CIF/NIF es obligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  if (_isAdmin)
                    Column(
                      children: [
                        TextFormField(
                          controller: _adminCodeController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Código de administrador',
                            prefixIcon: Icon(Icons.admin_panel_settings),
                          ),
                          onChanged: (_) {
                            if (_backendAdminCodeError != null) {
                              setState(() {
                                _backendAdminCodeError = null;
                              });
                              _formKey.currentState!.validate();
                            }
                          },
                          validator: (value) {
                            if (_isAdmin && (value == null || value.trim().isEmpty)) {
                              return 'El código de administrador es obligatorio';
                            }
                            if (_backendAdminCodeError != null) {
                              return _backendAdminCodeError;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                ],
                const SizedBox(height: AppSpacing.md),
                AppPrimaryButton(
                  label: _isLogin ? 'Iniciar Sesión' : 'Registrarse',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: _toggleAuthMode,
                  child: Text(
                    _isLogin
                        ? '¿No tienes cuenta? Regístrate aquí'
                        : '¿Ya tienes cuenta? Inicia sesión',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
