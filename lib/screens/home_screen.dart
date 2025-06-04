import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_studio/providers/app_provider.dart';
import 'package:media_studio/widgets/sidebar.dart';
import 'package:media_studio/widgets/content_area.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Row(
            children: [
              // Sidebar - sabit boyut
              const Sidebar(),
              // Content Area
              const Expanded(child: ContentArea()),
            ],
          ),
        );
      },
    );
  }
}
