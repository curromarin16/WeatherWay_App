import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_constants.dart';
import '../../services/places_services.dart';
import '../../utils/explore_cache.dart';
import '../../utils/network_check.dart';
import '../../utils/api_keys.dart';


class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();

}

class _ExploreScreenState extends State<ExploreScreen> with AutomaticKeepAliveClientMixin {
  String? _selectedCategory;
  GoogleMapController? _mapController;
  LatLng _initialPosition = const LatLng(0.0, 0.0);
  bool _loading = true;
  List<String> _categories = [];
  Set<Marker> _markers = {};
  CameraPosition? _currentCameraPosition;
  final PlacesService _placesService = PlacesService(ApiKeys.googleMaps);


  @override
  void initState() {
    super.initState();
    _loadFromCacheOrInit();
  }


  Future<void> _loadFromCacheOrInit() async {
    if (exploreCache.lastPosition != null) {
      _initialPosition = exploreCache.lastPosition!;
    }
    if (exploreCache.lastZoom != null) {
    }
    if (exploreCache.markers != null) {
      _markers = exploreCache.markers!;
    }
    if (exploreCache.selectedCategory != null) {
      _selectedCategory = exploreCache.selectedCategory;
    }

    if (exploreCache.categories != null) {
      _categories = exploreCache.categories!;
    } else {
      await _fetchCategories();
    }

    if (exploreCache.lastPosition == null) {
      await _getUserLocation();
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _obtenerYGuardarClima() async {
    if (!await checkInternetConnection()) {
      return;
    }
    try {
      final lat = _initialPosition.latitude;
      final lng = _initialPosition.longitude;

      const apiKey = ApiKeys.openWeather
;
      final url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lng&appid=$apiKey&units=metric&lang=es');

      final response = await http.get(url);
      if (response.statusCode != 200) {
        return;
      }

      final data = json.decode(response.body);
      final weather = data['weather'][0];
      final main = data['main'];

      final clima = {
        'id': FirebaseAuth.instance.currentUser?.uid ?? 'sin_usuario',
        'ubicacion': {'latitud': lat, 'longitud': lng},
        'temperatura': main['temp'],
        'humedad': main['humidity'],
        'condicion': weather['description'],
        'fuente': 'OpenWeatherMap',
        'fechaActualizacion': Timestamp.now(),
      };

      await FirebaseFirestore.instance.collection('clima').doc(clima['id']).set(clima);
      print(' Clima guardado');
    } catch (e) {
      print('Error al guardar clima: $e');
    }
  }






  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
        _loading = false;
      });
      exploreCache.lastPosition = _initialPosition;
      await _obtenerYGuardarClima();



      print(" Ubicación obtenida: ${position.latitude}, ${position.longitude}");
    } catch (e) {
      print('Error obteniendo la ubicación: $e');
    }
  }


  Future<void> _fetchCategories() async {
    if (!await checkInternetConnection()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sin conexión. No se pueden cargar las categorías.')),
      );
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categorias')
          .orderBy('nombre')
          .get();

      final tipos = snapshot.docs.map((doc) => doc.id).toList();

      if (!mounted) return;
      setState(() {
        _categories = tipos;
        exploreCache.categories = tipos;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar las categorías.')),
      );
    }
  }


  Future<void> _guardarFavorito(PlacesSearchResult place) async {
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

    final idLugar = place.placeId;
    final docId = "${idUsuario}_$idLugar";
    final docRef = firestore.collection('favoritos').doc(docId);
    final doc = await docRef.get();

    if (doc.exists) return;

    try {
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$idLugar&...&key=${ApiKeys.googleMaps}'
      );
      final response = await http.get(url);

      if (response.statusCode != 200) {
        if (!mounted) return;
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
        'nombre': detalle['name'] ?? place.name,
        'direccion': detalle['formatted_address'] ?? place.vicinity ?? '',
        'telefono': detalle['formatted_phone_number'] ?? '',
        'lat': place.geometry?.location.lat,
        'lng': place.geometry?.location.lng,
        'rating': detalle['rating'] ?? 0.0,
        'totalRatings': detalle['user_ratings_total'] ?? 0,
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Añadido a favoritos")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar: $e")),
      );
    }
  }

  Future<void> _mostrarDetallesLugar(PlacesSearchResult place) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return _PlaceDetailsContent(
          place: place,
          onSaveFavorite: _guardarFavorito,
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        _loading
            ? const Center(child: CircularProgressIndicator())
            : GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _initialPosition,
            zoom: exploreCache.lastZoom ?? 15,
          ),

          onMapCreated: (controller) {
            _mapController = controller;
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          markers: _markers,
          onCameraMove: (CameraPosition position) {
            _currentCameraPosition = position;
          },

          onCameraIdle: () {
            if (_currentCameraPosition != null) {
              exploreCache.lastPosition = _currentCameraPosition!.target;
              exploreCache.lastZoom = _currentCameraPosition!.zoom;
            }
          },

        ),


        // Filtros flotantes
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Column(
            children: [
              // Categorías como chips scrollables
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((type) {
                    final isSelected = _selectedCategory == type;
                    final translated = categoryTranslations[type] ?? type;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        avatar: Icon(
                          getCategoryIcon(type),
                          color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                          size: 18,
                        ),
                        label: Text(translated),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? type : null;
                          });
                        },
                        selectedColor: Theme.of(context).colorScheme.primaryContainer,
                        backgroundColor: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : (isDark ? Colors.grey[800] : Colors.grey[200]),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.black
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),

                      ),
                    );
                  }).toList(),
                ),
              ),


              const SizedBox(height: 8),

              // Botón aplicar
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  Theme.of(context).colorScheme.secondaryContainer,
                  foregroundColor: isDark ? Colors.white : Colors.black,
                ),
                onPressed: () async {
                  if (!await checkInternetConnection()) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sin conexión. No se pueden buscar lugares.')),
                    );
                    return;
                  }

                  if (_selectedCategory == null) return;

                  setState(() {
                    _loading = true;
                  });


                  try {
                    final service = PlacesService(ApiKeys.googleMaps);
                    final results = await service.getPlacesByCategory(
                      _initialPosition.latitude,
                      _initialPosition.longitude,
                      _selectedCategory!,
                    );

                    final newMarkers = results.map((place) {
                      final location = place.geometry?.location;
                      if (location == null) return null;

                      return Marker(
                        markerId: MarkerId(place.placeId),
                        position: LatLng(location.lat, location.lng),
                        infoWindow: InfoWindow(title: place.name),
                        onTap: () => _mostrarDetallesLugar(place),

                      );
                    }).whereType<Marker>().toSet();

                    if (!mounted) return;
                    setState(() {
                      _markers = newMarkers;
                      _selectedCategory = _selectedCategory;
                    });
                    exploreCache.markers = newMarkers;
                    exploreCache.selectedCategory = _selectedCategory;

                    if (_mapController != null && results.isNotEmpty) {
                      final first = results.first.geometry?.location;
                      if (first != null) {
                        _mapController!.animateCamera(
                          CameraUpdate.newLatLngZoom(LatLng(first.lat, first.lng), 14),
                        );
                      }
                    }
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error al buscar lugares. Revisa tu conexión e inténtalo de nuevo.')),
                    );
                  } finally {
                    if (mounted) {
                      setState(() {
                        _loading = false;
                      });
                    }
                  }
                },


                icon: const Icon(Icons.check),
                label: const Text('Aplicar filtros'),
              ),
              if (_selectedCategory != null)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.errorContainer,
                    foregroundColor: isDark ? Colors.white : Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedCategory = null;
                      _markers.clear();
                    });
                    exploreCache.selectedCategory = null;
                    exploreCache.markers = {};
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Borrar filtros'),
                ),



            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;

}
class _PlaceDetailsContent extends StatefulWidget {
  final PlacesSearchResult place;
  final Function(PlacesSearchResult) onSaveFavorite;

  const _PlaceDetailsContent({
    required this.place,
    required this.onSaveFavorite,
  });

  @override
  State<_PlaceDetailsContent> createState() => _PlaceDetailsContentState();
}

class _PlaceDetailsContentState extends State<_PlaceDetailsContent> {
  bool isLoadingDetails = true;
  String? detailsError;
  Map<String, dynamic> details = {};
  bool esFavorito = false;

  @override
  void initState() {
    super.initState();
    _cargarDetalles();
  }

  Future<void> _cargarDetalles() async {
    if (!mounted) return;

    try {
      if (!await checkInternetConnection()) {
        throw Exception('Sin conexión');
      }

      final idUsuario = FirebaseAuth.instance.currentUser?.uid;
      final docId = '${idUsuario}_${widget.place.placeId}';

      final results = await Future.wait([
        FirebaseFirestore.instance.collection('favoritos').doc(docId).get(),
        http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=${widget.place.placeId}&fields=rating,user_ratings_total,opening_hours,website&key=${ApiKeys.googleMaps}',
        )),
      ]);


      if (!mounted) return;

      final docSnap = results[0] as DocumentSnapshot;
      final response = results[1] as http.Response;
      final esFavoritoResult = docSnap.exists;

      if (response.statusCode == 200) {
        final detailsResult = json.decode(response.body)['result'];
        setState(() {
          esFavorito = esFavoritoResult;
          details = detailsResult;
          isLoadingDetails = false;
        });
      } else {
        throw Exception('Error de API');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        detailsError = e.toString().contains('Sin conexión')
            ? 'Sin conexión para cargar detalles.'
            : 'No se pudieron cargar los detalles.';
        isLoadingDetails = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoadingDetails)
            const Center(
              child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()),
            )
          else if (detailsError != null)
            Center(
              child: Padding(padding: const EdgeInsets.all(32.0), child: Text(detailsError!, style: const TextStyle(color: Colors.red))),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.place.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (widget.place.vicinity != null) Text(widget.place.vicinity!),
                const SizedBox(height: 8),
                if (details['rating'] != null)
                  Row(children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    Text(' ${details['rating']} (${details['user_ratings_total'] ?? 0})', style: const TextStyle(fontSize: 14)),
                  ]),
                if (details['opening_hours']?['open_now'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      details['opening_hours']['open_now'] ? 'Abierto ahora' : 'Cerrado ahora',
                      style: TextStyle(
                        color: details['opening_hours']['open_now'] ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                        onPressed: () async {
                          final idUsuario = FirebaseAuth.instance.currentUser?.uid;
                          final docId = '${idUsuario}_${widget.place.placeId}';
                          if (esFavorito) {
                            await FirebaseFirestore.instance.collection('favoritos').doc(docId).delete();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Eliminado de favoritos")));
                          } else {
                            await widget.onSaveFavorite(widget.place);
                          }
                          if (mounted) Navigator.pop(context);
                        },
                        icon: Icon(esFavorito ? Icons.favorite : Icons.favorite_border, color: esFavorito ? Colors.red : null),
                        label: Text(esFavorito ? 'Quitar' : 'Añadir')),
                    ElevatedButton.icon(
                        onPressed: () {
                          final lat = widget.place.geometry?.location.lat;
                          final lng = widget.place.geometry?.location.lng;
                          final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
                          launchUrl(url, mode: LaunchMode.externalApplication);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.map),
                        label: const Text('Abrir con Maps')),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}