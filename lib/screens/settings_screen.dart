import 'package:media_studio/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:media_studio/providers/app_provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _elevenlabsKeyController =
      TextEditingController();
  final SettingsService _settingsService = SettingsService();

  final TextEditingController _pixabayKeyController = TextEditingController();
  final TextEditingController _pexelsKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.loadAllSettings();

    setState(() {
      _elevenlabsKeyController.text = settings['elevenlabsKey'] ?? '';
      _pixabayKeyController.text = settings['pixabayKey'] ?? '';
      _pexelsKeyController.text = settings['pexelsKey'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.settings,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: const Text(
                  'Ayarlar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Settings Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ElevenLabs Section
                  _buildSectionTitle('Elevenlabs API Key'),
                  const SizedBox(height: 6),
                  _buildTextField(_elevenlabsKeyController, 'API Key girin...'),

                  const SizedBox(height: 16),

                  // Pixabay Section
                  _buildSectionTitle('Pixabay API Key'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    _pixabayKeyController,
                    'Pixabay API Key girin...',
                  ),

                  const SizedBox(height: 16),

                  // Pexels Section
                  _buildSectionTitle('Pexels API Key'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    _pexelsKeyController,
                    'Pexels API Key girin...',
                  ),

                  const SizedBox(height: 16),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'KAYDET',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Clear Downloads Button
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton(
                      onPressed: _clearDownloads,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'TÜM DOSYALARI TEMİZLE',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
          style: const TextStyle(fontSize: 13),
          textAlignVertical: TextAlignVertical.center,
        ),
      ),
    );
  }

  void _saveSettings() async {
    try {
      await _settingsService.saveAllSettings(
        elevenlabsKey: _elevenlabsKeyController.text.trim(),
        elevenlabsVoiceId: 'Drew', // Default değer
        pixabayKey: _pixabayKeyController.text.trim(),
        pexelsKey: _pexelsKeyController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ayarlar kaydedildi'),
            backgroundColor: Color(0xFF8B5CF6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ayarlar kaydedilemedi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearDownloads() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İNDİRİLENLERİ TEMİZLE'),
        content: const Text(
          'Tüm indirilen medya dosyaları ve ses efektleri silinecek. Emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final directory = await getApplicationDocumentsDirectory();

                // Downloads klasörünü temizle
                final downloadsDir = Directory(
                  '${directory.path}/RuwisVideoHelper/downloads',
                );
                if (await downloadsDir.exists()) {
                  await downloadsDir.delete(recursive: true);
                }

                // Sound effects klasörünü temizle
                final soundEffectsDir = Directory(
                  '${directory.path}/RuwisVideoHelper/sound_effects',
                );
                if (await soundEffectsDir.exists()) {
                  await soundEffectsDir.delete(recursive: true);
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tüm dosyalar temizlendi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }

                final appProvider = Provider.of<AppProvider>(
                  context,
                  listen: false,
                );
                appProvider.triggerClearAudioList();
                appProvider.clearAllSoundEffects();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Dosyalar temizlenemedi: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Temizle', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _elevenlabsKeyController.dispose();
    _pixabayKeyController.dispose();
    _pexelsKeyController.dispose();
    super.dispose();
  }
}
