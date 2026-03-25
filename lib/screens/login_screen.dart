import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. Controladores (Añadido el _nameController)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _cifController = TextEditingController();

  // 2. Variables de estado para cambiar la pantalla
  bool _isLogin = true; // Por defecto empezamos en "Iniciar Sesión"
  bool _isVerifiedOrganizer = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isLogin ? "GoTogether - Acceso" : "GoTogether - Registro", 
                    style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isLogin ? "¡Hola de nuevo!" : "Únete a GoTogether",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // --- CAMPO DE NOMBRE (Solo visible si NO estamos en Login) ---
              Visibility(
                visible: !_isLogin,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Tu Nombre (ej. Náyade, Miguel...)",
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),

              // --- EMAIL Y CONTRASEÑA (Siempre visibles) ---
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // --- SECCIÓN DE EMPRESA (Solo visible si NO estamos en Login) ---
              Visibility(
                visible: !_isLogin,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                      child: SwitchListTile(
                        title: const Text("Soy Organizador Verificado", style: TextStyle(fontWeight: FontWeight.bold)),
                        value: _isVerifiedOrganizer,
                        activeColor: Colors.blueAccent,
                        onChanged: (bool value) {
                          setState(() { _isVerifiedOrganizer = value; });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Visibility(
                      visible: _isVerifiedOrganizer,
                      child: Column(
                        children: [
                          TextField(
                            controller: _companyNameController,
                            decoration: InputDecoration(labelText: "Nombre de la Empresa", prefixIcon: const Icon(Icons.business), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _cifController,
                            decoration: InputDecoration(labelText: "CIF / NIF", prefixIcon: const Icon(Icons.badge), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- BOTÓN PRINCIPAL (Cambia su función y texto) ---
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  try {
                    String email = _emailController.text.trim();
                    String password = _passwordController.text.trim();

                    if (_isLogin) {
                      // 🟢 LÓGICA DE INICIO DE SESIÓN (HU-01)
                      print("⏳ Iniciando sesión...");
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: email, password: password
                      );
                      print("✅ ¡SESIÓN INICIADA CORRECTAMENTE!");
                      // Aquí luego añadiremos el código para saltar a la pantalla del Mapa
                    } else {
                      // 🔵 LÓGICA DE REGISTRO (HU-02 y HU-15)
                      print("⏳ Registrando...");
                      UserCredential user = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                        email: email, password: password
                      );
                      await user.user!.sendEmailVerification(); // Enviamos el email de verificación
                      print("✅ ¡USUARIO REGISTRADO! Verificación enviada a $email");
                      

                      Map<String, dynamic> userData = {
                        'nombre': _nameController.text.trim(), // ¡Aquí guardamos el nombre!
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
                      print("✅ ¡REGISTRO COMPLETADO!");
                    }
                  } catch (e) {
                    print("❌ ERROR: $e");
                    await FirebaseAuth.instance.signOut();
                  }
                },
                child: Text(_isLogin ? "Iniciar Sesión" : "Registrarse", style: const TextStyle(fontSize: 18, color: Colors.white)),
              ),

              // --- BOTÓN PARA CAMBIAR ENTRE LOGIN Y REGISTRO ---
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin; // Esto cambia la pantalla mágicamente
                  });
                },
                child: Text(
                  _isLogin ? "¿No tienes cuenta? Regístrate aquí" : "¿Ya tienes cuenta? Inicia sesión",
                  style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}