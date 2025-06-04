import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_studio/providers/app_provider.dart';
import 'package:media_studio/screens/voice_screen.dart';
import 'package:media_studio/screens/sound_effects_screen.dart';
import 'package:media_studio/screens/drawing_screen.dart';
import 'package:media_studio/screens/image_editor_screen.dart';
import 'package:media_studio/screens/media_screen.dart';
import 'package:media_studio/screens/settings_screen.dart';
import 'package:media_studio/screens/downloads_screen.dart';
import 'package:media_studio/screens/about_screen.dart';

class ContentArea extends StatelessWidget {
  const ContentArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        switch (appProvider.selectedTabIndex) {
          case 0:
            return const VoiceScreen();
          case 1:
            return const SoundEffectsScreen();
          case 2:
            return const DrawingScreen();
          case 3:
            return const ImageEditorScreen();
          case 4:
            return const MediaScreen();
          case 5:
            return const SettingsScreen();
          case 6:
            return const DownloadsScreen();
          case 7:
            return const AboutScreen();
          default:
            return const VoiceScreen();
        }
      },
    );
  }
}
