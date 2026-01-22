import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../views/screens/profile_screen.dart';
import '../views/screens/settings_screen.dart';
import '../views/screens/auth/login_screen.dart';
import '../utils/logout_modal.dart';


class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Usuario WeatherWay';
    final photoURL = user?.photoURL ??
        'https://www.gravatar.com/avatar/placeholder?d=mp&s=200';

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            accountName: Text(
              displayName,
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(
              user?.email ?? (user == null ? 'Invitado' : ''),
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8)),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundImage: NetworkImage(photoURL),
              onBackgroundImageError: (exception, stackTrace) {
                print('Error cargando imagen de cabecera del drawer: $exception');
              },
              child: photoURL.contains('placeholder') && user != null
                  ? Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 40.0),
              )
                  : (user == null ? const Icon(Icons.person, size: 40) : null),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Ver perfil'),
            onTap: () {
              Navigator.pop(context);
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Debes iniciar sesión para ver tu perfil.')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Ajustes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const Spacer(),
          const Divider(height: 1),
          if (user != null)
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Cerrar sesión', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {


                final confirmLogout = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => const LogoutModal(),
                );
                if (!context.mounted) return;

                if (confirmLogout == true) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (spinnerContext) => const Dialog(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );

                  try {
                    final googleSignIn = GoogleSignIn();
                    await googleSignIn.disconnect().catchError((_) {});
                    await googleSignIn.signOut().catchError((_) {});
                    await FirebaseAuth.instance.signOut();

                    if (!context.mounted) return;

                    Navigator.of(context, rootNavigator: true).pop();
                    Navigator.pop(context);
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (loginContext) => const LoginScreen()),
                            (route) => false);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sesión cerrada correctamente')),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    Navigator.of(context, rootNavigator: true).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al cerrar sesión: $e')),
                    );
                  }
                }

              },
            )
          else
            ListTile(
              leading: const Icon(Icons.login, color: Colors.green),
              title: const Text('Iniciar sesión', style: TextStyle(color: Colors.green)),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false);
              },
            ),
        ],
      ),
    );
  }
}
