import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_studio/providers/app_provider.dart';
import 'package:media_studio/screens/voice_screen.dart';
import 'package:media_studio/screens/sound_effects_screen.dart';
import 'package:media_studio/screens/drawing_screen.dart';
import 'package:media_studio/screens/media_screen.dart';
import 'package:media_studio/screens/settings_screen.dart';
import 'package:media_studio/screens/downloads_screen.dart';
import 'package:media_studio/screens/about_screen.dart';

class ContentArea extends StatelessWidget {
  const ContentArea({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _getSelectedScreen(appProvider.selectedTabIndex),
    );
  }

  Widget _getSelectedScreen(int index) {
    switch (index) {
      case 0:
        return const VoiceScreen();
      case 1:
        return const SoundEffectsScreen();
      case 2:
        return const DrawingScreen();
      case 3:
        return const MediaScreen();
      case 4:
        return const SettingsScreen();
      case 5:
        return const DownloadsScreen();
      case 6:
        return const AboutScreen();
      default:
        return const VoiceScreen();
    }
  }
}
