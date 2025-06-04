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

  // Ses efektleri için grup tabanlı kalıcı yapı
  final Map<String, List<Map<String, String>>> _soundEffects = {'Genel': []};

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
  Map<String, List<Map<String, String>>> get soundEffects => _soundEffects;

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
  void addSoundEffect(String filePath, String name, {String group = 'Genel'}) {
    print(
      'DEBUG PROVIDER: addSoundEffect çağrıldı - path: $filePath, name: $name, group: $group',
    );
    if (!_soundEffects.containsKey(group)) {
      _soundEffects[group] = [];
    }
    _soundEffects[group]!.add({
      'path': filePath,
      'name': name,
      'originalName': filePath.split(Platform.isWindows ? '\\' : '/').last,
    });
    _saveSoundEffects();
    notifyListeners();
  }

  void removeSoundEffect(String group, int index) {
    if (_soundEffects.containsKey(group) &&
        index >= 0 &&
        index < _soundEffects[group]!.length) {
      // Dosyayı diskten sil
      try {
        final filePath = _soundEffects[group]![index]['path'];
        if (filePath != null) {
          final file = File(filePath);
          if (file.existsSync()) {
            file.deleteSync(); // veya await file.delete();
            print('DEBUG PROVIDER: Dosya diskten silindi: $filePath');
          }
        }
      } catch (e) {
        print('DEBUG PROVIDER: Dosya silinirken hata: $e');
      }

      _soundEffects[group]!.removeAt(index);
      if (_soundEffects[group]!.isEmpty && group != 'Genel') {
        // Eğer grup "Genel" değilse ve boşaldıysa, grubu da sil.
        // Bu davranış istenmiyorsa, bu kısım kaldırılabilir veya değiştirilebilir.
        // Şimdilik, son efekt silindiğinde boş özel grupların kalmaması için böyle bırakıyorum.
        // _soundEffects.remove(group);
      }
      _saveSoundEffects();
      notifyListeners();
    }
  }

  void reorderSoundEffects(String group, int oldIndex, int newIndex) {
    if (!_soundEffects.containsKey(group)) return;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _soundEffects[group]!.removeAt(oldIndex);
    _soundEffects[group]!.insert(newIndex, item);
    _saveSoundEffects();
    notifyListeners();
  }

  void updateSoundEffectName(String group, int index, String newName) {
    if (_soundEffects.containsKey(group) &&
        index >= 0 &&
        index < _soundEffects[group]!.length) {
      _soundEffects[group]![index]['name'] = newName;
      _saveSoundEffects();
      notifyListeners();
    }
  }

  void clearAllSoundEffects() {
    _soundEffects.clear();
    _soundEffects['Genel'] = [];
    _saveSoundEffects();
    notifyListeners();
  }

  void addGroup(String groupName) {
    if (!_soundEffects.containsKey(groupName)) {
      _soundEffects[groupName] = [];
      _saveSoundEffects();
      notifyListeners();
    }
  }

  void removeGroup(String groupName) {
    if (_soundEffects.containsKey(groupName) && groupName != 'Genel') {
      // Gruba ait ses efektlerini ve dosyalarını sil
      final soundEffectsInGroup = List<Map<String, String>>.from(
        _soundEffects[groupName]!,
      );
      // Asenkron işlem için bu fonksiyonu Future<void> yapıp dışarıda await ile çağırmak daha doğru olur,
      // ancak şimdilik provider içindeki yapıyı koruyarak devam ediyorum.
      // Bu döngü UI'ı bir miktar bloklayabilir eğer çok fazla dosya varsa.
      for (final soundEffect in soundEffectsInGroup) {
        try {
          final filePath = soundEffect['path'];
          if (filePath != null) {
            final file = File(filePath);
            if (file.existsSync()) {
              // await file.exists() olmalıydı Future için
              file.deleteSync(); // Eğer Future ise await file.delete();
              print(
                'DEBUG PROVIDER: Grup silinirken dosya diskten silindi: $filePath',
              );
            }
          }
        } catch (e) {
          print('DEBUG PROVIDER: Grup silinirken dosya silme hatası: $e');
        }
      }
      _soundEffects.remove(groupName);
      _saveSoundEffects();
      notifyListeners();
    }
  }

  void renameGroup(String oldName, String newName) {
    if (_soundEffects.containsKey(oldName) &&
        !_soundEffects.containsKey(newName) &&
        oldName != 'Genel') {
      _soundEffects[newName] = _soundEffects.remove(oldName)!;
      _saveSoundEffects();
      notifyListeners();
    }
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
        final Map<String, dynamic> soundEffectsJson = jsonDecode(
          soundEffectsString,
        );
        _soundEffects.clear();
        soundEffectsJson.forEach((group, list) {
          _soundEffects[group] = [];
          if (list is List) {
            for (final item in list) {
              if (item is Map<String, dynamic>) {
                _soundEffects[group]!.add({
                  'path': item['path']?.toString() ?? '',
                  'name': item['name']?.toString() ?? '',
                  'originalName': item['originalName']?.toString() ?? '',
                });
              }
            }
          }
        });
        if (!_soundEffects.containsKey('Genel')) {
          _soundEffects['Genel'] = [];
        }
        print(
          'DEBUG PROVIDER: Ses efektleri yüklendi: ${_soundEffects.length} grup',
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
