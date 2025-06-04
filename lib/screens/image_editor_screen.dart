import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:media_studio/providers/app_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';

class ImageEditorScreen extends StatefulWidget {
  const ImageEditorScreen({super.key});

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  final FocusNode _focusNode = FocusNode();

  // Image properties
  ui.Image? _backgroundImage;
  String? _imagePath;
  double _imageX = 0;
  double _imageY = 0;
  double _imageScale = 1.0;

  // Drawing properties
  final List<DrawnLine> _lines = [];
  final List<List<DrawnLine>> _undoHistory = [];
  Color _selectedColor = Colors.red;
  double _strokeWidth = 8.0;
  bool _isEraser = false;
  List<Offset> _currentPoints = [];

  // Tool states
  bool _isBackgroundRemovalLoading = false;
  bool _isCropMode = false;
  Rect? _cropRect;
  String? _cachedImagePath;

  // Pan and zoom states
  bool _isPanning = false;
  Offset _lastPanPoint = Offset.zero;
  final double _minScale = 0.1;
  final double _maxScale = 5.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Column(
          children: [
            // Toolbar
            _buildToolbar(),

            // Canvas Area
            Expanded(child: _buildCanvas()),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // File Operations Group
                  if (_backgroundImage == null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          // Import Image Button
                          _buildToolButton(
                            icon: Icons.add_photo_alternate,
                            tooltip: 'Resim Ekle',
                            onTap: _importImage,
                          ),
                          // Add Transparent Blank Page Button
                          const SizedBox(width: 4),
                          _buildToolButton(
                            icon: Icons.crop_square,
                            tooltip: 'Boş Sayfa (Saydam)',
                            onTap: _addTransparentBlankPage,
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(width: 12),

                  // Drawing Tools Group
                  if (_backgroundImage != null && !_isCropMode) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          // Pen/Eraser Toggle
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildToggleButton(
                                  icon: Icons.brush,
                                  isSelected: !_isEraser,
                                  onTap: () =>
                                      setState(() => _isEraser = false),
                                  tooltip: 'Fırça',
                                ),
                                _buildToggleButton(
                                  icon: Icons.cleaning_services,
                                  isSelected: _isEraser,
                                  onTap: () => setState(() => _isEraser = true),
                                  tooltip: 'Silgi',
                                ),
                              ],
                            ),
                          ),

                          // Color Picker
                          if (!_isEraser) ...[
                            const SizedBox(width: 8),
                            Tooltip(
                              message: 'Renk Seç',
                              child: InkWell(
                                onTap: _showColorPicker,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _selectedColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],

                          // Brush Size
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Fırça Boyutu',
                            child: InkWell(
                              onTap: _showBrushSizePicker,
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${_strokeWidth.toInt()}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),
                  ],

                  // Edit Actions Group
                  if (_backgroundImage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          // Crop Toggle
                          _buildToolButton(
                            icon: _isCropMode ? Icons.check : Icons.crop,
                            tooltip: _isCropMode ? 'Kırpmayı Onayla' : 'Kırp',
                            onTap: _toggleCropMode,
                            isSuccess: _isCropMode,
                          ),

                          const SizedBox(width: 4),

                          // Undo
                          _buildToolButton(
                            icon: Icons.undo,
                            tooltip: 'Geri Al',
                            onTap: _lines.isNotEmpty ? _undo : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Export Group
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _cachedImagePath != null
                          ? DragItemWidget(
                              dragItemProvider: (request) async {
                                if (_cachedImagePath != null &&
                                    File(_cachedImagePath!).existsSync()) {
                                  final uri = Uri.file(_cachedImagePath!);
                                  return DragItem(
                                    localData: {'filePath': _cachedImagePath!},
                                  )..add(Formats.fileUri(uri));
                                }
                                return null;
                              },
                              allowedOperations: () => [DropOperation.copy],
                              child: DraggableWidget(
                                child: _buildToolButton(
                                  icon: Icons.open_with,
                                  tooltip: 'Sürükle',
                                  onTap: null,
                                ),
                              ),
                            )
                          : _buildToolButton(
                              icon: Icons.save,
                              tooltip: 'Hazırla',
                              onTap: _exportImage,
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
    bool isLoading = false,
    bool isSuccess = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: onTap == null
                ? Theme.of(context).colorScheme.surfaceContainer
                : isSuccess
                ? Colors.green.shade100
                : Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
            border: isSuccess
                ? Border.all(color: Colors.green, width: 2)
                : null,
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    icon,
                    size: 20,
                    color: isSuccess ? Colors.green.shade700 : null,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildCanvas() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFFF5F5F5),
          child: DropRegion(
            formats: const [Formats.fileUri],
            onDropOver: (event) => DropOperation.copy,
            onPerformDrop: (event) async {
              final items = event.session.items;
              for (final item in items) {
                final reader = item.dataReader!;
                if (reader.canProvide(Formats.fileUri)) {
                  reader.getValue<Uri>(Formats.fileUri, (uri) async {
                    if (uri != null) {
                      await _loadImageFromPath(uri.toFilePath());
                    }
                  });
                }
              }
            },
            child: _backgroundImage == null
                ? _buildEmptyState()
                : _buildImageCanvas(),
          ),
        ),
        if (_backgroundImage != null)
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${(_imageScale * 100).toInt()}%',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Bir resim sürükleyip bırakın\nveya "Resim Ekle" butonuna tıklayın',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Listener(
          onPointerSignal: (pointerSignal) {
            if (pointerSignal is PointerScrollEvent) {
              _handleScroll(pointerSignal, constraints);
            }
          },
          onPointerDown: (event) {
            if (event.buttons == 4) {
              // Middle mouse button
              _isPanning = true;
              _lastPanPoint = event.localPosition;
            }
          },
          onPointerMove: (event) {
            if (_isPanning && event.buttons == 4) {
              _handlePan(event.localPosition);
            }
          },
          onPointerUp: (event) {
            _isPanning = false;
          },
          child: RepaintBoundary(
            key: _canvasKey,
            child: GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              onPanStart: _isPanning
                  ? null
                  : (_isCropMode ? _onCropPanStart : _onDrawPanStart),
              onPanUpdate: _isPanning
                  ? null
                  : (_isCropMode ? _onCropPanUpdate : _onDrawPanUpdate),
              onPanEnd: _isPanning
                  ? null
                  : (_isCropMode ? _onCropPanEnd : _onDrawPanEnd),
              child: CustomPaint(
                painter: ImageEditorPainter(
                  backgroundImage: _backgroundImage,
                  imageX: _imageX,
                  imageY: _imageY,
                  imageScale: _imageScale,
                  lines: _lines,
                  currentPoints: _currentPoints,
                  currentColor: _selectedColor,
                  currentStrokeWidth: _strokeWidth,
                  isCurrentEraser: _isEraser,
                  cropRect: _cropRect,
                  isCropMode: _isCropMode,
                  canvasSize: Size(constraints.maxWidth, constraints.maxHeight),
                ),
                size: Size(constraints.maxWidth, constraints.maxHeight),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleScroll(PointerScrollEvent event, BoxConstraints constraints) {
    if (!HardwareKeyboard.instance.isControlPressed || _backgroundImage == null)
      return;

    final delta = event.scrollDelta.dy;
    final scaleFactor = delta > 0 ? 0.9 : 1.1;
    final newScale = (_imageScale * scaleFactor).clamp(_minScale, _maxScale);

    if (newScale != _imageScale) {
      // Zoom to cursor position
      final mousePos = event.localPosition;
      final oldImageWidth = _backgroundImage!.width * _imageScale;
      final oldImageHeight = _backgroundImage!.height * _imageScale;
      final newImageWidth = _backgroundImage!.width * newScale;
      final newImageHeight = _backgroundImage!.height * newScale;

      // Calculate zoom center offset
      final mouseOffsetX = mousePos.dx - _imageX;
      final mouseOffsetY = mousePos.dy - _imageY;
      final mouseRatioX = mouseOffsetX / oldImageWidth;
      final mouseRatioY = mouseOffsetY / oldImageHeight;

      setState(() {
        _imageScale = newScale;
        _imageX = mousePos.dx - (mouseRatioX * newImageWidth);
        _imageY = mousePos.dy - (mouseRatioY * newImageHeight);
        _cachedImagePath = null;
      });
    }
  }

  void _handlePan(Offset currentPoint) {
    if (_backgroundImage == null) return;

    final deltaX = currentPoint.dx - _lastPanPoint.dx;
    final deltaY = currentPoint.dy - _lastPanPoint.dy;

    setState(() {
      _imageX += deltaX;
      _imageY += deltaY;
      _lastPanPoint = currentPoint;
      _cachedImagePath = null;
    });
  }

  // Event Handlers
  void _handleKeyEvent(KeyEvent event) async {
    if (event is KeyDownEvent) {
      // Undo
      if (HardwareKeyboard.instance.isControlPressed &&
          event.logicalKey == LogicalKeyboardKey.keyZ) {
        if (_lines.isNotEmpty) {
          _undo();
        }
      }
      // Paste image from clipboard
      if (HardwareKeyboard.instance.isControlPressed &&
          event.logicalKey == LogicalKeyboardKey.keyV) {
        await _tryPasteImageFromClipboard();
      }
    }
  }

  Future<void> _tryPasteImageFromClipboard() async {
    try {
      final imageBytes = await Pasteboard.image;
      if (imageBytes == null) return;
      await _loadImageFromBytes(imageBytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Panodan resim alınamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadImageFromBytes(Uint8List bytes) async {
    try {
      final image = await decodeImageFromList(bytes);
      // Panodan gelen resmi temp dosyaya kaydet
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/clipboard_image_$timestamp.png');
      await tempFile.writeAsBytes(bytes);
      setState(() {
        _backgroundImage = image;
        _imagePath = tempFile.path;
        _fitImageToCanvas();
        _lines.clear();
        _currentPoints.clear();
        _cropRect = null;
        _isCropMode = false;
        _cachedImagePath = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Panodan resim eklendi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Panodan resim yüklenemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Drawing Methods
  void _onDrawPanStart(DragStartDetails details) {
    if (_isCropMode || _backgroundImage == null) return;

    final box = context.findRenderObject() as RenderBox;
    final offset = box.globalToLocal(details.globalPosition);
    final canvasPoint = Offset(
      offset.dx,
      offset.dy - 60,
    ); // Subtract toolbar height

    // Convert canvas coordinates to image-relative coordinates
    final imageRelativePoint = _canvasToImageCoordinates(canvasPoint);

    setState(() {
      _currentPoints = [imageRelativePoint];
      _cachedImagePath = null;
    });
  }

  void _onDrawPanUpdate(DragUpdateDetails details) {
    if (_isCropMode || _backgroundImage == null) return;

    final box = context.findRenderObject() as RenderBox;
    final offset = box.globalToLocal(details.globalPosition);
    final canvasPoint = Offset(
      offset.dx,
      offset.dy - 60,
    ); // Subtract toolbar height

    // Convert canvas coordinates to image-relative coordinates
    final imageRelativePoint = _canvasToImageCoordinates(canvasPoint);

    setState(() {
      _currentPoints.add(imageRelativePoint);
    });
  }

  void _onDrawPanEnd(DragEndDetails details) {
    if (_isCropMode || _currentPoints.isEmpty) return;

    setState(() {
      _lines.add(
        DrawnLine(
          points: List.from(_currentPoints),
          color: _selectedColor,
          strokeWidth: _strokeWidth,
          isEraser: _isEraser,
        ),
      );
      _currentPoints.clear();
      _cachedImagePath = null;
    });
  }

  // Convert canvas coordinates to image-relative coordinates (0-1 range)
  Offset _canvasToImageCoordinates(Offset canvasPoint) {
    if (_backgroundImage == null) return canvasPoint;

    // Get image bounds on canvas
    final imageWidth = _backgroundImage!.width * _imageScale;
    final imageHeight = _backgroundImage!.height * _imageScale;

    // Convert to image-relative coordinates (0-1 range)
    final relativeX = (canvasPoint.dx - _imageX) / imageWidth;
    final relativeY = (canvasPoint.dy - _imageY) / imageHeight;

    return Offset(relativeX, relativeY);
  }

  // Convert image-relative coordinates back to canvas coordinates
  Offset _imageToCanvasCoordinates(Offset imageRelativePoint) {
    if (_backgroundImage == null) return imageRelativePoint;

    // Get current image bounds on canvas
    final imageWidth = _backgroundImage!.width * _imageScale;
    final imageHeight = _backgroundImage!.height * _imageScale;

    // Convert back to canvas coordinates
    final canvasX = _imageX + (imageRelativePoint.dx * imageWidth);
    final canvasY = _imageY + (imageRelativePoint.dy * imageHeight);

    return Offset(canvasX, canvasY);
  }

  // Crop Methods
  void _onCropPanStart(DragStartDetails details) {
    if (!_isCropMode) return;

    final box = context.findRenderObject() as RenderBox;
    final offset = box.globalToLocal(details.globalPosition);
    final adjustedOffset = Offset(offset.dx, offset.dy - 60);

    setState(() {
      _cropRect = Rect.fromLTWH(adjustedOffset.dx, adjustedOffset.dy, 0, 0);
    });
  }

  void _onCropPanUpdate(DragUpdateDetails details) {
    if (!_isCropMode || _cropRect == null) return;

    final box = context.findRenderObject() as RenderBox;
    final offset = box.globalToLocal(details.globalPosition);
    final adjustedOffset = Offset(offset.dx, offset.dy - 60);

    setState(() {
      _cropRect = Rect.fromLTRB(
        _cropRect!.left,
        _cropRect!.top,
        adjustedOffset.dx,
        adjustedOffset.dy,
      );
    });
  }

  void _onCropPanEnd(DragEndDetails details) {
    // Crop rectangle is finalized
  }

  // Action Methods
  Future<void> _importImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      await _loadImageFromPath(result.files.single.path!);
    }
  }

  Future<void> _loadImageFromPath(String path) async {
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      final image = await decodeImageFromList(bytes);

      setState(() {
        _backgroundImage = image;
        _imagePath = path;
        _fitImageToCanvas();
        _lines.clear();
        _currentPoints.clear();
        _cropRect = null;
        _isCropMode = false;
        _cachedImagePath = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resim yüklenemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _fitImageToCanvas() {
    if (_backgroundImage == null) return;

    // Canvas boyutlarını al (toolbar hariç)
    final context = this.context;
    if (!mounted) return;

    final mediaQuery = MediaQuery.of(context);
    final canvasWidth = mediaQuery.size.width - 200; // Sidebar genişliği
    final canvasHeight =
        mediaQuery.size.height - 60 - 80; // Toolbar + bottom padding

    final imageWidth = _backgroundImage!.width.toDouble();
    final imageHeight = _backgroundImage!.height.toDouble();

    // Resim boyutlarına göre scale hesapla
    final scaleX = canvasWidth / imageWidth;
    final scaleY = canvasHeight / imageHeight;
    _imageScale = (scaleX < scaleY ? scaleX : scaleY) * 0.9; // %90'ı kullan

    // Resmi ortala
    final scaledWidth = imageWidth * _imageScale;
    final scaledHeight = imageHeight * _imageScale;
    _imageX = (canvasWidth - scaledWidth) / 2;
    _imageY = (canvasHeight - scaledHeight) / 2;
  }

  Future<void> _removeBackground() async {
    if (_imagePath == null) return;

    setState(() {
      _isBackgroundRemovalLoading = true;
    });

    try {
      // Check if Python is available
      ProcessResult pythonCheck;
      bool pythonFound = false;
      String pythonCmd = 'python';
      try {
        pythonCheck = await Process.run('python', ['--version']);
        pythonFound = pythonCheck.exitCode == 0;
      } catch (e) {
        try {
          pythonCheck = await Process.run('python3', ['--version']);
          pythonCmd = 'python3';
          pythonFound = pythonCheck.exitCode == 0;
        } catch (e2) {
          pythonFound = false;
        }
      }

      if (!pythonFound) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Python Yüklü Değil'),
              content: const SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Arka plan silme özelliği için Python 3.10+ gereklidir.',
                    ),
                    SizedBox(height: 8),
                    Text('Python yüklemek için aşağıdaki butona tıklayın:'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    // Python download link
                    const url = 'https://www.python.org/downloads/';
                    await Clipboard.setData(const ClipboardData(text: url));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Python indirme linki kopyalandı!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Python İndir'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kapat'),
                ),
              ],
            ),
          );
        }
        setState(() {
          _isBackgroundRemovalLoading = false;
        });
        return;
      }

      // Check if rembg is installed
      ProcessResult rembgCheck;
      bool rembgFound = false;
      try {
        rembgCheck = await Process.run(pythonCmd, [
          '-c',
          'import rembg; print("OK")',
        ]);
        rembgFound =
            rembgCheck.exitCode == 0 &&
            rembgCheck.stdout.toString().contains('OK');
      } catch (e) {
        rembgFound = false;
      }
      if (!rembgFound) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('rembg Yüklü Değil'),
              content: const SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Arka plan silme için rembg kütüphanesi gereklidir.'),
                    SizedBox(height: 8),
                    Text('Terminal/CMD\'de şu komutu çalıştırın:'),
                    SizedBox(height: 4),
                    SelectableText(
                      'pip install rembg[cpu]',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        backgroundColor: Color(0xFFEEEEEE),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Not: Bu tamamen ücretsiz ve offline çalışır!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await Clipboard.setData(
                      const ClipboardData(text: 'pip install rembg[cpu]'),
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Komut kopyalandı!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Komutu Kopyala'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kapat'),
                ),
              ],
            ),
          );
        }
        setState(() {
          _isBackgroundRemovalLoading = false;
        });
        return;
      }

      // Create temporary input and output files
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final inputFile = File('${tempDir.path}/rembg_input_$timestamp.png');
      final outputFile = File('${tempDir.path}/rembg_output_$timestamp.png');

      // Copy input image to temp file
      final originalFile = File(_imagePath!);
      await originalFile.copy(inputFile.path);

      // Run rembg command
      final result = await Process.run(pythonCmd, [
        '-c',
        '''
import sys
from rembg import remove
from PIL import Image
import io

try:
    # Read input image
    with open("${inputFile.path.replaceAll('\\', '/')}", "rb") as f:
        input_data = f.read()

    # Remove background
    output_data = remove(input_data)

    # Save output image
    with open("${outputFile.path.replaceAll('\\', '/')}", "wb") as f:
        f.write(output_data)

    print("SUCCESS")
except Exception as e:
    print(f"ERROR: {str(e)}")
    sys.exit(1)
''',
      ]);

      if (result.exitCode != 0) {
        throw Exception('Rembg işlemi başarısız: ${result.stderr}');
      }

      if (!result.stdout.toString().contains('SUCCESS')) {
        throw Exception('Rembg işlemi tamamlanamadı: ${result.stdout}');
      }

      // Check if output file exists
      if (!await outputFile.exists()) {
        throw Exception('Çıktı dosyası oluşturulamadı');
      }

      // Load the processed image
      final bytes = await outputFile.readAsBytes();
      final image = await decodeImageFromList(bytes);

      setState(() {
        _backgroundImage = image;
        _fitImageToCanvas();
        _lines.clear();
        _currentPoints.clear();
        _cachedImagePath = null;
      });

      // Clean up temp files
      try {
        await inputFile.delete();
        await outputFile.delete();
      } catch (e) {
        // Ignore cleanup errors
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arka plan başarıyla silindi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Arka plan silinemedi: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Yardım',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Rembg Kurulumu'),
                    content: const SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Arka plan silme özelliği için gereksinimler:'),
                          SizedBox(height: 8),
                          Text('1. Python 3.10+ yüklü olmalı'),
                          SizedBox(height: 4),
                          Text('2. Terminal/CMD\'de şu komutu çalıştırın:'),
                          SizedBox(height: 4),
                          SelectableText(
                            'pip install rembg[cpu]',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              backgroundColor: Color(0xFFEEEEEE),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Not: Bu tamamen ücretsiz ve offline çalışır!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tamam'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isBackgroundRemovalLoading = false;
      });
    }
  }

  void _toggleCropMode() {
    setState(() {
      _isCropMode = !_isCropMode;
      if (!_isCropMode && _cropRect != null) {
        _applyCrop();
      } else if (_isCropMode) {
        _cropRect = null; // Reset crop rectangle when entering crop mode
      }
    });
  }

  void _applyCrop() {
    if (_cropRect == null || _backgroundImage == null) return;

    try {
      // Kırpma rectangle'ının canvas içindeki konumunu doğrudan kullan
      // Sadece canvas sınırları içinde olduğundan emin ol
      final canvasWidth =
          MediaQuery.of(context).size.width - 200; // sidebar width
      final canvasHeight =
          MediaQuery.of(context).size.height - 60; // toolbar height

      final clampedRect = Rect.fromLTRB(
        _cropRect!.left.clamp(0.0, canvasWidth.toDouble()),
        _cropRect!.top.clamp(0.0, canvasHeight.toDouble()),
        _cropRect!.right.clamp(0.0, canvasWidth.toDouble()),
        _cropRect!.bottom.clamp(0.0, canvasHeight.toDouble()),
      );

      if (clampedRect.width < 10 || clampedRect.height < 10) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kırpma alanı çok küçük'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Kırpma overlay'ini kaldır ve async işlem başlat
      final tempCropRect = _cropRect;
      setState(() {
        _cropRect = null; // Overlay'i kaldır
      });

      // Bir frame bekleyip sonra kırpma işlemini yap
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cropImageAsync(clampedRect);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kırpma hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cropImageAsync(Rect cropRect) async {
    try {
      // Create a transparent image with only the cropped content
      final croppedWidth = cropRect.width.toInt();
      final croppedHeight = cropRect.height.toInt();

      if (croppedWidth < 1 || croppedHeight < 1) return;

      // Create a custom painter for the cropped area
      final painter = CroppedImagePainter(
        backgroundImage: _backgroundImage,
        imageX: _imageX,
        imageY: _imageY,
        imageScale: _imageScale,
        lines: _lines,
        cropRect: cropRect,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Paint the cropped content
      painter.paint(
        canvas,
        Size(croppedWidth.toDouble(), croppedHeight.toDouble()),
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(croppedWidth, croppedHeight);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      // Decode the new image
      final pngBytes = byteData.buffer.asUint8List();
      final newImage = await decodeImageFromList(pngBytes);

      setState(() {
        _backgroundImage = newImage;
        _fitImageToCanvas();
        _lines.clear();
        _currentPoints.clear();
        _cachedImagePath = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resim kırpıldı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kırpma işlemi başarısız: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _undo() {
    if (_lines.isNotEmpty) {
      setState(() {
        _undoHistory.add(List.from(_lines));
        _lines.removeLast();
        _cachedImagePath = null;
      });
    }
  }

  Future<void> _exportImage() async {
    // Export the final image with original dimensions and transparent background
    try {
      if (_backgroundImage == null) return;

      // Use original image dimensions
      final originalWidth = _backgroundImage!.width;
      final originalHeight = _backgroundImage!.height;

      // Create a custom painter that renders at original size
      final painter = TransparentImagePainter(
        backgroundImage: _backgroundImage,
        imageX: 0, // At export, image starts at origin
        imageY: 0,
        imageScale: 1.0, // Original scale
        lines: _lines,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Render at original image size
      painter.paint(
        canvas,
        Size(originalWidth.toDouble(), originalHeight.toDouble()),
      );

      final picture = recorder.endRecording();
      final image = await picture.toImage(originalWidth, originalHeight);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/edited_image_$timestamp.png');
      await file.writeAsBytes(bytes);

      setState(() {
        _cachedImagePath = file.path;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resim hazırlandı! Şimdi sürükleyebilirsiniz.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Renk Seç'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) => setState(() => _selectedColor = color),
              enableAlpha: false,
              displayThumbColor: true,
              pickerAreaBorderRadius: BorderRadius.circular(8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  void _showBrushSizePicker() {
    showDialog(
      context: context,
      builder: (context) {
        double tempSize = _strokeWidth;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(_isEraser ? 'Silgi Boyutu' : 'Fırça Boyutu'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 60,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Container(
                        width: tempSize * 2,
                        height: tempSize * 2,
                        decoration: BoxDecoration(
                          color: _isEraser ? Colors.white : _selectedColor,
                          shape: BoxShape.circle,
                          border: _isEraser
                              ? Border.all(color: Colors.grey)
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('1'),
                      Expanded(
                        child: Slider(
                          value: tempSize,
                          min: 1.0,
                          max: 30.0,
                          divisions: 29,
                          onChanged: (value) {
                            setDialogState(() => tempSize = value);
                          },
                        ),
                      ),
                      const Text('30'),
                    ],
                  ),
                  Text('${tempSize.toInt()} px'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _strokeWidth = tempSize);
                    Navigator.pop(context);
                  },
                  child: const Text('Tamam'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Yeni fonksiyon: Boş, saydam tuval ekle
  Future<void> _addTransparentBlankPage() async {
    // İstersen dialog ile boyut sorabilirsin, şimdilik sabit 1024x768
    const int width = 1024;
    const int height = 768;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    // Hiçbir şey çizme, tamamen saydam bırak
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    setState(() {
      _backgroundImage = image;
      _imagePath = null;
      _fitImageToCanvas();
      _lines.clear();
      _currentPoints.clear();
      _cropRect = null;
      _isCropMode = false;
      _cachedImagePath = null;
    });
  }
}

// Drawing Line Class
class DrawnLine {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isEraser;

  DrawnLine({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isEraser = false,
  });
}

// Custom Painter
class ImageEditorPainter extends CustomPainter {
  final ui.Image? backgroundImage;
  final double imageX;
  final double imageY;
  final double imageScale;
  final List<DrawnLine> lines;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentStrokeWidth;
  final bool isCurrentEraser;
  final Rect? cropRect;
  final bool isCropMode;
  final Size canvasSize;

  ImageEditorPainter({
    required this.backgroundImage,
    required this.imageX,
    required this.imageY,
    required this.imageScale,
    required this.lines,
    required this.currentPoints,
    required this.currentColor,
    required this.currentStrokeWidth,
    required this.isCurrentEraser,
    this.cropRect,
    required this.isCropMode,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Transparent/Checkered background pattern
    _drawTransparencyBackground(canvas, size);

    // Create a layer for the image and drawings
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Draw background image
    if (backgroundImage != null) {
      final paint = Paint()
        ..filterQuality = FilterQuality.high
        ..isAntiAlias = true;

      final srcRect = Rect.fromLTWH(
        0,
        0,
        backgroundImage!.width.toDouble(),
        backgroundImage!.height.toDouble(),
      );

      final dstRect = Rect.fromLTWH(
        imageX,
        imageY,
        backgroundImage!.width * imageScale,
        backgroundImage!.height * imageScale,
      );

      canvas.drawImageRect(backgroundImage!, srcRect, dstRect, paint);
    }

    // Draw completed lines (convert from image-relative to canvas coordinates)
    for (final line in lines) {
      if (line.points.isEmpty || backgroundImage == null) continue;

      // Convert image-relative coordinates to canvas coordinates
      final canvasPoints = line.points
          .map((point) => _imageRelativeToCanvas(point))
          .toList();

      if (line.isEraser) {
        // For eraser, use clear blend mode
        final paint = Paint()
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = line.strokeWidth * imageScale
          ..style = PaintingStyle.stroke
          ..blendMode = BlendMode.clear
          ..isAntiAlias = true;

        _drawSmoothPath(canvas, canvasPoints, paint);
      } else {
        // For normal drawing
        final paint = Paint()
          ..color = line.color
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = line.strokeWidth * imageScale
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true;

        _drawSmoothPath(canvas, canvasPoints, paint);
      }
    }

    // Draw current line (convert from image-relative to canvas coordinates)
    if (currentPoints.isNotEmpty && !isCropMode && backgroundImage != null) {
      // Convert image-relative coordinates to canvas coordinates
      final canvasPoints = currentPoints
          .map((point) => _imageRelativeToCanvas(point))
          .toList();

      if (isCurrentEraser) {
        // For current eraser stroke
        final paint = Paint()
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = currentStrokeWidth * imageScale
          ..style = PaintingStyle.stroke
          ..blendMode = BlendMode.clear
          ..isAntiAlias = true;

        _drawSmoothPath(canvas, canvasPoints, paint);
      } else {
        // For current normal stroke
        final paint = Paint()
          ..color = currentColor
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = currentStrokeWidth * imageScale
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true;

        _drawSmoothPath(canvas, canvasPoints, paint);
      }
    }

    canvas.restore();

    // Draw crop rectangle (outside the layer)
    if (isCropMode && cropRect != null) {
      final cropPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final dashedPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      canvas.drawRect(cropRect!, dashedPaint);
      canvas.drawRect(cropRect!, cropPaint);
    }
  }

  // Convert image-relative coordinates (0-1 range) to canvas coordinates
  Offset _imageRelativeToCanvas(Offset imageRelativePoint) {
    if (backgroundImage == null) return imageRelativePoint;

    // Get current image bounds on canvas
    final imageWidth = backgroundImage!.width * imageScale;
    final imageHeight = backgroundImage!.height * imageScale;

    // Convert back to canvas coordinates
    final canvasX = imageX + (imageRelativePoint.dx * imageWidth);
    final canvasY = imageY + (imageRelativePoint.dy * imageHeight);

    return Offset(canvasX, canvasY);
  }

  void _drawTransparencyBackground(Canvas canvas, Size size) {
    const squareSize = 16.0;
    final paint1 = Paint()..color = const Color(0xFFFFFFFF);
    final paint2 = Paint()..color = const Color(0xFFE0E0E0);

    for (double x = 0; x < size.width; x += squareSize) {
      for (double y = 0; y < size.height; y += squareSize) {
        final isEven =
            ((x / squareSize).floor() + (y / squareSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, squareSize, squareSize),
          isEven ? paint1 : paint2,
        );
      }
    }
  }

  void _drawSmoothPath(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) {
      if (points.isNotEmpty) {
        canvas.drawCircle(points.first, paint.strokeWidth / 2, paint);
      }
      return;
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// Transparent Export Painter (no background)
class TransparentImagePainter extends CustomPainter {
  final ui.Image? backgroundImage;
  final double imageX;
  final double imageY;
  final double imageScale;
  final List<DrawnLine> lines;

  TransparentImagePainter({
    required this.backgroundImage,
    required this.imageX,
    required this.imageY,
    required this.imageScale,
    required this.lines,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundImage == null) return;

    // Create a layer for the image and drawings
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Draw background image at origin (0,0) for export
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    final srcRect = Rect.fromLTWH(
      0,
      0,
      backgroundImage!.width.toDouble(),
      backgroundImage!.height.toDouble(),
    );

    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(backgroundImage!, srcRect, dstRect, paint);

    // Draw completed lines (coordinates are already image-relative, 0-1 range)
    for (final line in lines) {
      if (line.points.isEmpty) continue;

      // Convert from image-relative (0-1) to export canvas coordinates
      final exportPoints = line.points.map((point) {
        return Offset(point.dx * size.width, point.dy * size.height);
      }).toList();

      // Filter out points that are outside the image bounds
      final validPoints = exportPoints
          .where(
            (point) =>
                point.dx >= 0 &&
                point.dx <= size.width &&
                point.dy >= 0 &&
                point.dy <= size.height,
          )
          .toList();

      if (validPoints.isEmpty) continue;

      if (line.isEraser) {
        // For eraser, use clear blend mode
        final linePaint = Paint()
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = line.strokeWidth
          ..style = PaintingStyle.stroke
          ..blendMode = BlendMode.clear
          ..isAntiAlias = true;

        _drawSmoothPath(canvas, validPoints, linePaint);
      } else {
        // For normal drawing
        final linePaint = Paint()
          ..color = line.color
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = line.strokeWidth
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true;

        _drawSmoothPath(canvas, validPoints, linePaint);
      }
    }

    canvas.restore();
  }

  void _drawSmoothPath(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) {
      if (points.isNotEmpty) {
        canvas.drawCircle(points.first, paint.strokeWidth / 2, paint);
      }
      return;
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Cropped Image Painter
class CroppedImagePainter extends CustomPainter {
  final ui.Image? backgroundImage;
  final double imageX;
  final double imageY;
  final double imageScale;
  final List<DrawnLine> lines;
  final Rect cropRect;

  CroppedImagePainter({
    required this.backgroundImage,
    required this.imageX,
    required this.imageY,
    required this.imageScale,
    required this.lines,
    required this.cropRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundImage == null) return;

    // Create a layer for the image and drawings
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Calculate the portion of the image to draw
    final imageWidth = backgroundImage!.width * imageScale;
    final imageHeight = backgroundImage!.height * imageScale;

    // Map crop rect to image coordinates
    final cropLeftInImage = (cropRect.left - imageX) / imageWidth;
    final cropTopInImage = (cropRect.top - imageY) / imageHeight;
    final cropWidthInImage = cropRect.width / imageWidth;
    final cropHeightInImage = cropRect.height / imageHeight;

    // Clamp to image bounds
    final srcRect = Rect.fromLTWH(
      (cropLeftInImage * backgroundImage!.width).clamp(
        0.0,
        backgroundImage!.width.toDouble(),
      ),
      (cropTopInImage * backgroundImage!.height).clamp(
        0.0,
        backgroundImage!.height.toDouble(),
      ),
      (cropWidthInImage * backgroundImage!.width).clamp(
        0.0,
        backgroundImage!.width.toDouble(),
      ),
      (cropHeightInImage * backgroundImage!.height).clamp(
        0.0,
        backgroundImage!.height.toDouble(),
      ),
    );

    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Draw the cropped portion of the image
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    canvas.drawImageRect(backgroundImage!, srcRect, dstRect, paint);

    // Draw completed lines (convert from image-relative to export coordinates)
    for (final line in lines) {
      if (line.points.isEmpty) continue;

      // Convert image-relative coordinates to crop canvas coordinates
      final exportPoints = line.points.map((point) {
        // Convert from image-relative (0-1) to crop area coordinates
        final exportX =
            (point.dx - cropLeftInImage) * (size.width / cropWidthInImage);
        final exportY =
            (point.dy - cropTopInImage) * (size.height / cropHeightInImage);
        return Offset(exportX, exportY);
      }).toList();

      // Filter out points that are outside the crop area
      final validPoints = exportPoints.where((point) {
        return point.dx >= 0 &&
            point.dx <= size.width &&
            point.dy >= 0 &&
            point.dy <= size.height;
      }).toList();

      if (validPoints.isEmpty) continue;

      if (line.isEraser) {
        // For eraser, use clear blend mode
        final linePaint = Paint()
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = line.strokeWidth
          ..style = PaintingStyle.stroke
          ..blendMode = BlendMode.clear
          ..isAntiAlias = true;

        _drawSmoothPath(canvas, validPoints, linePaint);
      } else {
        // For normal drawing
        final linePaint = Paint()
          ..color = line.color
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = line.strokeWidth
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true;

        _drawSmoothPath(canvas, validPoints, linePaint);
      }
    }

    canvas.restore();
  }

  void _drawSmoothPath(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) {
      if (points.isNotEmpty) {
        canvas.drawCircle(points.first, paint.strokeWidth / 2, paint);
      }
      return;
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
