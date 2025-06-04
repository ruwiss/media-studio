import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyElevenlabsApiKey = 'elevenlabs_api_key';
  static const String _keyElevenlabsVoiceId = 'elevenlabs_voice_id';
  static const String _keyPixabayApiKey = 'pixabay_api_key';
  static const String _keyPexelsApiKey = 'pexels_api_key';

  // ElevenLabs varsayılan ses modelleri
  static const Map<String, String> elevenlabsVoices = {
    'Adam': 'pNInz6obpgDQGcFmaJgB',
    'Alice': 'Xb7hH8MSUJpSbSDYk0k2',
    'Antoni': 'ErXwobaYiN019PkySvjV',
    'Aria': '9BWtsMINqrJLrRacOk9x',
    'Arnold 1': 'VR6AewLTigWG4xSOukaG',
    'Arnold 2': 'wViXBPUzp2ZZixB1xQuM',
    'Bill': 'pqHfZKP75CvOlQylNhV4',
    'Brian': 'nPczCjzI2devNBz1zQrb',
    'Callum': 'N2lVS1w4EtoT3dr4eOWO',
    'Charlie': 'IKne3meq5aSn9XLyUdCD',
    'Charlotte': 'XB0fDUnXU5powFXDhCwa',
    'Chris': 'iP95p4xoKVk53GoZ742B',
    'Clyde': '2EiwWnXFnvU5JabPnv8n',
    'Daniel': 'onwK4e9ZLuTAKqWW03F9',
    'Dave': 'CYw3kZ02Hs0563khs1Fj',
    'Domi': 'AZnzlk1XvdvUeBnXmlld',
    'Dorothy': 'ThT5KcBeYPX3keUQqHPh',
    'Drew': '29vD33N1CtxCmqQRPOHJ',
    'Elli': 'MF3mGyEYCl7XYWbV9V6O',
    'Emily': 'LcfcDJNUP1GQjkzn1xUU',
    'Eric': 'cjVigY5qzO86Huf0OWal',
    'Ethan': 'g5CIjZEefAph4nQFvHAz',
    'Fin': 'D38z5RcWu1voky8WS1ja',
    'Freya': 'jsCqWAovK2LkecY7zXl4',
    'George 1': 'JBFqnCBsd6RMkjVDRZzb',
    'George 2': 'Yko7PKHZNXotIFUBG7I9',
    'Gigi': 'jBpfuIE2acCO8z3wKNLl',
    'Giovanni': 'zcAOhNBS3c14rBihAFp1',
    'Glinda': 'z9fAnlkpzviPz146aGWa',
    'Grace': 'oWAxZDx7w5VEj9dCyTzz',
    'Harry': 'SOYHLrjzK2X1ezoPC6cr',
    'James': 'ZQe5CZNOzWyzPSCn5a3c',
    'Jessica': 'cgSgspJ2msm6clMCkdW9',
    'Jessie': 't0jbNlBVZ17f02VDIeMI',
    'Joseph': 'Zlb1dXrM653N07WRdFW3',
    'Josh': 'TxGEqnHWrfWFTfGW9XjX',
    'Laura': 'FGY2WhTYpPnrIDTdsKH5',
    'Liam': 'TX3LPaxmHKxFdv7VOQHJ',
    'Lily': 'pFZP5JQG7iQjIQuC4Bku',
    'Matilda': 'XrExE9yKIg1WjnnlVkGX',
    'Michael': 'flq6f7yk4E4fJM5XTYuZ',
    'Mimi': 'zrHiDhphv9ZnVXBqCLjz',
    'Nicole': 'piTKgcLEGmPE4e6mEKli',
    'Patrick': 'ODq5zmih8GrVes37Dizd',
    'Paul': '5Q0t7uMcjvnagumLfvZi',
    'Rachel': '21m00Tcm4TlvDq8ikWAM',
    'River': 'SAz9YHcvj6GT2YYXdXww',
    'Roger': 'CwhRBWXzGAHq8TQ4Fs17',
    'Sam': 'yoZ06aMxZJJ28mfd3POQ',
    'Sarah': 'EXAVITQu4vr4xnSDxMaL',
    'Serena': 'pMsXgVXv3BLzUgSXRplE',
    'Thomas': 'GBv7mTt0atIp3Br8iCZE',
    'Will': 'bIHbv24MWmeRgasZH58o',
    'Santa Claus': 'knrPHWnBmmDHMoiMeP3l',
  };

  Future<void> saveElevenlabsApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyElevenlabsApiKey, apiKey);
  }

  Future<String?> getElevenlabsApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyElevenlabsApiKey);
  }

  Future<void> saveElevenlabsVoiceId(String voiceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyElevenlabsVoiceId, voiceId);
  }

  Future<String?> getElevenlabsVoiceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyElevenlabsVoiceId) ?? 'Drew'; // Varsayılan Drew
  }

  // Eski metod adını koruyalım uyumluluk için
  Future<String?> getElevenLabsModelName() async {
    final selectedVoice = await getElevenlabsVoiceId();
    return elevenlabsVoices[selectedVoice] ?? elevenlabsVoices['Drew'];
  }

  // Pixabay Settings
  Future<void> setPixabayApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPixabayApiKey, apiKey);
  }

  Future<String?> getPixabayApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPixabayApiKey);
  }

  Future<void> savePixabayApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPixabayApiKey, apiKey);
  }

  Future<String?> getPexelsApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPexelsApiKey);
  }

  Future<void> savePexelsApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPexelsApiKey, apiKey);
  }

  // Save all settings
  Future<void> saveAllSettings({
    required String elevenlabsKey,
    required String elevenlabsVoiceId,
    required String pixabayKey,
    required String pexelsKey,
  }) async {
    await saveElevenlabsApiKey(elevenlabsKey);
    await saveElevenlabsVoiceId(elevenlabsVoiceId);
    await setPixabayApiKey(pixabayKey);
    await savePexelsApiKey(pexelsKey);
  }

  // Load all settings
  Future<Map<String, String?>> loadAllSettings() async {
    final results = await Future.wait([
      getElevenlabsApiKey(),
      getElevenlabsVoiceId(),
      getPixabayApiKey(),
      getPexelsApiKey(),
    ]);

    return {
      'elevenlabsKey': results[0],
      'elevenlabsVoiceId': results[1],
      'pixabayKey': results[2],
      'pexelsKey': results[3],
    };
  }

  Future<String?> getTenorApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('tenor_api_key');
  }

  Future<void> setTenorApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tenor_api_key', apiKey);
  }
}
