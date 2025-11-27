import 'dart:convert';
import 'package:http/http.dart' as http;

class MovieService {
  final String apiKey;

  // Constructor con parámetro nombrado
  MovieService({required this.apiKey});

  Future<Map<String, dynamic>> fetchMovieByTitle(String title) async {
    final url = Uri.parse("https://www.omdbapi.com/?t=$title&apikey=$apiKey");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["Response"] == "True") {
        return data;
      } else {
        throw Exception("Película no encontrada");
      }
    } else {
      throw Exception("Error en la API");
    }
  }

  Future<List<Map<String, dynamic>>> getCatalog(String query) async {
    final url = Uri.parse(
      "https://www.omdbapi.com/?s=$query&type=movie&apikey=$apiKey",
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["Response"] == "True") {
        return (data["Search"] as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      } else {
        return [];
      }
    } else {
      throw Exception("Error en la API");
    }
  }
}
