import 'package:flutter/material.dart';

class LogoutModal extends StatelessWidget {
  const LogoutModal({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cerrar sesión'),
      content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: const Text(
            'Cerrar sesión',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
