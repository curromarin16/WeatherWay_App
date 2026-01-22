import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../models/Place.dart';
import '../../services/places_services.dart';
import '../../services/weather_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/explore_cache.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/api_keys.dart';

import '../../utils/network_check.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  Map<String, dynamic>? _clima;
  List<String> _categoriasSugeridas = [];
  List<Place> _lugaresRecomendados = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  String _fechaActualizacion = '';

  final WeatherService _weatherService = WeatherService();
  final PlacesService _placesService = PlacesService(ApiKeys.googleMaps);

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    print(' Iniciando carga de datos...');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    if (!await checkInternetConnection()) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "No hay conexión a internet. \nNo se pueden cargar las recomendaciones.";
        _isLoading = false;
      });
      return;
    }
    try {
      final position = exploreCache.lastPosition;
      if (position == null) {
        throw Exception('No se encontró la posición del usuario. Asegúrate de tener permisos de ubicación.');
      }


      // cargar clima guardado primero
      Map<String, dynamic>? clima = await _weatherService.obtenerClimaGuardado(
        position.latitude,
        position.longitude,
      );

      //  Si no hay clima guardado o es muy viejo, actualizar desde API
      if (clima == null || !_weatherService.esClimaReciente(clima)) {
        clima = await _weatherService.obtenerClimaActualizado(
          position.latitude,
          position.longitude,
        );
      }

      if (clima != null) {
        setState(() {
          _clima = clima;
          _fechaActualizacion = _weatherService.formatearFechaActualizacion(clima!);
        });

        //  Cargar recomendaciones basadas en el clima
        await _cargarRecomendaciones(clima);

      } else {
        throw Exception('No se pudo obtener la información del clima.');
      }
    } catch (e) {
      print(' Error al cargar datos iniciales: $e');
      setState(() {
        _errorMessage = 'Ocurrió un error. Por favor, intenta de nuevo.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _actualizarClima() async {
    print(' Actualizando clima...');
    if (!await checkInternetConnection()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sin conexión. No se puede actualizar el clima.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      final position = exploreCache.lastPosition;
      if (position == null) {
        throw Exception('No se encontró la posición del usuario.');
      }

      final clima = await _weatherService.obtenerClimaActualizado(
        position.latitude,
        position.longitude,
      );

      if (clima != null) {
        setState(() {
          _clima = clima;
          _fechaActualizacion = _weatherService.formatearFechaActualizacion(clima);
        });

        await _cargarRecomendaciones(clima);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(' Clima actualizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('No se pudo obtener la información del clima actualizada.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: ${e.toString().split(':')[0]}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _cargarRecomendaciones(Map<String, dynamic> clima) async {
    try {
      final position = exploreCache.lastPosition;
      if (position == null) {
        print(' No hay posición para cargar recomendaciones');
        return;
      }

      final condicion = clima['condicion'];
      final pesosCategoria = pesosPorClimaYCategoria[condicion] ?? {};

      print('📋 Categorías para $condicion: ${pesosCategoria.keys.toList()}');

      if (pesosCategoria.isEmpty) {
        setState(() {
          _categoriasSugeridas = [];
          _lugaresRecomendados = [];
        });
        return;
      }

      final Set<String> yaAgregados = {};
      final List<MapEntry<Place, double>> lugaresConPuntaje = [];

      for (final categoria in pesosCategoria.keys) {

        try {
          final resultados = await _placesService.getPlacesByCategory(
            position.latitude,
            position.longitude,
            categoria,
          );

          print(' Encontrados ${resultados.length} lugares de $categoria');

          for (final result in resultados.take(5)) {
            if (yaAgregados.contains(result.placeId)) continue;

            try {
              final lugar = await _placesService.getPlaceDetails(result.placeId);
              if (lugar == null) continue;

              final rating = lugar.rating ?? 0;
              final peso = pesosCategoria[categoria]!;
              final puntuacionFinal = rating * peso;

              lugaresConPuntaje.add(MapEntry(lugar, puntuacionFinal));
              yaAgregados.add(lugar.id);

              print(' Lugar agregado: ${lugar.name} - Rating: $rating - Puntuación: $puntuacionFinal');
            } catch (e) {
              print(' Error al obtener detalles del lugar ${result.placeId}: $e');
              continue;
            }
          }
        } catch (e) {
          print(' Error al buscar lugares de categoría $categoria: $e');
          continue;
        }
      }

      lugaresConPuntaje.sort((a, b) => b.value.compareTo(a.value));
      final lugaresOrdenados = lugaresConPuntaje
          .take(10)
          .map((e) => e.key)
          .toList();

      print(' Lugares finales ordenados: ${lugaresOrdenados.length}');

      setState(() {
        _categoriasSugeridas = pesosCategoria.keys.toList();
        _lugaresRecomendados = lugaresOrdenados;
      });

    } catch (e) {
      setState(() {
        _categoriasSugeridas = [];
        _lugaresRecomendados = [];
      });
    }
  }

  Future<void> _guardarFavoritoDesdePlace(Place lugar) async {
    if (!await checkInternetConnection()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sin conexión. No se pudo añadir a favoritos.')),
      );
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final idUsuario = auth.currentUser?.uid;

    if (idUsuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario no logueado")),
      );
      return;
    }

    final idLugar = lugar.id;
    final docId = "${idUsuario}_$idLugar";
    final docRef = firestore.collection('favoritos').doc(docId);
    final doc = await docRef.get();

    if (doc.exists) return;

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$idLugar&fields=name,formatted_address,formatted_phone_number,geometry,rating,user_ratings_total,opening_hours,photos,website&key=${ApiKeys.googleMaps}',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al obtener detalles del lugar")),
        );
        return;
      }

      final detalle = json.decode(response.body)['result'];

      final data = {
        'id': docId,
        'idLugar': idLugar,
        'idUsuario': idUsuario,
        'nombre': detalle['name'] ?? lugar.name,
        'direccion': detalle['formatted_address'] ?? lugar.address,
        'telefono': detalle['formatted_phone_number'] ?? '',
        'latitude': lugar.latitude,
        'longitude': lugar.longitude,
        'rating': detalle['rating'] ?? lugar.rating ?? 0.0,
        'totalRatings': detalle['user_ratings_total'] ?? lugar.userRatingsTotal ?? 0,
        'website': detalle['website'] ?? '',
        'fotoRef': detalle['photos'] != null && detalle['photos'].isNotEmpty
            ? detalle['photos'][0]['photo_reference']
            : null,
        'horarios': detalle['opening_hours'] != null
            ? traducirHorarios(detalle['opening_hours']['weekday_text'])
            : [],
        'fechaAgregado': Timestamp.now(),
      };

      await docRef.set(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Añadido a favoritos sabes")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar: $e")),
      );
    }
  }

  void _abrirEnGoogleMaps(Place lugar) async {
    if (!await checkInternetConnection()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sin conexión. No se puede abrir en Google Maps.')),
      );
      return;
    }
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(lugar.name ?? '')}&query_place_id=${lugar.id}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir Google Maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {



    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando el clima y las mejores recomendaciones...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _errorMessage!.contains("conexión")
                    ? const Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 48)
                    : const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _errorMessage!.contains("conexión") ? Colors.orange.shade800 : Colors.red,
                      fontSize: 16
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _cargarDatosIniciales,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }


    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _actualizarClima,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            //Card del Clima con botón de actualizar
            if (_clima != null) ...[
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade100.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      weatherIcons[_clima!['condicion']] ?? Icons.cloud,
                      size: 60,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      weatherDescriptions[_clima!['condicion']] ?? 'Condición Desconocida',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_clima!['temperatura'].toStringAsFixed(1)}°C',
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                    ),
                    Text(
                      'Humedad: ${_clima!['humedad']}%',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),

                    // Información de actualización
                    if (_fechaActualizacion.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Actualizado: $_fechaActualizacion',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Botón de actualizar
                    ElevatedButton.icon(
                      onPressed: _isRefreshing ? null : _actualizarClima,
                      icon: _isRefreshing
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : const Icon(Icons.refresh),
                      label: Text(_isRefreshing ? 'Actualizando...' : 'Actualizar clima'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Sección Categorías Recomendadas
            if (_categoriasSugeridas.isNotEmpty) ...[
              const Text(
                'Explora según el clima:',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _categoriasSugeridas
                    .map((cat) => Chip(
                  label: Text(
                    categoryTranslations[cat] ?? cat.replaceAll('_', ' '),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  avatar: Icon(
                    getCategoryIcon(cat),
                    color: Colors.white,
                  ),
                  backgroundColor: Colors.teal.shade400,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  elevation: 3,
                ))
                    .toList(),
              ),
              const SizedBox(height: 32),
            ],

            // Sección Lugares Sugeridos
            if (_lugaresRecomendados.isNotEmpty) ...[
              const Text(
                'Lugares sugeridos para ti:',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              ..._lugaresRecomendados.map((lugar) => Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          lugar.photoUrl.isNotEmpty
                              ? lugar.photoUrl
                              : 'https://via.placeholder.com/400x180?text=Sin+imagen',
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 180,
                              width: double.infinity,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 50),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),
                      Text(
                        lugar.name ?? 'Lugar Desconocido',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lugar.address.isNotEmpty ? lugar.address : 'Dirección no disponible',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (lugar.rating != null && lugar.rating! > 0)
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              lugar.rating!.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            if (lugar.userRatingsTotal != null)
                              Text(
                                ' (${lugar.userRatingsTotal} opiniones)',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _abrirEnGoogleMaps(lugar),
                              icon: const Icon(Icons.map),
                              label: const Text('Abrir en Maps'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseAuth.instance.currentUser?.uid == null
                                  ? null
                                  : FirebaseFirestore.instance
                                  .collection('favoritos')
                                  .doc("${FirebaseAuth.instance.currentUser!.uid}_${lugar.id}")
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                                  //loader
                                  return ElevatedButton.icon(
                                    onPressed: null,
                                    icon: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                                    label: const Text('Favorito'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.shade400,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  );
                                }

                                final bool esFavorito = snapshot.hasData && snapshot.data!.exists;

                                return ElevatedButton.icon(
                                  onPressed: () async {
                                    if (!await checkInternetConnection()) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Sin conexión. No se pudo actualizar el favorito.')),
                                      );
                                      return;
                                    }

                                    final idUsuario = FirebaseAuth.instance.currentUser?.uid;
                                    if (idUsuario == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Debes iniciar sesión para gestionar favoritos.")),
                                      );
                                      return;
                                    }
                                    final docId = "${idUsuario}_${lugar.id}";
                                    final docRef = FirebaseFirestore.instance.collection('favoritos').doc(docId);

                                    if (esFavorito) {
                                      await docRef.delete();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Eliminado de favoritos")),
                                        );
                                      }
                                    } else {
                                      await _guardarFavoritoDesdePlace(lugar);
                                    }
                                  },
                                  icon: Icon(
                                    esFavorito ? Icons.favorite : Icons.favorite_border,
                                    color: esFavorito ? Colors.white : Colors.white,
                                  ),
                                  label: Text(esFavorito ? 'Quitar Favorito' : 'Añadir Favorito'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: esFavorito ? Colors.red.shade400 : Colors.pink.shade400,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
            ],

            if (_lugaresRecomendados.isEmpty && _clima != null) ...[
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'No encontramos lugares sugeridos para estas categorías y clima. ¡Intenta de nuevo más tarde!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}