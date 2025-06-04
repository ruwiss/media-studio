import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:media_studio/providers/app_provider.dart';
import 'package:media_studio/screens/home_screen.dart';
import 'package:screen_retriever/screen_retriever.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop pencere ayarları
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(700, 950),
    minimumSize: Size(700, 950),
    maximumSize: Size(1000, 2000),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'Media Studio - Video Düzenleme Yardımcısı',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    // Ekranın sağ kenarına yasla
    final display = await ScreenRetriever.instance.getPrimaryDisplay();
    final screenWidth = display.size.width;
    final windowSize = await windowManager.getSize();
    final x = screenWidth - windowSize.width;
    final y = 0;
    await windowManager.setPosition(Offset(x.toDouble(), y.toDouble()));
  });

  // Flutter keyboard hatalarını yakalamak için
  FlutterError.onError = (FlutterErrorDetails details) {
    // Keyboard event hatalarını sessizce geç
    if (details.exception.toString().contains('keysPressed') ||
        details.exception.toString().contains('RawKeyDownEvent')) {
      return;
    }
    // Diğer hataları normal şekilde logla
    FlutterError.presentError(details);
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppProvider(),
      child: MaterialApp(
        title: 'Media Studio',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF8B5CF6),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Segoe UI',
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF8B5CF6),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Segoe UI',
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
