import 'package:flutter/material.dart';




const List<String> nearbySearchSupportedTypes = [
  'restaurant',
  'cafe',
  'bar',
  'supermarket',
  'pharmacy',
  'hospital',
  'bank',
  'church',
  'movie_theater',
  'park',
  'tourist_attraction',
  'museum',
  'shopping_mall',
  'clothing_store',
  'shoe_store',
  'art_gallery',
  'zoo',
  'amusement_park',
];

const Map<String, String> categoryTranslations = {
  'restaurant': 'Restaurantes',
  'cafe': 'Cafeterías',
  'bar': 'Bares',
  'supermarket': 'Supermercados',
  'pharmacy': 'Farmacias',
  'hospital': 'Hospitales',
  'bank': 'Bancos',
  'church': 'Iglesias',
  'movie_theater': 'Cines',
  'park': 'Parques',
  'tourist_attraction': 'Atracciones Turísticas',
  'museum': 'Museos',
  'shopping_mall': 'Centros Comerciales',
  'clothing_store': 'Tiendas de ropa',
  'shoe_store': 'Tiendas de Zapatos',
  'art_gallery': 'Galerías de Arte',
  'zoo': 'Zoológicos',
  'amusement_park': 'Parques de Atracciones',
  'point_of_interest': 'Puntos de Interés',
};

List<String> traducirHorarios(List<dynamic> horariosEn) {
  final dias = {
    'Monday': 'Lunes',
    'Tuesday': 'Martes',
    'Wednesday': 'Miércoles',
    'Thursday': 'Jueves',
    'Friday': 'Viernes',
    'Saturday': 'Sábado',
    'Sunday': 'Domingo',
  };

  return horariosEn.map<String>((h) {
    for (final dia in dias.keys) {
      if (h.startsWith(dia)) {
        return h.replaceFirst(dia, dias[dia]!);
      }
    }
    return h;
  }).toList();
}

final Map<String, List<String>> categoriasPorClima = {
  'Clear': ['park', 'tourist_attraction', 'art_gallery'],
  'Rain': ['museum', 'shopping_mall', 'cafe'],
  'Clouds': ['museum', 'art_gallery'],
  'Snow': ['shopping_mall', 'museum'],
  'Drizzle': ['cafe', 'movie_theater'],
  'Thunderstorm': ['museum', 'movie_theater'],
  'Mist': ['cafe'],
};

final Map<String, Map<String, double>> pesosPorClimaYCategoria = {
  'Clear': {
    'park': 1.0,
    'tourist_attraction': 0.9,
    'art_gallery': 0.7,
  },
  'Rain': {
    'museum': 1.0,
    'shopping_mall': 0.8,
    'cafe': 0.6,
  },
  'Clouds': {
    'museum': 0.9,
    'art_gallery': 0.7,
  },
  'Snow': {
    'shopping_mall': 1.0,
    'museum': 0.8,
  },
  'Drizzle': {
    'cafe': 1.0,
    'movie_theater': 0.9,
  },
  'Thunderstorm': {
    'museum': 1.0,
    'movie_theater': 0.8,
  },
  'Mist': {
    'cafe': 1.0,
  },
};

final Map<String, IconData> weatherIcons = {
  'Clear': Icons.wb_sunny,
  'Rain': Icons.beach_access,
  'Clouds': Icons.cloud,
  'Snow': Icons.ac_unit,
  'Drizzle': Icons.grain,
  'Thunderstorm': Icons.flash_on,
  'Mist': Icons.dehaze,
};

final Map<String, String> weatherDescriptions = {
  'Clear': 'Cielo Despejado',
  'Rain': 'Lluvioso',
  'Clouds': 'Nublado',
  'Snow': 'Nevando',
  'Drizzle': 'Llovizna',
  'Thunderstorm': 'Tormenta',
  'Mist': 'Niebla',
};

IconData getCategoryIcon(String category) {
  switch (category) {
    case 'park':
      return Icons.park;
    case 'tourist_attraction':
      return Icons.attractions;
    case 'art_gallery':
      return Icons.palette;
    case 'museum':
      return Icons.museum;
    case 'shopping_mall':
      return Icons.shopping_bag;
    case 'cafe':
      return Icons.coffee;
    case 'library':
      return Icons.local_library;
    case 'movie_theater':
      return Icons.movie;
    case 'restaurant':
      return Icons.restaurant;
    case 'bar':
      return Icons.local_bar;
    case 'supermarket':
      return Icons.local_grocery_store;
    case 'pharmacy':
      return Icons.local_pharmacy;
    case 'hospital':
      return Icons.local_hospital;
    case 'bank':
      return Icons.atm;
    case 'church':
      return Icons.church;
    case 'clothing_store':
      return Icons.checkroom;
    case 'shoe_store':
      return Icons.roller_skating;
    case 'zoo':
      return Icons.pets;
    case 'amusement_park':
      return Icons.castle;
    default:
      return Icons.place;
  }
}