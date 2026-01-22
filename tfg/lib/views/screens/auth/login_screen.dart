import 'package:WeatherWay/views/screens/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _signInWithEmailAndPassword() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      print('Login con email falló: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fallo al iniciar sesión. Verifica tus datos.')),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;

      if (user != null) {
        final docRef = FirebaseFirestore.instance.collection('Usuarios').doc(user.uid);
        final doc = await docRef.get();

        if (!doc.exists) {
          await docRef.set({
            'id': user.uid,
            'nombre': user.displayName ?? '',
            'email': user.email ?? '',
            'fotoPerfil': user.photoURL ?? '',
            'fechaRegistro': FieldValue.serverTimestamp(),
            'ubicacion': {
              'latitud': 0.0,
              'longitud': 0.0,
            },
          });
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      print('Error en login con Google: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fallo en el inicio de sesión con Google')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    border: const OutlineInputBorder(),
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
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _signInWithEmailAndPassword,
                  child: const Text('Iniciar sesión'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  child: const Text('¿No tienes cuenta? Regístrate'),
                ),


                const SizedBox(height: 16),
                const Text('O inicia sesión con'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: signInWithGoogle,
                  icon: const Icon(Icons.login),
                  label: const Text('Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
