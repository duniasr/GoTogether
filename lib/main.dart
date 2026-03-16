import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Tu archivo "mágico"

void main() async {
  // 1. Asegura que Flutter esté listo
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Enciende la conexión con Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MaterialApp(
    home: Scaffold(
      body: Center(
        child: Text('GoTogether: ¡Firebase conectado con éxito! '),
      ),
    ),
  ));
}