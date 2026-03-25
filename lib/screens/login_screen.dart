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
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _cifController = TextEditingController();

  bool _isLogin = true;
  bool _isVerifiedOrganizer = false;
  bool _isLoading = false;

  // Variables para mostrar errores del backend directamente en los TextFields
  String? _backendEmailError;
  String? _backendPasswordError;

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
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9-]+\.[a-zA-Z]+").hasMatch(email);
  }

  Future<void> _submit() async {
    // Limpiamos los errores del backend antes de volver a intentar
    setState(() {
      _backendEmailError = null;
      _backendPasswordError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() { _isLoading = true; });

    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      if (_isLogin) {
        // Consultamos Firestore para ver si el correo existe y sortear el 'invalid-credential' genérico
        final query = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).limit(1).get();
        if (query.docs.isEmpty) {
          setState(() { _backendEmailError = "Email inválido"; });
          _formKey.currentState!.validate();
          setState(() { _isLoading = false; });
          return;
        }

        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email, password: password
        );
      } else {
        UserCredential user = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email, password: password
        );
        await user.user!.sendEmailVerification();
        
        Map<String, dynamic> userData = {
          'nombre': _nameController.text.trim(),
          'email': email,
          'puntos': 0,
          'fechaRegistro': DateTime.now(),
          'rol': _isVerifiedOrganizer ? 'verificado' : 'usuario',
        };

        if (_isVerifiedOrganizer) {
          userData['nombreEmpresa'] = _companyNameController.text.trim();
          userData['cif'] = _cifController.text.trim();
          userData['estadoVerificacion'] = 'pendiente';
        }

        await FirebaseFirestore.instance.collection('users').doc(user.user!.uid).set(userData);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _backendEmailError = "Email inválido";
        } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _backendPasswordError = "Contraseña incorrecta";
        } else if (e.code == 'invalid-email') {
          _backendEmailError = "Email inválido";
        } else if (e.code == 'email-already-in-use') {
          _backendEmailError = "Ese email ya está registrado";
        } else {
          _showError("Ocurrió un error: ${e.message}");
        }
      });
      // Volvemos a validar para que se muestren los textos en rojo
      _formKey.currentState!.validate();
    } catch (e) {
      _showError("Error: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isLogin ? "GoTogether - Acceso" : "GoTogether - Registro"),
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
                // Logo de la Aplicación
                Center(
                  child: Image.asset(
                    'assets/images/Logo.png',
                    height: 160, // Logo mediano
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // --- CAMPO DE NOMBRE ---
                if (!_isLogin)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Tu Nombre",
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (!_isLogin && (value == null || value.trim().isEmpty)) {
                          return "El nombre es obligatorio";
                        }
                        return null;
                      },
                    ),
                  ),

                // --- EMAIL ---
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email",
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
                      return "El email es obligatorio";
                    }
                    if (!_isValidEmail(value.trim())) {
                      return "Formato inválido";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // --- CONTRASEÑA ---
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Contraseña",
                    prefixIcon: Icon(Icons.lock),
                  ),
                  onChanged: (value) {
                    if (_backendPasswordError != null) {
                      setState(() { _backendPasswordError = null; });
                      _formKey.currentState!.validate();
                    }
                  },
                  validator: (value) {
                    if (_backendPasswordError != null) {
                      return _backendPasswordError;
                    }
                    if (value == null || value.isEmpty) {
                      return "La contraseña es obligatoria";
                    }
                    if (!_isLogin && value.length < 6) {
                      return "La contraseña debe tener al menos 6 caracteres";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // --- CONFIRMAR CONTRASEÑA ---
                if (!_isLogin)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Confirmar Contraseña",
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (!_isLogin) {
                          if (value == null || value.isEmpty) {
                            return "Confirma tu contraseña";
                          }
                          if (value != _passwordController.text) {
                            return "Las contraseñas no coinciden";
                          }
                        }
                        return null;
                      },
                    ),
                  ),

                if (_isLogin) const SizedBox(height: AppSpacing.sm) else const SizedBox.shrink(),

                // --- SECCIÓN DE EMPRESA ---
                if (!_isLogin)
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.surface, 
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          boxShadow: AppShadows.card,
                        ),
                        child: SwitchListTile(
                          title: const Text("Soy Organizador Verificado", style: AppTextStyles.labelLarge),
                          value: _isVerifiedOrganizer,
                          activeColor: AppColors.primary,
                          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          onChanged: (bool value) {
                            setState(() { _isVerifiedOrganizer = value; });
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_isVerifiedOrganizer)
                        Column(
                          children: [
                            TextFormField(
                              controller: _companyNameController,
                              decoration: const InputDecoration(
                                labelText: "Nombre de la Empresa", 
                                prefixIcon: Icon(Icons.business),
                              ),
                              validator: (value) {
                                if (_isVerifiedOrganizer && (value == null || value.trim().isEmpty)) {
                                  return "El nombre de la empresa es obligatorio";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _cifController,
                              decoration: const InputDecoration(
                                labelText: "CIF / NIF", 
                                prefixIcon: Icon(Icons.badge),
                              ),
                              validator: (value) {
                                if (_isVerifiedOrganizer && (value == null || value.trim().isEmpty)) {
                                  return "El CIF/NIF es obligatorio";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ),
                    ],
                  ),

                const SizedBox(height: AppSpacing.md),

                // --- BOTÓN PRINCIPAL ---
                AppPrimaryButton(
                  label: _isLogin ? "Iniciar Sesión" : "Registrarse",
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),

                const SizedBox(height: AppSpacing.md),

                // --- BOTÓN PARA CAMBIAR ENTRE LOGIN Y REGISTRO ---
                TextButton(
                  onPressed: () {
                    // Limpiar formulario al cambiar de vista
                    _formKey.currentState?.reset();
                    _nameController.clear();
                    _emailController.clear();
                    _passwordController.clear();
                    _confirmPasswordController.clear();
                    _companyNameController.clear();
                    _cifController.clear();

                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                  child: Text(
                    _isLogin ? "¿No tienes cuenta? Regístrate aquí" : "¿Ya tienes cuenta? Inicia sesión",
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
