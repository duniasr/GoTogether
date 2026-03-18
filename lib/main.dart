import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart'; // Conectamos con tu carpeta screens

void main() async {
  // Nos aseguramos de que Flutter esté listo antes de arrancar Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializamos Firebase con tu configuración mágica
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GoTogether',
      home: LoginScreen(), // Le decimos que la primera pantalla es tu Login
    );
  }
}