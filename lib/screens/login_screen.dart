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
      backgroundColor: const Color(
        0xFFF8FAFC,
      ), // A very light, clean grey-white
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _LoginBackgroundPainter()),
          ),
          SafeArea(
            child: AuthForm(
              isLogin: _isLogin,
              onToggleMode: () {
                setState(() {
                  _isLogin = !_isLogin;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bluePaint = Paint()
      ..color = AppColors.primary.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    final yellowPaint = Paint()
      ..color = AppColors.warning.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    final darkBluePaint = Paint()
      ..color = AppColors.primaryDark.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    // Top-left blue wave
    final path1 = Path();
    path1.moveTo(0, 0);
    path1.lineTo(size.width * 0.6, 0);
    path1.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.15,
      0,
      size.height * 0.25,
    );
    path1.close();
    canvas.drawPath(path1, bluePaint);

    // Top-right yellow wave
    final path2 = Path();
    path2.moveTo(size.width, 0);
    path2.lineTo(size.width * 0.6, 0);
    path2.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.1,
      size.width,
      size.height * 0.25,
    );
    path2.close();
    canvas.drawPath(path2, yellowPaint);

    // Bottom-left yellow wave
    final path3 = Path();
    path3.moveTo(0, size.height);
    path3.lineTo(0, size.height * 0.6);
    path3.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.8,
      size.width * 0.6,
      size.height,
    );
    path3.close();
    canvas.drawPath(path3, yellowPaint);

    // Bottom-right dark blue wave
    final path4 = Path();
    path4.moveTo(size.width, size.height);
    path4.lineTo(size.width, size.height * 0.45);
    path4.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.6,
      size.width * 0.5,
      size.height,
    );
    path4.close();
    canvas.drawPath(path4, darkBluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
