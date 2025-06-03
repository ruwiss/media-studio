import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class ElevenLabsService {
  static const String _baseUrl = 'https://api.elevenlabs.io/v1';

  Future<Map<String, dynamic>?> getApiLimits(String apiKey) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/user/subscription'),
        headers: {'Accept': 'application/json', 'xi-api-key': apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'character_count': data['character_count'] ?? 0,
          'character_limit': data['character_limit'] ?? 10000,
          'can_extend_character_limit':
              data['can_extend_character_limit'] ?? false,
          'allowed_to_extend_character_limit':
              data['allowed_to_extend_character_limit'] ?? false,
          'next_character_count_reset_unix':
              data['next_character_count_reset_unix'] ?? 0,
        };
      }
      return null;
    } catch (e) {
      debugPrint('ElevenLabs limit check error: $e');
      return null;
    }
  }

  Future<String?> generateSpeech({
    required String text,
    required String apiKey,
    required String voiceId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/text-to-speech/$voiceId');

      final response = await http.post(
        url,
        headers: {
          'Accept': 'audio/mpeg',
          'Content-Type': 'application/json',
          'xi-api-key': apiKey,
        },
        body: jsonEncode({
          'text': text,
          'model_id': 'eleven_multilingual_v2',
          'voice_settings': {
            'stability': 0.5,
            'similarity_boost': 0.5,
            'style': 0.0,
            'use_speaker_boost': true,
          },
        }),
      );

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final downloadsDir = Directory(
          '${directory.path}/RuwisVideoHelper/downloads',
        );
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filePath = '${downloadsDir.path}/voice_$timestamp.mp3';
        final file = File(filePath);

        await file.writeAsBytes(response.bodyBytes);
        return filePath;
      } else {
        debugPrint('ElevenLabs API Error: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('ElevenLabs Service Error: $e');
      return null;
    }
  }
}
