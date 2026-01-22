import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/network_check.dart';
import '../../utils/api_keys.dart';


class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    const apiKey = ApiKeys.googleMaps
;
    return Scaffold(
      body: userId == null
          ? const Center(child: Text("Inicia sesión para ver tus favoritos."))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('favoritos')
            .where('idUsuario', isEqualTo: userId)
            .orderBy('fechaAgregado', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("Error del Stream de Firestore: ${snapshot.error}");
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      "Sin conexión a internet",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "No se pueden cargar tus favoritos. Por favor, revisa tu conexión.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Aún no has añadido ningún favorito."));
          }

          final favs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favs.length,
            itemBuilder: (context, index) {
              final data = favs[index].data() as Map<String, dynamic>;
              final fecha = (data['fechaAgregado'] as Timestamp).toDate();
              final fechaFormateada =
              DateFormat('dd/MM/yyyy – HH:mm').format(fecha);

              final fotoRef = data['fotoRef'];
              final fotoUrl = fotoRef != null
                  ? 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$fotoRef&key=$apiKey'
                  : null;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
                color: isDark ? Colors.grey[850] : Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen superior
                    if (fotoUrl != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(
                          fotoUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 180,
                              color: isDark ? Colors.grey[800] : Colors.grey.shade200,
                              child: SizedBox(
                                width: double.infinity,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.signal_wifi_off_rounded, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text("No se pudo cargar la imagen"),
                                  ],
                                ),
                              ),
                            );
                          },

                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre
                          Text(
                            data['nombre'] ?? 'Sin nombre',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Dirección
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 18, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  data['direccion'] ?? 'Dirección no disponible',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Teléfono
                          if (data['telefono'] != null && data['telefono'].toString().isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.phone_outlined, size: 18, color: Colors.grey.shade600),
                                const SizedBox(width: 6),
                                Text(
                                  data['telefono'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 6),

                          // Website
                          if (data['website'] != null && data['website'].toString().isNotEmpty)
                            GestureDetector(
                              onTap: () async {
                                if (!await checkInternetConnection()) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Sin conexión para abrir el sitio web.')),
                                  );
                                  return;
                                }
                                final url = Uri.parse(data['website']);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                }
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.link_outlined, size: 18, color: Colors.grey.shade600),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      data['website'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 6),

                          // Rating
                          if (data['rating'] != null && data['rating'] > 0)
                            Row(
                              children: [
                                Icon(Icons.star, size: 18, color: Colors.amber.shade600),
                                const SizedBox(width: 6),
                                Text(
                                  "${data['rating'].toString()} ★ (${data['totalRatings'] ?? 0} opiniones)",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 6),

                          // Coordenadas
                          Row(
                            children: [
                              Icon(Icons.map_outlined, size: 18, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(
                                "Lat: ${data['lat']?.toStringAsFixed(5)}, Lng: ${data['lng']?.toStringAsFixed(5)}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Horarios
                          if (data['horarios'] != null && data['horarios'] is List && (data['horarios'] as List).isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
                                    const SizedBox(width: 6),
                                    const Text("Horarios:"),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.only(left: 24.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: List<String>.from(data['horarios']).map(
                                          (dia) => Text(
                                        dia,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? Colors.white60 : Colors.black54,
                                        ),
                                      ),
                                    ).toList(),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 6),

                          // Fecha de guardado
                          Row(
                            children: [
                              Icon(Icons.favorite_border, size: 18, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(
                                'Guardado el: $fechaFormateada',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          // Botones de acción
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (data['telefono'] != null && data['telefono'].toString().isNotEmpty)
                                TextButton.icon(
                                  onPressed: () async {
                                    final rawTelefono = data['telefono'].toString();
                                    final telefonoLimpio = rawTelefono.replaceAll(RegExp(r'\s+|-|\(|\)'), '');
                                    final telefonoFormateado = telefonoLimpio.startsWith('+')
                                        ? telefonoLimpio
                                        : '+34$telefonoLimpio';

                                    final uri = Uri.parse('tel:$telefonoFormateado');
                                    print('Intentando llamar a: $uri');

                                    try {
                                      final success = await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                      if (!success) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("No se pudo iniciar el marcador ")),
                                        );
                                      }
                                    } catch (e) {
                                      print('Error al intentar llamar: $e');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Error al intentar llamar ")),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.call_outlined, color: Colors.green),
                                  label: const Text(
                                    "Llamar",
                                    style: TextStyle(color: Colors.green),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () async {
                                  // Comprobación de red para eliminar
                                  if (!await checkInternetConnection()) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Sin conexión. No se pudo eliminar.')),
                                    );
                                    return;
                                  }

                                  // Confirmación  borrar
                                  final confirmar = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirmar eliminación'),
                                      content: const Text('¿Estás seguro de que quieres eliminar este lugar de tus favoritos?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmar != true) return;

                                  try {
                                    final docId = data['id'];
                                    await FirebaseFirestore.instance
                                        .collection('favoritos')
                                        .doc(docId)
                                        .delete();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Favorito eliminado.')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Error al eliminar. Intenta de nuevo.')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                label: const Text(
                                  "Eliminar",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}