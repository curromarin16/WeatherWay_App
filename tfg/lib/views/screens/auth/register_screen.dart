import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();

  Future<void> _register() async {
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;

      if (user != null) {
        await user.updateDisplayName(_nombreController.text.trim());
        await user.reload();

        await FirebaseFirestore.instance.collection('Usuarios').doc(user.uid).set({
          'id': user.uid,
          'nombre': _nombreController.text.trim(),
          'email': user.email ?? '',
          'fotoPerfil': '',
          'fechaRegistro': FieldValue.serverTimestamp(),
          'ubicacion': {
            'latitud': 0.0,
            'longitud': 0.0,
          },
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      String mensaje = 'Fallo al iniciar sesión. Verifica tus datos.';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-email':
            mensaje = 'El correo no es válido.';
            break;
          case 'user-not-found':
            mensaje = 'No se encontró el usuario.';
            break;
          case 'wrong-password':
            mensaje = 'Contraseña incorrecta.';
            break;
          default:
            mensaje = 'Error: verifica la conexión e intentalo de nuevo';
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _register,
              child: const Text('Registrarse'),
            ),
          ],
        ),
      ),
    );
  }
}
