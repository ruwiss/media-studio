import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class TenorService {
  static const String _baseUrl = 'https://tenor.googleapis.com/v2/search';

  Future<List<Map<String, dynamic>>> searchGifs({
    required String query,
    required String apiKey,
    int page = 1,
    int perPage = 20,
  }) async {
    final url = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'q': query,
        'key': apiKey,
        'limit': perPage.toString(),
        'pos': ((page - 1) * perPage).toString(),
        'media_filter': 'minimal',
        'contentfilter': 'high',
      },
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List;
      return results.map((item) {
        final formats = item['media_formats'] as Map<String, dynamic>;
        // Sırayla en iyi gif formatını bul
        final gifKeys = ['gif', 'mediumgif', 'tinygif', 'nanogif'];
        Map<String, dynamic>? media;
        for (final key in gifKeys) {
          if (formats[key] != null) {
            media = formats[key];
            break;
          }
        }
        if (media == null) {
          return {
            'id': item['id'],
            'thumbnail': '',
            'original': '',
            'source': 'tenor',
            'width': 0,
            'height': 0,
          };
        }
        return {
          'id': item['id'],
          'thumbnail': media['preview_url'] ?? media['url'],
          'original': media['url'] ?? '',
          'source': 'tenor',
          'width': (media['dims'] != null && media['dims'].isNotEmpty)
              ? media['dims'][0]
              : 0,
          'height': (media['dims'] != null && media['dims'].length > 1)
              ? media['dims'][1]
              : 0,
        };
      }).toList();
    } else {
      throw Exception('Tenor API Error: ${response.statusCode}');
    }
  }

  Future<String?> downloadGif(String url, String filename) async {
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
  }
}
