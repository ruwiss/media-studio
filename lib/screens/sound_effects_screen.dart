import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_studio/providers/app_provider.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SoundEffectsScreen extends StatefulWidget {
  const SoundEffectsScreen({super.key});

  @override
  State<SoundEffectsScreen> createState() => _SoundEffectsScreenState();
}

class _SoundEffectsScreenState extends State<SoundEffectsScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentPlayingPath;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
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
                      Icons.library_music,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: const Text(
                      'Ses Efektleri',
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

              // Drop Zone
              _buildDropZone(),

              const SizedBox(height: 20),

              // Sound Effects List
              if (appProvider.soundEffects.isNotEmpty) ...[
                Text(
                  'Ses Efektleri (${appProvider.soundEffects.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              Expanded(
                child: appProvider.soundEffects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.audio_file,
                              size: 48,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Ses dosyalarını buraya sürükleyip bırakın',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ReorderableListView.builder(
                        itemCount: appProvider.soundEffects.length,
                        onReorder: (oldIndex, newIndex) {
                          appProvider.reorderSoundEffects(oldIndex, newIndex);
                        },
                        itemBuilder: (context, index) {
                          final soundEffect = appProvider.soundEffects[index];
                          final isCurrentPlaying =
                              _currentPlayingPath == soundEffect['path'];

                          return Container(
                            key: ValueKey(soundEffect['path']),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: _buildSoundEffectItem(
                              context,
                              soundEffect,
                              isCurrentPlaying,
                              index,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropZone() {
    return DropRegion(
      formats: const [Formats.fileUri],
      onDropOver: (event) {
        return DropOperation.copy;
      },
      onPerformDrop: (event) async {
        final items = event.session.items;
        for (final item in items) {
          final reader = item.dataReader!;
          if (reader.canProvide(Formats.fileUri)) {
            reader.getValue<Uri>(Formats.fileUri, (uri) async {
              if (uri != null) {
                await _handleDroppedFile(uri.toFilePath());
              }
            });
          }
        }
      },
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload, size: 40, color: const Color(0xFF8B5CF6)),
            const SizedBox(height: 8),
            Text(
              'Ses dosyalarını buraya sürükleyip bırakın',
              style: TextStyle(
                color: const Color(0xFF8B5CF6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'MP3, WAV, M4A, OGG desteklenir',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundEffectItem(
    BuildContext context,
    Map<String, String> soundEffect,
    bool isCurrentPlaying,
    int index,
  ) {
    return DragItemWidget(
      dragItemProvider: (request) async {
        final item = DragItem(localData: soundEffect['path']);
        item.add(Formats.fileUri(Uri.file(soundEffect['path']!)));
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
                  // Drag Handle
                  Icon(
                    Icons.drag_handle,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 8),

                  // Play Button
                  GestureDetector(
                    onTap: () => _playAudio(soundEffect['path']!),
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

                  // Name and Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onDoubleTap: () =>
                              _editName(index, soundEffect['name']!),
                          child: Text(
                            soundEffect['name']!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          soundEffect['originalName']!,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Edit Button
                  IconButton(
                    onPressed: () => _editName(index, soundEffect['name']!),
                    icon: const Icon(Icons.edit, size: 16),
                    tooltip: 'İsmi düzenle',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),

                  // Delete Button
                  IconButton(
                    onPressed: () => _deleteSoundEffect(index),
                    icon: const Icon(Icons.delete, size: 16),
                    tooltip: 'Sil',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                ],
              ),

              // Progress Bar (only when playing)
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

  Future<void> _handleDroppedFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    final extension = filePath.toLowerCase().split('.').last;
    final supportedFormats = ['mp3', 'wav', 'm4a', 'ogg', 'aac'];

    if (!supportedFormats.contains(extension)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Desteklenmeyen dosya formatı'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final fileName = filePath.split('/').last.split('.').first;
    await _showNameDialog(filePath, fileName);
  }

  Future<void> _showNameDialog(String filePath, String defaultName) async {
    final controller = TextEditingController(text: defaultName);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ses Efekti Adı'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Ses efekti adını girin',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _copySoundEffectToApp(filePath, result);
    }
  }

  Future<void> _copySoundEffectToApp(String sourcePath, String name) async {
    try {
      print('DEBUG: Başlıyor - sourcePath: $sourcePath, name: $name');

      final directory = await getApplicationDocumentsDirectory();
      print('DEBUG: Documents directory: ${directory.path}');

      final soundEffectsDir = Directory(
        '${directory.path}/RuwisVideoHelper/sound_effects',
      );
      print('DEBUG: Sound effects directory: ${soundEffectsDir.path}');

      if (!await soundEffectsDir.exists()) {
        print('DEBUG: Klasör yok, oluşturuluyor...');
        await soundEffectsDir.create(recursive: true);
      } else {
        print('DEBUG: Klasör zaten var');
      }

      final sourceFile = File(sourcePath);
      print('DEBUG: Source file exists: ${await sourceFile.exists()}');

      final extension = sourcePath.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetFileName = '${name}_$timestamp.$extension';
      final targetPath = '${soundEffectsDir.path}/$targetFileName';
      print('DEBUG: Target path: $targetPath');

      await sourceFile.copy(targetPath);
      print('DEBUG: Dosya kopyalandı');

      final appProvider = Provider.of<AppProvider>(context, listen: false);
      print('DEBUG: Provider alındı, ses efekti ekleniyor...');
      appProvider.addSoundEffect(targetPath, name);
      print('DEBUG: addSoundEffect çağrıldı');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ses efekti eklendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('DEBUG: HATA: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ses efekti eklenemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editName(int index, String currentName) async {
    final controller = TextEditingController(text: currentName);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İsmi Düzenle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Yeni isim girin',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != currentName) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      appProvider.updateSoundEffectName(index, result);
    }
  }

  void _deleteSoundEffect(int index) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ses Efektini Sil'),
        content: const Text(
          'Bu ses efektini silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final soundEffect = appProvider.soundEffects[index];

      // Stop playing if this file is currently playing
      if (_currentPlayingPath == soundEffect['path']) {
        _audioPlayer.stop();
        setState(() {
          _currentPlayingPath = null;
        });
      }

      // Delete file from disk
      try {
        final file = File(soundEffect['path']!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Dosya silinirken hata: $e');
      }

      appProvider.removeSoundEffect(index);
    }
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
