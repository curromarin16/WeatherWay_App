import 'package:flutter/material.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkModeEnabled = false;
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: [
          SwitchListTile(
            title: const Text('Modo Oscuro'),
            subtitle: const Text('Activa o desactiva el tema oscuro de la aplicación.'),
            value: _darkModeEnabled,
            onChanged: (bool value) {
              setState(() {
                _darkModeEnabled = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Modo Oscuro ${value ? "activado" : "desactivado"} (próximamente).')),
              );
            },
            secondary: Icon(_darkModeEnabled ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Notificaciones Push'),
            subtitle: const Text('Recibir alertas y actualizaciones importantes.'),
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Notificaciones ${value ? "activadas" : "desactivadas"} (próximamente).')),
              );
            },
            secondary: Icon(_notificationsEnabled ? Icons.notifications_active_outlined : Icons.notifications_off_outlined),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de WeatherWay'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('WeatherWay,tu app para explorar y descubrir lugares según el clima.'))
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Política de Privacidad'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Abrir enlace a Política de Privacidad (próximamente).')),
              );
            },
          ),
        ],
      ),
    );
  }
}
