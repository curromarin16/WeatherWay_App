import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_webservice/places.dart';
import '../../utils/api_keys.dart';

import '../models/Place.dart';
import '../utils/app_constants.dart';

class PlacesService {
  final GoogleMapsPlaces _places;

  PlacesService(String apiKey) : _places = GoogleMapsPlaces(apiKey: apiKey);

  Future<List<String>> getNearbyCategories(double lat, double lng) async {
    final location = Location(lat: lat.toDouble(), lng: lng.toDouble());
    final foundCategories = <String>{};

    for (String type in nearbySearchSupportedTypes) {
      final response = await _places.searchNearbyWithRadius(
        location,
        30000,
        type: type,
      );

      if (response.status == 'OK' && response.results.isNotEmpty) {
        print('Tipo encontrado: $type (${response.results.length} lugares)');
        foundCategories.add(type);
      } else {
        print('Sin resultados para: $type');
      }

      await Future.delayed(const Duration(milliseconds: 300));
    }

    return foundCategories.toList();
  }

  Place placeFromSearchResult(PlacesSearchResult result) {
    return Place(
      id: result.placeId ?? '',
      name: result.name ?? '',
      latitude: result.geometry?.location.lat ?? 0.0,
      longitude: result.geometry?.location.lng ?? 0.0,
      rating: (result.rating ?? 0).toDouble(),
      address: result.vicinity ?? '',
      phoneNumber: '',
      website: '',
      photoUrl: '',
      openNow: result.openingHours?.openNow ?? false,
      openingHours: [],
    );
  }

  Future<List<Place>> getNearbyPlaces({
    required double lat,
    required double lng,
    required String type,
  }) async {
    final rawResults = await getPlacesByCategory(lat, lng, type);

    return rawResults.map((r) => Place(
      id: r.placeId ?? '',
      name: r.name ?? '',
      latitude: r.geometry?.location.lat ?? 0.0,
      longitude: r.geometry?.location.lng ?? 0.0,
      rating: (r.rating ?? 0).toDouble(),
      address: r.vicinity ?? '',
      phoneNumber: '',
      website: '',
      photoUrl: '',
      openNow: r.openingHours?.openNow ?? false,
      openingHours: [],
    )).toList();
  }

  Future<List<PlacesSearchResult>> getPlacesByCategory(
      double lat, double lng, String category) async {
    final location = Location(lat: lat, lng: lng);
    final response = await _places.searchNearbyWithRadius(
      location,
      30000,
      type: category,
    );


    if (response.status == 'OK' && response.results.isNotEmpty) {
      for (var place in response.results) {
        print(' ${place.name} - ${place.vicinity}');
      }
      return response.results;
    } else {
      print(' No se encontraron lugares ');
      return [];
    }
  }

  Future<void> saveCategoriesToFirestore(List<String> categories) async {

    final firestore = FirebaseFirestore.instance;
    final collection = firestore.collection('categorias');

    for (var type in categories) {
      final docRef = collection.doc(type);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        final translated = categoryTranslations[type] ?? type;
        await docRef.set({
          'id': type,
          'nombre': translated,
        });
        print(' Categoría guardada: $type');
      } else {
        print('Categoría ya existente: $type');
      }

      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<Place?> getPlaceDetails(String placeId) async {
    final response = await _places.getDetailsByPlaceId(placeId);
    if (response.status == 'OK') {
      final detail = response.result;
      return Place(
        id: detail.placeId ?? '',
        name: detail.name ?? '',
        latitude: detail.geometry?.location.lat ?? 0.0,
        longitude: detail.geometry?.location.lng ?? 0.0,
        rating: (detail.rating ?? 0).toDouble(),
        address: detail.formattedAddress ?? '',
        phoneNumber: detail.formattedPhoneNumber ?? '',
        website: detail.website ?? '',
        photoUrl: (detail.photos != null && detail.photos!.isNotEmpty)
            ? _getPhotoUrl(detail.photos!.first.photoReference)
            : '',
        openNow: detail.openingHours?.openNow ?? false,
        openingHours: detail.openingHours?.weekdayText ?? [],
      );
    } else {
      print('Error al obtener detalles $placeId: ${response.status}');
      return null;
    }
  }
  String _getPhotoUrl(String photoReference) {
    return 'https://maps.googleapis.com/maps/api/place/photo'
        '?maxwidth=400'
        '&photoreference=$photoReference'
        '&key=${ApiKeys.googleMaps}';
  }




}
