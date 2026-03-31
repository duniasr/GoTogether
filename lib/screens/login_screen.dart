import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'login/widgets/auth_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isLogin ? "GoTogether - Login" : "GoTogether - Register"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: AuthForm(
          isLogin: _isLogin,
          onToggleMode: () {
            setState(() {
              _isLogin = !_isLogin;
            });
          },
        ),
      ),
    );
  }
}
