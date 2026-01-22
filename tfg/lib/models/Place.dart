import 'package:cloud_firestore/cloud_firestore.dart';

class Place {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double? rating;
  final int? userRatingsTotal;
  final String address;
  final String phoneNumber;
  final String website;
  final String photoUrl;
  final bool openNow;
  final List<String> openingHours;


  final double? temperatura;
  final int? humedad;
  final String? condicion;
  final String? fuente;
  final DateTime? fechaActualizacion;

  Place({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.rating,
    this.userRatingsTotal,
    required this.address,
    required this.phoneNumber,
    required this.website,
    required this.photoUrl,
    required this.openNow,
    required this.openingHours,
    this.temperatura,
    this.humedad,
    this.condicion,
    this.fuente,
    this.fechaActualizacion,
  });

  factory Place.fromMap(Map<String, dynamic> map) {
    return Place(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
      rating: (map['rating'] as num?)?.toDouble(),
      userRatingsTotal: map['user_ratings_total'] as int?,
      address: map['address'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      website: map['website'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      openNow: map['openNow'] ?? false,
      openingHours: List<String>.from(map['openingHours'] ?? []),
      temperatura: (map['temperatura'] as num?)?.toDouble(),
      humedad: map['humedad'],
      condicion: map['condicion'],
      fuente: map['fuente'],
      fechaActualizacion: (map['fechaActualizacion'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'user_ratings_total': userRatingsTotal,
      'address': address,
      'phoneNumber': phoneNumber,
      'website': website,
      'photoUrl': photoUrl,
      'openNow': openNow,
      'openingHours': openingHours,
      'temperatura': temperatura,
      'humedad': humedad,
      'condicion': condicion,
      'fuente': fuente,
      'fechaActualizacion': fechaActualizacion != null
          ? Timestamp.fromDate(fechaActualizacion!)
          : null,
    };
  }
}