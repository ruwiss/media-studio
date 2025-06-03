import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class PixabayService {
  static const String _baseUrl = 'https://pixabay.com/api';

  Future<List<Map<String, dynamic>>> searchImages({
    required String query,
    required String apiKey,
    String type = 'all',
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      // API parametresi için image_type kullan
      final typeParam = type.toLowerCase();

      final url = Uri.parse('$_baseUrl/').replace(
        queryParameters: {
          'key': apiKey,
          'q': query,
          'image_type': typeParam,
          'page': page.toString(),
          'per_page': perPage.toString(),
          'safesearch': 'true',
          'category': 'all',
        },
      );

      debugPrint('Pixabay API URL: $url');

      final response = await http.get(url);

      debugPrint('Pixabay Response Status: ${response.statusCode}');
      debugPrint('Pixabay Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['error'] != null) {
          throw Exception('Pixabay API Error: ${data['error']}');
        }

        final hits = data['hits'] as List;

        return hits.map((hit) {
          return {
            'id': hit['id'].toString(),
            'thumbnail': hit['webformatURL'],
            'original': hit['largeImageURL'] ?? hit['webformatURL'],
            'source': 'pixabay',
            'tags': hit['tags'] ?? '',
            'user': hit['user'] ?? 'Unknown',
            'width': hit['imageWidth'],
            'height': hit['imageHeight'],
          };
        }).toList();
      } else {
        throw Exception(
          'Pixabay API Error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Pixabay search error: $e');
      throw Exception('Pixabay search error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> searchVideos({
    required String query,
    required String apiKey,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/videos/').replace(
        queryParameters: {
          'key': apiKey,
          'q': query,
          'category': 'all',
          'page': page.toString(),
          'per_page': perPage.toString(),
          'safesearch': 'true',
        },
      );

      debugPrint('Pixabay Video API URL: $url');

      final response = await http.get(url);

      debugPrint('Pixabay Video Response Status: ${response.statusCode}');
      debugPrint('Pixabay Video Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['error'] != null) {
          throw Exception('Pixabay Video API Error: ${data['error']}');
        }

        final hits = data['hits'] as List;

        return hits
            .map(
              (hit) => {
                'id': hit['id'].toString(),
                'title': hit['tags'] ?? 'Pixabay Video',
                'thumbnail': hit['picture_id'],
                'original': hit['videos']['large']['url'],
                'width': hit['videos']['large']['width'],
                'height': hit['videos']['large']['height'],
                'duration': hit['duration'],
                'source': 'pixabay',
              },
            )
            .toList();
      } else {
        throw Exception(
          'Pixabay Video API Error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Pixabay Video Service Error: $e');
      throw Exception('Pixabay Video Service Error: $e');
    }
  }

  Future<String?> downloadMedia(String mediaUrl, String filename) async {
    try {
      final response = await http.get(Uri.parse(mediaUrl));

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final downloadsDir = Directory(
          '${directory.path}/RuwisVideoHelper/downloads',
        );
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        final filePath = '${downloadsDir.path}/$filename';
        final file = File(filePath);

        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      }
      return null;
    } catch (e) {
      debugPrint('Download Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getApiLimits(String apiKey) async {
    try {
      // Pixabay'de basit bir test isteği yaparak header'ları kontrol edelim
      final response = await http.get(
        Uri.parse('$_baseUrl/').replace(
          queryParameters: {'key': apiKey, 'q': 'test', 'per_page': '3'},
        ),
      );

      if (response.statusCode == 200) {
        // Rate limit bilgilerini header'lardan al
        final headers = response.headers;
        return {
          'rate_limit':
              int.tryParse(headers['x-ratelimit-limit'] ?? '100') ?? 100,
          'rate_remaining':
              int.tryParse(headers['x-ratelimit-remaining'] ?? '100') ?? 100,
          'rate_reset':
              int.tryParse(headers['x-ratelimit-reset'] ?? '60') ??
              60, // 60 saniye
          'rate_period': '60 saniye', // Açıklama için
        };
      }
      return null;
    } catch (e) {
      debugPrint('Pixabay limit check error: $e');
      return null;
    }
  }
}
