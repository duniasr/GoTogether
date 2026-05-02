import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../app_theme.dart';

class AuthForm extends StatefulWidget {
  final bool isLogin;
  final VoidCallback onToggleMode;

  const AuthForm({
    super.key,
    required this.isLogin,
    required this.onToggleMode,
  });

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _cifController = TextEditingController();
  final TextEditingController _adminCodeController = TextEditingController();

  static const String _adminSecretCode = '1515453820';

  bool _isVerifiedOrganizer = false;
  bool _isAdmin = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _backendEmailError;
  String? _backendPasswordError;
  String? _backendAdminCodeError;

  @override
  void didUpdateWidget(AuthForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLogin != widget.isLogin) {
      _formKey.currentState?.reset();
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _companyNameController.clear();
      _cifController.clear();
      _adminCodeController.clear();
      _backendEmailError = null;
      _backendPasswordError = null;
      _backendAdminCodeError = null;
      _isVerifiedOrganizer = false;
      _isAdmin = false;
      _obscurePassword = true;
      _obscureConfirmPassword = true;
    }
  }

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
    return RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9-]+\.[a-zA-Z]+",
    ).hasMatch(email);
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
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      if (widget.isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        UserCredential user = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        if (_isAdmin && _adminCodeController.text.trim() != _adminSecretCode) {
          await user.user?.delete();
          setState(() {
            _backendAdminCodeError = 'Código de administrador incorrecto';
          });
          _formKey.currentState!.validate();
          return;
        }

        await user.user!.sendEmailVerification();

        Map<String, dynamic> userData = {
          'nombre': _nameController.text.trim(),
          'email': email,
          'puntos': 0,
          'fechaRegistro': DateTime.now(),
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

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.user!.uid)
            .set(userData);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _backendEmailError = "Invalid email";
        } else if (e.code == 'wrong-password' ||
            e.code == 'invalid-credential') {
          _backendPasswordError = "Incorrect password";
        } else if (e.code == 'invalid-email') {
          _backendEmailError = "Invalid email";
        } else if (e.code == 'email-already-in-use') {
          _backendEmailError = "Email already registered";
        } else {
          _showError("An error occurred: ${e.message}");
        }
      });
      _formKey.currentState!.validate();
    } catch (e) {
      _showError("Error: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: AppShadows.card,
                  ),
                  child: Image.asset(
                    'assets/images/Logo.png',
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.image_not_supported,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                widget.isLogin ? 'Welcome Back!' : 'Create Account',
                style: AppTextStyles.displayMedium.copyWith(
                  color: AppColors.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.isLogin
                    ? 'Sign in to continue to GoTogether'
                    : 'Join GoTogether and find your next plan',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadows.card,
                  border: Border.all(color: AppColors.surfaceAlt, width: 1.5),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    if (!widget.isLogin)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: "Your Name",
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (!widget.isLogin &&
                                (value == null || value.trim().isEmpty)) {
                              return "Name is required";
                            }
                            return null;
                          },
                        ),
                      ),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: "Email",
                        prefixIcon: Icon(Icons.email),
                      ),
                      onChanged: (value) {
                        if (_backendEmailError != null ||
                            _backendPasswordError != null) {
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
                          return "Email is required";
                        }
                        if (!_isValidEmail(value.trim())) {
                          return "Invalid format";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: "Password",
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textHint,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
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
                          return "Password is required";
                        }
                        if (!widget.isLogin && value.length < 6) {
                          return "Password must be at least 6 characters";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (!widget.isLogin)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            hintText: "Confirm Password",
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textHint,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (!widget.isLogin) {
                              if (value == null || value.isEmpty) {
                                return "Confirm your password";
                              }
                              if (value != _passwordController.text) {
                                return "Passwords do not match";
                              }
                            }
                            return null;
                          },
                        ),
                      ),

                    if (widget.isLogin)
                      const SizedBox(height: AppSpacing.sm)
                    else
                      const SizedBox.shrink(),

                    if (!widget.isLogin)
                      Column(
                        children: [
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
                                    "I am a Verified Organizer",
                                    style: AppTextStyles.labelLarge,
                                  ),
                                  value: _isVerifiedOrganizer,
                                  activeColor: AppColors.primary,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                  ),
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
                                    "I am an Admin",
                                    style: AppTextStyles.labelLarge,
                                  ),
                                  value: _isAdmin,
                                  activeColor: AppColors.primary,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                  ),
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
                                    hintText: "Company Name",
                                    prefixIcon: Icon(Icons.business),
                                  ),
                                  validator: (value) {
                                    if (_isVerifiedOrganizer &&
                                        (value == null ||
                                            value.trim().isEmpty)) {
                                      return "Company name is required";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
                                TextFormField(
                                  controller: _cifController,
                                  decoration: const InputDecoration(
                                    hintText: "VAT Number",
                                    prefixIcon: Icon(Icons.badge),
                                  ),
                                  validator: (value) {
                                    if (_isVerifiedOrganizer &&
                                        (value == null ||
                                            value.trim().isEmpty)) {
                                      return "VAT number is required";
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
                                    hintText: "Admin Code",
                                    prefixIcon: Icon(
                                      Icons.admin_panel_settings,
                                    ),
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
                                    if (_isAdmin &&
                                        (value == null ||
                                            value.trim().isEmpty)) {
                                      return "Admin code is required";
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
                      ),

                    const SizedBox(height: AppSpacing.md),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              widget.isLogin ? "Login" : "Register",
                              style: AppTextStyles.button.copyWith(
                                color: Colors.white,
                              ),
                            ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: widget.onToggleMode,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: AppTextStyles.bodyMedium,
                          children: [
                            TextSpan(
                              text: widget.isLogin
                                  ? "Don't have an account? "
                                  : "Already have an account? ",
                            ),
                            TextSpan(
                              text: widget.isLogin ? "Register here" : "Login here",
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
