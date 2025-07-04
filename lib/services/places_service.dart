// lib/services/places_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlaceAutocomplete {
  final String description;
  final String placeId;

  PlaceAutocomplete({required this.description, required this.placeId});

  factory PlaceAutocomplete.fromJson(Map<String, dynamic> json) {
    return PlaceAutocomplete(
      description: json['description'] as String,
      placeId: json['place_id'] as String,
    );
  }
}

class PlaceDetails {
  final String? address;
  final double? latitude;
  final double? longitude;

  PlaceDetails({this.address, this.latitude, this.longitude, required formattedAddress, required lat, required lng});
}

class PlacesService {
  static Future<List<PlaceAutocomplete>> getAutocompleteSuggestions(String query) async {
    if (query.length < 3) return [];

    final apiKey = dotenv.env['MAPS_API_KEY'] ?? '';
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
            '?input=$query'
            '&components=country:pe'
            '&language=es'
            '&types=address'
            '&key=$apiKey'
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return (data['predictions'] as List)
              .map((prediction) => PlaceAutocomplete.fromJson(prediction))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    final apiKey = dotenv.env['MAPS_API_KEY'] ?? '';
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
            '?place_id=$placeId'
            '&fields=geometry,formatted_address'
            '&key=$apiKey'
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];
          final location = result['geometry']['location'];
          return PlaceDetails(
            lat: location['lat'],
            lng: location['lng'],
            formattedAddress: result['formatted_address'],
          );
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}