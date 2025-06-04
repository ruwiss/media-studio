import 'package:flutter/material.dart';
import 'package:media_studio/services/pixabay_service.dart';
import 'package:media_studio/services/pexels_service.dart';
import 'package:media_studio/services/settings_service.dart';
import 'dart:io';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';

class MediaScreen extends StatefulWidget {
  const MediaScreen({super.key});

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PixabayService _pixabayService = PixabayService();
  final PexelsService _pexelsService = PexelsService();
  final SettingsService _settingsService = SettingsService();

  String _selectedType = 'PHOTO';
  String _selectedApi = 'pixabay';
  bool _isSearching = false;
  bool _isLoadingMore = false;
  List<Map<String, dynamic>> _searchResults = [];
  final Set<String> _downloadedFiles = {};

  // Pagination
  int _currentPage = 1;
  bool _hasMoreData = true;
  String? _lastSearchQuery;

  // API desteklenen medya türleri
  final Map<String, List<String>> _apiSupportedTypes = {
    'pixabay': ['PHOTO', 'ILLUSTRATION', 'VECTOR', 'VIDEO', 'GIF'],
    'pexels': ['PHOTO', 'VIDEO'],
  };

  List<String> get _availableApis {
    return _apiSupportedTypes.keys
        .where((api) => _apiSupportedTypes[api]!.contains(_selectedType))
        .toList();
  }

  List<String> get _availableTypes {
    return _apiSupportedTypes[_selectedApi] ?? ['PHOTO'];
  }

  @override
  void initState() {
    super.initState();
    // initState'de setState çağırmayalım
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSelections();
      _loadDownloadedFiles();
    });
  }

  Future<void> _loadDownloadedFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory(
        '${directory.path}/RuwisVideoHelper/downloads',
      );

      if (await downloadsDir.exists()) {
        final files = await downloadsDir.list().toList();

        setState(() {
          _downloadedFiles.clear();
          for (var file in files) {
            if (file is File) {
              _downloadedFiles.add(file.path);
            }
          }
        });
      }
    } catch (e) {
      debugPrint('İndirilen dosyalar yüklenirken hata: $e');
    }
  }

  void _updateSelections() {
    bool needsUpdate = false;
    String newApi = _selectedApi;
    String newType = _selectedType;

    // Güvenli API seçimi
    final availableApis = _apiSupportedTypes.keys
        .where((api) => _apiSupportedTypes[api]!.contains(_selectedType))
        .toList();

    if (!availableApis.contains(_selectedApi)) {
      newApi = availableApis.isNotEmpty ? availableApis.first : 'pixabay';
      needsUpdate = true;
    }

    // Güvenli tip seçimi
    final availableTypes = _apiSupportedTypes[newApi] ?? ['PHOTO'];
    if (!availableTypes.contains(_selectedType)) {
      newType = availableTypes.isNotEmpty ? availableTypes.first : 'PHOTO';
      needsUpdate = true;
    }

    if (needsUpdate) {
      setState(() {
        _selectedApi = newApi;
        _selectedType = newType;
        // Kategori değişince içerikleri sıfırla
        _searchResults.clear();
      });
    }
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'PHOTO':
        return 'Resim';
      case 'ILLUSTRATION':
        return 'İllüstrasyon';
      case 'VECTOR':
        return 'Vektör';
      case 'VIDEO':
        return 'Video';
      case 'GIF':
        return 'GIF';
      default:
        return type;
    }
  }

  String _getApiDisplayName(String api) {
    switch (api) {
      case 'pixabay':
        return 'Pixabay';
      case 'pexels':
        return 'Pexels';
      default:
        return api;
    }
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
                  Icons.image,
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

          // Media Type Selector and API Dropdown
          Row(
            children: [
              // Dinamik medya tipi butonları
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _availableTypes.isEmpty
                        ? [_buildTypeButton('PHOTO', true)]
                        : _availableTypes.map((type) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: _buildTypeButton(
                                type,
                                _selectedType == type,
                              ),
                            );
                          }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _availableApis.contains(_selectedApi)
                        ? _selectedApi
                        : null,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedApi = newValue;
                          // API değişince içerikleri sıfırla
                          _searchResults.clear();
                          _updateSelections();
                        });
                      }
                    },
                    items: _availableApis.isEmpty
                        ? [
                            DropdownMenuItem<String>(
                              value: 'pixabay',
                              child: Text(
                                'Pixabay',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ]
                        : _availableApis.map<DropdownMenuItem<String>>((
                            String api,
                          ) {
                            return DropdownMenuItem<String>(
                              value: api,
                              child: Text(
                                _getApiDisplayName(api),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 14,
                    ),
                    dropdownColor: const Color(0xFF8B5CF6),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Search Bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Center(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _performSearch(),
                      decoration: const InputDecoration(
                        hintText: 'Arama yap...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                      textAlignVertical: TextAlignVertical.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                height: 40,
                child: ElevatedButton(
                  onPressed: _isSearching ? null : _performSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: _isSearching
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
                          'ARA',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Results Grid
          Expanded(child: _buildMediaGrid()),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String type, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          // Kategori değişince içerikleri sıfırla
          _searchResults.clear();
          _updateSelections();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _getTypeDisplayName(type),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMediaGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        double childAspectRatio;
        double width = constraints.maxWidth;

        // Video için farklı grid yapısı
        if (_selectedType == 'VIDEO') {
          if (width > 900) {
            crossAxisCount = 3;
          } else if (width > 600) {
            crossAxisCount = 2;
          } else {
            crossAxisCount = 1;
          }
          childAspectRatio = 16 / 9;
        } else {
          // Resim, illustration, vector, gif için
          if (width > 800) {
            crossAxisCount = 5;
          } else if (width > 600) {
            crossAxisCount = 4;
          } else if (width > 400) {
            crossAxisCount = 3;
          } else {
            crossAxisCount = 2;
          }
          childAspectRatio = 1;
        }

        if (_searchResults.isEmpty && !_isSearching) {
          return Center(
            child: Text(
              'Arama yapmak için yukarıdaki arama kutusunu kullanın',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (!_isLoadingMore &&
                _hasMoreData &&
                scrollInfo.metrics.pixels ==
                    scrollInfo.metrics.maxScrollExtent &&
                _lastSearchQuery != null) {
              _loadMoreResults();
            }
            return false;
          },
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: _searchResults.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Loading indicator
              if (index == _searchResults.length && _isLoadingMore) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                );
              }

              final item = _searchResults[index];
              final itemId = '${item['source']}_${item['id']}';

              // İndirilen dosyalar arasında bu item'ı ara
              String? downloadedFilePath;
              for (String filePath in _downloadedFiles) {
                if (filePath.contains(itemId)) {
                  downloadedFilePath = filePath;
                  break;
                }
              }

              if (downloadedFilePath != null) {
                return _buildDraggableMediaItem(item, downloadedFilePath);
              } else {
                return _buildDownloadableMediaItem(item);
              }
            },
          ),
        );
      },
    );
  }

  void _performSearch({bool isLoadMore = false}) async {
    if (_searchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen arama terimi girin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!isLoadMore) {
      setState(() {
        _isSearching = true;
        _currentPage = 1;
        _hasMoreData = true;
        _lastSearchQuery = _searchController.text.trim();
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      List<Map<String, dynamic>> results = [];

      if (_selectedApi == 'pixabay') {
        final apiKey = await _settingsService.getPixabayApiKey();

        if (apiKey == null || apiKey.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pixabay API Key ayarlardan girilmelidir'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        if (_selectedType == 'VIDEO') {
          results = await _pixabayService.searchVideos(
            query: _lastSearchQuery!,
            apiKey: apiKey,
            page: _currentPage,
            perPage: 20,
          );
        } else {
          String pixabayType = _selectedType == 'PHOTO'
              ? 'photo'
              : _selectedType == 'ILLUSTRATION'
              ? 'illustration'
              : _selectedType == 'VECTOR'
              ? 'vector'
              : 'all';

          results = await _pixabayService.searchImages(
            query: _lastSearchQuery!,
            apiKey: apiKey,
            type: pixabayType,
            page: _currentPage,
            perPage: 20,
          );
        }
      } else if (_selectedApi == 'pexels') {
        final apiKey = await _settingsService.getPexelsApiKey();

        if (apiKey == null || apiKey.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pexels API Key ayarlardan girilmelidir'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        if (_selectedType == 'VIDEO') {
          results = await _pexelsService.searchVideos(
            query: _lastSearchQuery!,
            apiKey: apiKey,
            page: _currentPage,
            perPage: 20,
          );
        } else {
          results = await _pexelsService.searchImages(
            query: _lastSearchQuery!,
            apiKey: apiKey,
            type: _selectedType,
            page: _currentPage,
            perPage: 20,
          );
        }
      }

      if (mounted) {
        setState(() {
          if (isLoadMore) {
            _searchResults.addAll(results);
          } else {
            _searchResults = results;
          }

          // Eğer gelen sonuç 20'den az ise son sayfa
          _hasMoreData = results.length >= 20;
          _currentPage++;
        });

        if (_searchResults.isEmpty && !isLoadMore) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sonuç bulunamadı'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Arama hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _loadMoreResults() {
    if (!_isLoadingMore && _hasMoreData && _lastSearchQuery != null) {
      _performSearch(isLoadMore: true);
    }
  }

  void _downloadMedia(Map<String, dynamic> media) async {
    try {
      String? filePath;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Medya tipine göre dosya uzantısı
      String extension;
      switch (_selectedType) {
        case 'VIDEO':
          extension = 'mp4';
          break;
        case 'GIF':
          extension = 'gif';
          break;
        case 'VECTOR':
          extension = 'svg';
          break;
        default:
          extension = 'jpg';
      }

      final filename =
          '${media['source']}_${media['id']}_$timestamp.$extension';

      if (media['source'] == 'pixabay') {
        filePath = await _pixabayService.downloadMedia(
          media['original'],
          filename,
        );
      } else if (media['source'] == 'pexels') {
        filePath = await _pexelsService.downloadMedia(
          media['original'],
          filename,
        );
      }

      if (mounted && filePath != null) {
        setState(() {
          _downloadedFiles.add(filePath!);
        });
        // İndirilen dosyaları yeniden yükle
        await _loadDownloadedFiles();
      }
    } catch (e) {
      // Sessizce hata yakala, kullanıcıya bildirim gösterme
      debugPrint('İndirme hatası: $e');
    }
  }

  void _openDownloadsFolder() async {
    try {
      await Process.run('explorer', ['/select,downloads'], runInShell: true);
    } catch (e) {
      debugPrint('Klasör açma hatası: $e');
    }
  }

  void _openMediaFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        // Windows'ta dosyayı varsayılan uygulamayla aç
        await Process.run('cmd', [
          '/c',
          'start',
          '',
          filePath,
        ], runInShell: true);
      } else {
        debugPrint('Dosya bulunamadı: $filePath');
      }
    } catch (e) {
      debugPrint('Dosya açma hatası: $e');
    }
  }

  Widget _buildDraggableMediaItem(Map<String, dynamic> item, String filePath) {
    return DragItemWidget(
      dragItemProvider: (request) async {
        final dragItem = DragItem(localData: filePath);
        dragItem.add(Formats.fileUri(Uri.file(filePath)));
        return dragItem;
      },
      allowedOperations: () => [DropOperation.move],
      child: DraggableWidget(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedScale(
            scale: 1.0,
            duration: const Duration(milliseconds: 200),
            child: Builder(
              builder: (context) {
                bool isHovered = false;
                return StatefulBuilder(
                  builder: (context, setState) {
                    return MouseRegion(
                      onEnter: (_) => setState(() => isHovered = true),
                      onExit: (_) => setState(() => isHovered = false),
                      child: AnimatedScale(
                        scale: isHovered ? 1.05 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: GestureDetector(
                          onDoubleTap: () => _openMediaFile(filePath),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(
                                  0xFF8B5CF6,
                                ).withValues(alpha: 0.3),
                                width: 2,
                              ),
                              boxShadow: isHovered
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF8B5CF6,
                                        ).withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                children: [
                                  Image.network(
                                    item['thumbnail'],
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(
                                          _selectedType == 'GIF'
                                              ? Icons.gif
                                              : Icons.image,
                                          size: 32,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      );
                                    },
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(
                                          alpha: 0.8,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(
                                        Icons.open_with,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  // Boyut bilgisi - sağ alt
                                  if (item['width'] != null &&
                                      item['height'] != null)
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.7,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                        child: Text(
                                          '${item['width']}×${item['height']}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  // Çift tıklama ipucu
                                  Positioned(
                                    bottom: 4,
                                    left: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.7,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Çift tıkla',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadableMediaItem(Map<String, dynamic> item) {
    final isVideo = _selectedType == 'VIDEO';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: StatefulBuilder(
        builder: (context, setState) {
          bool isHovered = false;
          return MouseRegion(
            onEnter: (_) => setState(() => isHovered = true),
            onExit: (_) => setState(() => isHovered = false),
            child: AnimatedScale(
              scale: isHovered ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: GestureDetector(
                onTap: () => _downloadMedia(item),
                onDoubleTap: () async {
                  // Eğer dosya zaten indirilmişse aç
                  final itemId = '${item['source']}_${item['id']}';

                  // İndirilen dosyalar arasında ara
                  String? existingFilePath;
                  for (String filePath in _downloadedFiles) {
                    if (filePath.contains(itemId)) {
                      existingFilePath = filePath;
                      break;
                    }
                  }

                  if (existingFilePath != null &&
                      await File(existingFilePath).exists()) {
                    _openMediaFile(existingFilePath);
                  } else {
                    // Dosya yoksa indir
                    _downloadMedia(item);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.1),
                    ),
                    boxShadow: isHovered
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF8B5CF6,
                              ).withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: isVideo ? 16 / 9 : 1,
                          child: Image.network(
                            item['thumbnail'],
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  _selectedType == 'VIDEO'
                                      ? Icons.videocam
                                      : _selectedType == 'GIF'
                                      ? Icons.gif
                                      : Icons.image,
                                  size: 32,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              );
                            },
                          ),
                        ),
                        if (isVideo)
                          const Positioned(
                            top: 8,
                            left: 8,
                            child: Icon(
                              Icons.play_circle_filled,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        // İndirme ikonu - sol alt
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF8B5CF6,
                              ).withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.download,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Boyut bilgisi - sağ alt
                        if (item['width'] != null && item['height'] != null)
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                '${item['width']}×${item['height']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _generateFilename(Map<String, dynamic> item) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    String extension;
    switch (_selectedType) {
      case 'VIDEO':
        extension = 'mp4';
        break;
      case 'GIF':
        extension = 'gif';
        break;
      case 'VECTOR':
        extension = 'svg';
        break;
      default:
        extension = 'jpg';
    }
    return '${item['source']}_${item['id']}_$timestamp.$extension';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
