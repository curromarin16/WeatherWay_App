import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Usuario WeatherWay';
    final email = user?.email ?? 'No disponible';
    final photoURL = user?.photoURL ?? 'https://www.gravatar.com/avatar/placeholder?d=mp&s=200';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        elevation: 1,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(photoURL),
                onBackgroundImageError: (exception, stackTrace) {
                  print('Error cargando imagen de perfil: $exception');
                },
              ),
              const SizedBox(height: 24),
              Text(
                displayName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                email,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar Perfil'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Función de editar perfil próximamente.')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
