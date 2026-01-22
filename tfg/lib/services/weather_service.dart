import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../utils/api_keys.dart';

class WeatherService {
  final String apiKey =  ApiKeys.openWeather
;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> obtenerClimaGuardado(double lat, double lon) async {
    try {
      final id = '${lat.toStringAsFixed(4)}_${lon.toStringAsFixed(4)}';
      final doc = await _firestore.collection('climas').doc(id).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        print(' Clima cargado');
        return data;
      } else {
        print('No hay clima guardado para esta ubicación');
        return null;
      }
    } catch (e) {
      print('Error al obtener clima guardado: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> obtenerClimaActualizado(double lat, double lon) async {
    try {
      final url = 'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=es';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final clima = {
          'id': '${lat.toStringAsFixed(4)}_${lon.toStringAsFixed(4)}',
          'ubicacion': {
            'latitud': lat,
            'longitud': lon,
          },
          'temperatura': data['main']['temp'].toDouble(),
          'humedad': data['main']['humidity'],
          'condicion': data['weather'][0]['main'],
          'descripcion': data['weather'][0]['description'],
          'fuente': 'OpenWeatherMap',
          'fechaActualizacion': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('climas').doc(clima['id']).set(clima);

        clima['fechaActualizacion'] = Timestamp.now();

        print('Clima actualizado y guardado');
        return clima;
      } else {
        print('Error al obtener el clima: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error al actualizar clima: $e');
      return null;
    }
  }

  bool esClimaReciente(Map<String, dynamic> clima) {
    try {
      final fechaActualizacion = clima['fechaActualizacion'] as Timestamp?;
      if (fechaActualizacion == null) return false;

      final ahora = DateTime.now();
      final fechaClima = fechaActualizacion.toDate();
      final diferencia = ahora.difference(fechaClima).inMinutes;

      return diferencia < 60;
    } catch (e) {
      print('Error al verificar fecha del clima: $e');
      return false;
    }
  }

  String formatearFechaActualizacion(Map<String, dynamic> clima) {
    try {
      final fechaActualizacion = clima['fechaActualizacion'] as Timestamp?;
      if (fechaActualizacion == null) return 'Fecha desconocida';

      final fecha = fechaActualizacion.toDate();
      final ahora = DateTime.now();
      final diferencia = ahora.difference(fecha);

      if (diferencia.inMinutes < 1) {
        return 'Hace unos segundos';
      } else if (diferencia.inMinutes < 60) {
        return 'Hace ${diferencia.inMinutes} minutos';
      } else if (diferencia.inHours < 24) {
        return 'Hace ${diferencia.inHours} horas';
      } else {
        return 'Hace ${diferencia.inDays} días';
      }
    } catch (e) {
      return 'Fecha no disponible';
    }
  }

  Future<Map<String, dynamic>?> obtenerClima(double lat, double lon, {bool forzarActualizacion = false}) async {
    if (!forzarActualizacion) {
      final climaGuardado = await obtenerClimaGuardado(lat, lon);
      if (climaGuardado != null && esClimaReciente(climaGuardado)) {
        return climaGuardado;
      }
    }

    return await obtenerClimaActualizado(lat, lon);
  }
}