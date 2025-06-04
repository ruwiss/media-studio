import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

class AppProvider with ChangeNotifier {
  int _selectedTabIndex = 0;
  String _searchText = '';
  bool _isLoading = false;
  bool _shouldClearAudioList = false;

  // Ses dosyaları için kalıcı liste
  final List<Map<String, String>> _generatedAudioFiles = [];

  // Ses efektleri için kalıcı liste
  final List<Map<String, String>> _soundEffects = [];

  static const String _soundEffectsKey = 'sound_effects';

  // Constructor'da ses efektlerini yükle
  AppProvider() {
    _loadSoundEffects();
  }

  int get selectedTabIndex => _selectedTabIndex;
  String get searchText => _searchText;
  bool get isLoading => _isLoading;
  bool get shouldClearAudioList => _shouldClearAudioList;
  List<Map<String, String>> get generatedAudioFiles => _generatedAudioFiles;
  List<Map<String, String>> get soundEffects => _soundEffects;

  void setSelectedTabIndex(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  void setSearchText(String text) {
    _searchText = text;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void addGeneratedAudio(String filePath, String text, String filename) {
    _generatedAudioFiles.insert(0, {
      'path': filePath,
      'text': text,
      'filename': filename,
    });
    notifyListeners();
  }

  void removeGeneratedAudio(int index) {
    if (index >= 0 && index < _generatedAudioFiles.length) {
      _generatedAudioFiles.removeAt(index);
      notifyListeners();
    }
  }

  void clearAllGeneratedAudios() {
    _generatedAudioFiles.clear();
    notifyListeners();
  }

  // Ses efektleri yönetimi
  void addSoundEffect(String filePath, String name) {
    print(
      'DEBUG PROVIDER: addSoundEffect çağrıldı - path: $filePath, name: $name',
    );
    _soundEffects.add({
      'path': filePath,
      'name': name,
      'originalName': filePath.split(Platform.isWindows ? '\\' : '/').last,
    });
    print(
      'DEBUG PROVIDER: Ses efekti eklendi. Toplam: ${_soundEffects.length}',
    );
    _saveSoundEffects(); // Kalıcı kaydet
    notifyListeners();
    print('DEBUG PROVIDER: notifyListeners çağrıldı');
  }

  void removeSoundEffect(int index) {
    if (index >= 0 && index < _soundEffects.length) {
      _soundEffects.removeAt(index);
      _saveSoundEffects(); // Kalıcı kaydet
      notifyListeners();
    }
  }

  void reorderSoundEffects(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _soundEffects.removeAt(oldIndex);
    _soundEffects.insert(newIndex, item);
    _saveSoundEffects(); // Kalıcı kaydet
    notifyListeners();
  }

  void updateSoundEffectName(int index, String newName) {
    if (index >= 0 && index < _soundEffects.length) {
      _soundEffects[index]['name'] = newName;
      _saveSoundEffects(); // Kalıcı kaydet
      notifyListeners();
    }
  }

  void clearAllSoundEffects() {
    _soundEffects.clear();
    _saveSoundEffects(); // Kalıcı kaydet
    notifyListeners();
  }

  // SharedPreferences ile ses efektlerini kaydet
  Future<void> _saveSoundEffects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final soundEffectsJson = jsonEncode(_soundEffects);
      await prefs.setString(_soundEffectsKey, soundEffectsJson);
      print(
        'DEBUG PROVIDER: Ses efektleri kaydedildi: ${_soundEffects.length} adet',
      );
    } catch (e) {
      print('DEBUG PROVIDER: Ses efektleri kaydetme hatası: $e');
    }
  }

  // SharedPreferences'tan ses efektlerini yükle
  Future<void> _loadSoundEffects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final soundEffectsString = prefs.getString(_soundEffectsKey);

      if (soundEffectsString != null) {
        final List<dynamic> soundEffectsJson = jsonDecode(soundEffectsString);
        _soundEffects.clear();

        for (final item in soundEffectsJson) {
          if (item is Map<String, dynamic>) {
            _soundEffects.add({
              'path': item['path']?.toString() ?? '',
              'name': item['name']?.toString() ?? '',
              'originalName': item['originalName']?.toString() ?? '',
            });
          }
        }

        print(
          'DEBUG PROVIDER: Ses efektleri yüklendi: ${_soundEffects.length} adet',
        );
        notifyListeners();
      }
    } catch (e) {
      print('DEBUG PROVIDER: Ses efektleri yükleme hatası: $e');
    }
  }

  void triggerClearAudioList() {
    _shouldClearAudioList = true;
    notifyListeners();
  }

  void clearAudioListTriggered() {
    _shouldClearAudioList = false;
  }
}
