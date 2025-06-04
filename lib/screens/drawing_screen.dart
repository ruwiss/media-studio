import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'dart:io';

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  final List<DrawnLine> _lines = [];
  final List<List<DrawnLine>> _undoHistory = [];
  final FocusNode _focusNode = FocusNode();

  Color _selectedColor = Colors.black;
  double _strokeWidth = 8.0;
  bool _isEraser = false;
  List<Offset> _currentPoints = [];
  String? _cachedImagePath;

  @override
  void initState() {
    super.initState();
    // Focus'u al ki keyboard dinleyebilsin
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
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Kalem/Silgi Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
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
                          icon: Icons.edit,
                          isSelected: !_isEraser,
                          onTap: () => setState(() => _isEraser = false),
                          tooltip: 'Kalem',
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

                  const SizedBox(width: 16),

                  // Renk Seçici
                  if (!_isEraser) ...[
                    InkWell(
                      onTap: _showColorPicker,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],

                  // Fırça Boyutu Popup
                  InkWell(
                    onTap: _showBrushSizePicker,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.brush,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_strokeWidth.toInt()}px',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Geri Al
                  IconButton(
                    onPressed: _lines.isNotEmpty ? _undo : null,
                    icon: const Icon(Icons.undo),
                    tooltip: 'Geri Al (Ctrl+Z)',
                  ),

                  // Temizle
                  IconButton(
                    onPressed: _lines.isNotEmpty ? _clear : null,
                    icon: const Icon(Icons.clear),
                    tooltip: 'Temizle',
                  ),

                  // Sürükle Bırak Butonu
                  if (_lines.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _cachedImagePath != null
                        ? DragItemWidget(
                            dragItemProvider: (request) async {
                              print(
                                'Drag requested, cached path: $_cachedImagePath',
                              );

                              if (_cachedImagePath != null &&
                                  File(_cachedImagePath!).existsSync()) {
                                print('Providing drag item: $_cachedImagePath');
                                final uri = Uri.file(_cachedImagePath!);
                                return DragItem(
                                  localData: {'filePath': _cachedImagePath!},
                                )..add(Formats.fileUri(uri));
                              }

                              print('No file available for drag');
                              return null;
                            },
                            allowedOperations: () => [DropOperation.copy],
                            child: DraggableWidget(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.open_with,
                                      size: 16,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Sürükle',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: () async {
                              print('Hazırla butonuna tıklandı');
                              await _updateCachedImage();
                              if (_cachedImagePath != null &&
                                  File(_cachedImagePath!).existsSync()) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Dosya hazırlandı! Şimdi sürükleyebilirsiniz.',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Dosya hazırlanamadı, tekrar deneyin.',
                                    ),
                                    duration: Duration(seconds: 2),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.download,
                                    size: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Hazırla',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ],
                ],
              ),
            ),

            // Çizim Alanı
            Expanded(
              child: GestureDetector(
                onTap: () => _focusNode.requestFocus(),
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: RepaintBoundary(
                    key: _repaintKey,
                    child: GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: CustomPaint(
                        painter: DrawingPainter(
                          _lines,
                          _currentPoints,
                          _selectedColor,
                          _strokeWidth,
                          _isEraser,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // Ctrl+Z için geri alma
      if (HardwareKeyboard.instance.isControlPressed &&
          event.logicalKey == LogicalKeyboardKey.keyZ) {
        if (_lines.isNotEmpty) {
          _undo();
        }
      }
    }
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
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
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
                  // Preview
                  Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
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
                  // Slider
                  Row(
                    children: [
                      Text('1', style: Theme.of(context).textTheme.bodySmall),
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
                      Text('30', style: Theme.of(context).textTheme.bodySmall),
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

  void _onPanStart(DragStartDetails details) {
    final box = context.findRenderObject() as RenderBox;
    final offset = box.globalToLocal(details.globalPosition);
    final adjustedOffset = Offset(offset.dx, offset.dy - 60);

    setState(() {
      _currentPoints = [adjustedOffset];
      // Yeni çizim başladığında cache'i invalidate et
      _cachedImagePath = null;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final box = context.findRenderObject() as RenderBox;
    final offset = box.globalToLocal(details.globalPosition);
    final adjustedOffset = Offset(offset.dx, offset.dy - 60);

    setState(() {
      _currentPoints.add(adjustedOffset);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentPoints.isNotEmpty) {
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
        // Yeni çizim sonrası cache'i invalidate et
        _cachedImagePath = null;
      });
      // Otomatik kaydetmeyi kaldır - sadece butona tıklayınca kaydetsin
    }
  }

  Future<void> _updateCachedImage() async {
    try {
      // Render tamamlanana kadar bekle
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        print('Boundary null');
        return;
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        print('ByteData null');
        return;
      }

      final bytes = byteData.buffer.asUint8List();

      // Image paketini kullanarak transparan PNG oluştur
      final originalImage = img.decodePng(bytes);
      if (originalImage == null) {
        print('Original image null');
        return;
      }

      // Beyaz arka planı transparan yap
      final transparentImage = img.Image(
        width: originalImage.width,
        height: originalImage.height,
        numChannels: 4,
      );

      img.fill(transparentImage, color: img.ColorRgba8(255, 255, 255, 0));

      for (int y = 0; y < originalImage.height; y++) {
        for (int x = 0; x < originalImage.width; x++) {
          final pixel = originalImage.getPixel(x, y);
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();

          // Eğer pixel beyaz değilse (çizim varsa), kopyala
          if (!(r > 250 && g > 250 && b > 250)) {
            transparentImage.setPixelRgba(x, y, r, g, b, 255);
          }
        }
      }

      final pngBytes = img.encodePng(transparentImage);

      // Temp klasörüne kaydet
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/drawing_$timestamp.png');
      await file.writeAsBytes(pngBytes);

      setState(() {
        _cachedImagePath = file.path;
      });

      print('Image cached: $_cachedImagePath');
    } catch (e) {
      print('Cache error: $e');
    }
  }

  void _undo() {
    if (_lines.isNotEmpty) {
      setState(() {
        _undoHistory.add(List.from(_lines));
        _lines.removeLast();
        // Undo sonrası cache'i invalidate et
        _cachedImagePath = null;
      });
    }
  }

  void _clear() {
    setState(() {
      _undoHistory.add(List.from(_lines));
      _lines.clear();
      _currentPoints.clear();
      _cachedImagePath = null;
    });
  }
}

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

class DrawingPainter extends CustomPainter {
  final List<DrawnLine> lines;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentStrokeWidth;
  final bool isCurrentEraser;

  DrawingPainter(
    this.lines,
    this.currentPoints,
    this.currentColor,
    this.currentStrokeWidth,
    this.isCurrentEraser,
  );

  @override
  void paint(Canvas canvas, Size size) {
    // Beyaz arka plan
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Tamamlanmış çizgileri çiz
    for (final line in lines) {
      if (line.points.isEmpty) continue;

      if (line.isEraser) {
        final eraserPaint = Paint()
          ..color = Colors.white
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = line.strokeWidth
          ..style = PaintingStyle.stroke
          ..blendMode = BlendMode.src;

        _drawSmoothPath(canvas, line.points, eraserPaint);
      } else {
        final paint = Paint()
          ..color = line.color
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = line.strokeWidth
          ..style = PaintingStyle.stroke;

        _drawSmoothPath(canvas, line.points, paint);
      }
    }

    // Şu anda çizilen çizgiyi çiz (real-time preview)
    if (currentPoints.isNotEmpty) {
      final currentPaint = Paint()
        ..color = isCurrentEraser ? Colors.white : currentColor
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = currentStrokeWidth
        ..style = PaintingStyle.stroke;

      if (isCurrentEraser) {
        currentPaint.blendMode = BlendMode.src;
      }

      _drawSmoothPath(canvas, currentPoints, currentPaint);
    }
  }

  void _drawSmoothPath(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) {
      if (points.isNotEmpty) {
        canvas.drawCircle(
          points.first,
          paint.strokeWidth / 2,
          paint..style = PaintingStyle.fill,
        );
      }
      return;
    }

    if (points.length == 2) {
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);
      path.lineTo(points[1].dx, points[1].dy);
      paint.style = PaintingStyle.stroke;
      canvas.drawPath(path, paint);
      return;
    }

    // Catmull-Rom spline yumuşatma
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    final firstControlPoint = Offset(
      (points[0].dx + points[1].dx) / 2,
      (points[0].dy + points[1].dy) / 2,
    );

    if (points.length > 2) {
      path.quadraticBezierTo(
        points[1].dx,
        points[1].dy,
        firstControlPoint.dx,
        firstControlPoint.dy,
      );

      for (int i = 1; i < points.length - 2; i++) {
        final p0 = points[i - 1];
        final p1 = points[i];
        final p2 = points[i + 1];
        final p3 = points[i + 2];

        final cp1 = Offset(
          p1.dx + (p2.dx - p0.dx) / 6,
          p1.dy + (p2.dy - p0.dy) / 6,
        );

        final cp2 = Offset(
          p2.dx - (p3.dx - p1.dx) / 6,
          p2.dy - (p3.dy - p1.dy) / 6,
        );

        path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
      }

      final lastIndex = points.length - 1;
      final secondLastIndex = lastIndex - 1;

      path.quadraticBezierTo(
        points[secondLastIndex].dx,
        points[secondLastIndex].dy,
        points[lastIndex].dx,
        points[lastIndex].dy,
      );
    } else {
      path.quadraticBezierTo(
        points[1].dx,
        points[1].dy,
        points[2].dx,
        points[2].dy,
      );
    }

    paint.style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
