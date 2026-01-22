import 'package:google_maps_flutter/google_maps_flutter.dart';

class ExploreCache {
  static final ExploreCache _instance = ExploreCache._internal();

  factory ExploreCache() => _instance;
  ExploreCache._internal();

  LatLng? lastPosition;
  double? lastZoom;

  String? selectedCategory;
  Set<Marker>? markers;
  List<String>? categories;
  void clear() {
    lastPosition = null;
    lastZoom = null;
    markers = null;
    selectedCategory = null;
    categories = null;
  }
}

final exploreCache = ExploreCache();
