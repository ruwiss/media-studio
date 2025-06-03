import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class PexelsService {
  static const String _baseUrl = 'https://api.pexels.com/v1';
  static const String _videosUrl = 'https://api.pexels.com/videos';

  Future<Map<String, dynamic>?> getApiLimits(String apiKey) async {
    try {
      // Pexels'de basit bir test isteği yaparak header'ları kontrol edelim
      final response = await http.get(
        Uri.parse('$_baseUrl/search?query=test&per_page=1'),
        headers: {'Authorization': apiKey},
      );

      if (response.statusCode == 200) {
        // Rate limit bilgilerini header'lardan al
        final headers = response.headers;
        return {
          'rate_limit':
              int.tryParse(headers['x-ratelimit-limit'] ?? '200') ?? 200,
          'rate_remaining':
              int.tryParse(headers['x-ratelimit-remaining'] ?? '200') ?? 200,
          'rate_reset':
              int.tryParse(headers['x-ratelimit-reset'] ?? '3600') ??
              3600, // 1 saat
          'rate_period': '1 saat', // Açıklama için
        };
      }
      return null;
    } catch (e) {
      debugPrint('Pexels limit check error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> searchImages({
    required String query,
    required String apiKey,
    String type = 'PNG',
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search?query=$query&page=$page&per_page=$perPage'),
        headers: {'Authorization': apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final photos = data['photos'] as List;

        return photos.map((photo) {
          return {
            'id': photo['id'].toString(),
            'thumbnail': photo['src']['medium'],
            'original': photo['src']['original'],
            'large': photo['src']['large'],
            'source': 'pexels',
            'photographer': photo['photographer'],
            'width': photo['width'],
            'height': photo['height'],
          };
        }).toList();
      } else {
        throw Exception('Pexels API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Pexels search error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> searchVideos({
    required String query,
    required String apiKey,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_videosUrl/search?query=$query&page=$page&per_page=$perPage',
        ),
        headers: {'Authorization': apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final videos = data['videos'] as List;

        return videos.map((video) {
          // En uygun video dosyasını seç
          final videoFiles = video['video_files'] as List;
          final hdFile = videoFiles.firstWhere(
            (file) => file['quality'] == 'hd',
            orElse: () => videoFiles.first,
          );

          return {
            'id': video['id'].toString(),
            'thumbnail': video['image'],
            'original': hdFile['link'],
            'source': 'pexels',
            'photographer': video['user']['name'],
            'width': video['width'],
            'height': video['height'],
            'duration': video['duration'],
          };
        }).toList();
      } else {
        throw Exception('Pexels Video API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Pexels video search error: $e');
    }
  }

  Future<String?> downloadMedia(String url, String filename) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final downloadsDir = Directory(
          '${directory.path}/RuwisVideoHelper/downloads',
        );

        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        final file = File('${downloadsDir.path}/$filename');
        await file.writeAsBytes(response.bodyBytes);

        return file.path;
      }
      return null;
    } catch (e) {
      throw Exception('Download error: $e');
    }
  }
}
