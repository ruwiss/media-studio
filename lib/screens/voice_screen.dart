import 'package:media_studio/services/elevenlabs_service.dart';
import 'package:media_studio/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'package:media_studio/providers/app_provider.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:provider/provider.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final TextEditingController _textController = TextEditingController();
  final ElevenLabsService _elevenLabsService = ElevenLabsService();
  final SettingsService _settingsService = SettingsService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isGenerating = false;
  bool _isPlaying = false;
  String? _currentPlayingPath;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String _selectedVoice = 'Drew';

  // API Limits
  Map<String, dynamic>? _apiLimits;
  bool _isLoadingLimits = false;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    _loadSelectedVoice();
    _loadApiLimits();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appProvider = Provider.of<AppProvider>(context);

    if (appProvider.shouldClearAudioList) {
      appProvider.clearAllGeneratedAudios();
      setState(() {
        _currentPlayingPath = null;
      });
      _audioPlayer.stop();
      appProvider.clearAudioListTriggered();
    }

    // Ses seçimi değiştiğinde güncelle
    _loadSelectedVoice();
  }

  Future<void> _loadSelectedVoice() async {
    final voice = await _settingsService.getElevenlabsVoiceId();
    setState(() {
      _selectedVoice = voice ?? 'Drew';
    });
  }

  Future<void> _saveSelectedVoice(String voice) async {
    await _settingsService.saveElevenlabsVoiceId(voice);
  }

  Future<void> _loadApiLimits() async {
    final apiKey = await _settingsService.getElevenlabsApiKey();
    if (apiKey == null || apiKey.isEmpty) return;

    setState(() {
      _isLoadingLimits = true;
    });

    try {
      _apiLimits = await _elevenLabsService.getApiLimits(apiKey);
    } catch (e) {
      debugPrint('ElevenLabs API limit kontrol hatası: $e');
    }

    if (mounted) {
      setState(() {
        _isLoadingLimits = false;
      });
    }
  }

  void _initAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((Duration d) {
      if (mounted) {
        setState(() => _duration = d);
      }
    });

    _audioPlayer.onPositionChanged.listen((Duration p) {
      if (mounted) {
        setState(() => _position = p);
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
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
                      Icons.record_voice_over,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: const Text(
                      'Düzenleme Yardımcısı',
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

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text Input
                    Container(
                      width: double.infinity,
                      height: 100,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.1),
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        maxLines: null,
                        expands: true,
                        decoration: const InputDecoration(
                          hintText: 'Bir cümle yazın',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Voice Selection
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Ses Modeli:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.1),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedVoice,
                                isExpanded: true,
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedVoice = newValue;
                                    });
                                    _saveSelectedVoice(newValue);
                                  }
                                },
                                items: SettingsService.elevenlabsVoices.keys
                                    .map<DropdownMenuItem<String>>((
                                      String voice,
                                    ) {
                                      return DropdownMenuItem<String>(
                                        value: voice,
                                        child: Text(
                                          voice,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      );
                                    })
                                    .toList(),
                                style: const TextStyle(fontSize: 12),
                                isDense: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // API Limits Section
                    _buildApiLimitsSection(),

                    const SizedBox(height: 12),

                    // Generate Button
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: _isGenerating ? null : _generateVoice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isGenerating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'OLUŞTUR',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Oluşturulan sesler listesi başlığı
                    if (appProvider.generatedAudioFiles.isNotEmpty) ...[
                      Text(
                        'Oluşturulan Sesler (${appProvider.generatedAudioFiles.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Oluşturulan sesler listesi
                    Expanded(
                      child: appProvider.generatedAudioFiles.isEmpty
                          ? Center(
                              child: Text(
                                'Henüz ses oluşturulmadı',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: appProvider.generatedAudioFiles.length,
                              itemBuilder: (context, index) {
                                final audioData =
                                    appProvider.generatedAudioFiles[index];
                                final audioFile = audioData['path']!;
                                final fileName = audioData['filename']!;
                                final audioText = audioData['text'] ?? '';
                                final isCurrentPlaying =
                                    _currentPlayingPath == audioFile;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: _buildAudioListItem(
                                    audioFile,
                                    fileName,
                                    audioText,
                                    isCurrentPlaying,
                                    index,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _generateVoice() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir metin girin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final apiKey = await _settingsService.getElevenlabsApiKey();
      final voiceId = await _settingsService.getElevenLabsModelName();

      if (apiKey == null || apiKey.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ElevenLabs API Key ayarlardan girilmelidir'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final audioPath = await _elevenLabsService.generateSpeech(
        text: _textController.text.trim(),
        apiKey: apiKey,
        voiceId: voiceId ?? '29vD33N1CtxCmqQRPOHJ',
      );

      if (mounted && audioPath != null) {
        // Dosyayı Downloads klasörüne kopyala
        await _copyToDownloads(audioPath);

        // Provider'a ses ekle
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        appProvider.addGeneratedAudio(
          audioPath,
          _textController.text.trim(),
          audioPath.split('/').last,
        );

        // Text input'u temizle
        _textController.clear();

        // API limitlerini yeniden yükle
        _loadApiLimits();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ses oluşturuldu ve indirilenler klasörüne eklendi',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ses oluşturulamadı. API anahtarını kontrol edin.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _copyToDownloads(String filePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory(
        '${directory.path}/RuwisVideoHelper/downloads',
      );
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final sourceFile = File(filePath);
      final fileName = filePath.split('/').last;
      final targetPath = '${downloadsDir.path}/$fileName';

      await sourceFile.copy(targetPath);
    } catch (e) {
      debugPrint('Downloads klasörüne kopyalama hatası: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildAudioListItem(
    String audioPath,
    String fileName,
    String text,
    bool isCurrentPlaying,
    int index,
  ) {
    return DragItemWidget(
      dragItemProvider: (request) async {
        final item = DragItem(localData: audioPath);
        item.add(Formats.fileUri(Uri.file(audioPath)));
        return item;
      },
      allowedOperations: () => [DropOperation.move],
      child: DraggableWidget(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCurrentPlaying
                ? const Color(0xFF8B5CF6).withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCurrentPlaying
                  ? const Color(0xFF8B5CF6)
                  : Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.2),
              width: isCurrentPlaying ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _playAudio(audioPath),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isCurrentPlaying && _isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          text,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeAudioFile(index),
                    icon: const Icon(Icons.close, size: 16),
                    tooltip: 'Listeden çıkar',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                ],
              ),
              if (isCurrentPlaying && _duration.inMilliseconds > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: _duration.inMilliseconds > 0
                            ? (_position.inMilliseconds /
                                      _duration.inMilliseconds)
                                  .clamp(0.0, 1.0)
                            : 0.0,
                        onChanged: (value) {
                          if (_duration.inMilliseconds > 0) {
                            final newPosition = Duration(
                              milliseconds: (value * _duration.inMilliseconds)
                                  .round(),
                            );
                            _audioPlayer.seek(newPosition);
                          }
                        },
                        activeColor: const Color(0xFF8B5CF6),
                      ),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _playAudio(String audioPath) async {
    try {
      if (_currentPlayingPath == audioPath && _isPlaying) {
        await _audioPlayer.pause();
      } else {
        setState(() {
          _currentPlayingPath = audioPath;
        });
        await _audioPlayer.play(DeviceFileSource(audioPath));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Oynatma hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeAudioFile(int index) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final removedFile = appProvider.generatedAudioFiles[index]['path']!;

    // Eğer silinen dosya şu an oynatılıyorsa, oynatmayı durdur
    if (_currentPlayingPath == removedFile) {
      _audioPlayer.stop();
      setState(() {
        _currentPlayingPath = null;
      });
    }

    appProvider.removeGeneratedAudio(index);
  }

  Widget _buildApiLimitsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: const Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 8),
              const Text(
                'ElevenLabs API Limitleri',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const Spacer(),
              if (_isLoadingLimits)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF8B5CF6),
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: _loadApiLimits,
                  child: Icon(
                    Icons.refresh,
                    size: 16,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_apiLimits == null && !_isLoadingLimits)
            const Text(
              'API key girilmemiş veya kontrol edilmemiş',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            )
          else if (_apiLimits != null)
            _buildLimitInfo(),
        ],
      ),
    );
  }

  Widget _buildLimitInfo() {
    final used = _apiLimits!['character_count'] ?? 0;
    final total = _apiLimits!['character_limit'] ?? 10000;
    final percentage = total > 0 ? (used / total * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Karakter: $used / $total (%$percentage) - Aylık',
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: total > 0 ? used / total : 0,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage > 80 ? Colors.red : const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
