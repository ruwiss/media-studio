import 'package:flutter/material.dart';

class AppProvider with ChangeNotifier {
  int _selectedTabIndex = 0;
  String _searchText = '';
  bool _isLoading = false;
  bool _isSidebarCollapsed = true;
  bool _shouldClearAudioList = false;

  // Ses dosyaları için kalıcı liste
  final List<Map<String, String>> _generatedAudioFiles = [];

  // Ses efektleri için kalıcı liste
  final List<Map<String, String>> _soundEffects = [];

  int get selectedTabIndex => _selectedTabIndex;
  String get searchText => _searchText;
  bool get isLoading => _isLoading;
  bool get isSidebarCollapsed => _isSidebarCollapsed;
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

  void toggleSidebar() {
    _isSidebarCollapsed = !_isSidebarCollapsed;
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
      'originalName': filePath.split('/').last,
    });
    print(
      'DEBUG PROVIDER: Ses efekti eklendi. Toplam: ${_soundEffects.length}',
    );
    notifyListeners();
    print('DEBUG PROVIDER: notifyListeners çağrıldı');
  }

  void removeSoundEffect(int index) {
    if (index >= 0 && index < _soundEffects.length) {
      _soundEffects.removeAt(index);
      notifyListeners();
    }
  }

  void reorderSoundEffects(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _soundEffects.removeAt(oldIndex);
    _soundEffects.insert(newIndex, item);
    notifyListeners();
  }

  void updateSoundEffectName(int index, String newName) {
    if (index >= 0 && index < _soundEffects.length) {
      _soundEffects[index]['name'] = newName;
      notifyListeners();
    }
  }

  void clearAllSoundEffects() {
    _soundEffects.clear();
    notifyListeners();
  }

  void triggerClearAudioList() {
    _shouldClearAudioList = true;
    notifyListeners();
  }

  void clearAudioListTriggered() {
    _shouldClearAudioList = false;
  }
}
