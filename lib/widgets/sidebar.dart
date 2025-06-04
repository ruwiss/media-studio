import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_studio/providers/app_provider.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return SizedBox(
      width: 200,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            right: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(context, appProvider),

            // Navigation Menu
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  children: [
                    _buildNavItem(
                      context,
                      icon: Icons.record_voice_over_rounded,
                      title: 'Ses Oluştur',
                      index: 0,
                      isSelected: appProvider.selectedTabIndex == 0,
                      onTap: () => appProvider.setSelectedTabIndex(0),
                    ),
                    const SizedBox(height: 4),
                    _buildNavItem(
                      context,
                      icon: Icons.image_rounded,
                      title: 'Medya',
                      index: 3,
                      isSelected: appProvider.selectedTabIndex == 3,
                      onTap: () => appProvider.setSelectedTabIndex(3),
                    ),
                    const SizedBox(height: 4),
                    _buildNavItem(
                      context,
                      icon: Icons.music_note_outlined,
                      title: 'Ses Efektleri',
                      index: 1,
                      isSelected: appProvider.selectedTabIndex == 1,
                      onTap: () => appProvider.setSelectedTabIndex(1),
                    ),
                    const SizedBox(height: 4),
                    _buildNavItem(
                      context,
                      icon: Icons.panorama_horizontal_outlined,
                      title: 'Resim Editörü',
                      index: 2,
                      isSelected: appProvider.selectedTabIndex == 2,
                      onTap: () => appProvider.setSelectedTabIndex(2),
                    ),

                    const SizedBox(height: 4),
                    _buildNavItem(
                      context,
                      icon: Icons.settings_rounded,
                      title: 'Ayarlar',
                      index: 4,
                      isSelected: appProvider.selectedTabIndex == 4,
                      onTap: () => appProvider.setSelectedTabIndex(4),
                    ),
                    const SizedBox(height: 4),
                    _buildNavItem(
                      context,
                      icon: Icons.download_rounded,
                      title: 'İndirilenler',
                      index: 5,
                      isSelected: appProvider.selectedTabIndex == 5,
                      onTap: () => appProvider.setSelectedTabIndex(5),
                    ),
                  ],
                ),
              ),
            ),

            // Hakkında butonu en altta
            Padding(
              padding: const EdgeInsets.all(8),
              child: _buildNavItem(
                context,
                icon: Icons.info_outline_rounded,
                title: 'Hakkında',
                index: 6,
                isSelected: appProvider.selectedTabIndex == 6,
                onTap: () => appProvider.setSelectedTabIndex(6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppProvider appProvider) {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/icons/icon.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.video_library_rounded,
                    color: Colors.white,
                    size: 20,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Media Studio',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
