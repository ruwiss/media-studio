import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_studio/providers/app_provider.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isCollapsed = appProvider.isSidebarCollapsed;

    return InkWell(
      onTap: appProvider.toggleSidebar,
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: appProvider.toggleSidebar,
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                mainAxisAlignment: isCollapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/icons/icon.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.video_library,
                            color: Colors.white,
                            size: 16,
                          );
                        },
                      ),
                    ),
                  ),
                  if (!isCollapsed) ...[
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Media Studio',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Navigation Menu
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  _buildNavItem(
                    context,
                    icon: Icons.record_voice_over,
                    title: 'Ses Oluştur',
                    index: 0,
                    isSelected: appProvider.selectedTabIndex == 0,
                    onTap: () => appProvider.setSelectedTabIndex(0),
                    isCollapsed: isCollapsed,
                  ),
                  const SizedBox(height: 3),
                  _buildNavItem(
                    context,
                    icon: Icons.library_music,
                    title: 'Ses Efektleri',
                    index: 1,
                    isSelected: appProvider.selectedTabIndex == 1,
                    onTap: () => appProvider.setSelectedTabIndex(1),
                    isCollapsed: isCollapsed,
                  ),
                  const SizedBox(height: 3),
                  _buildNavItem(
                    context,
                    icon: Icons.draw,
                    title: 'Çizim',
                    index: 2,
                    isSelected: appProvider.selectedTabIndex == 2,
                    onTap: () => appProvider.setSelectedTabIndex(2),
                    isCollapsed: isCollapsed,
                  ),
                  const SizedBox(height: 3),
                  _buildNavItem(
                    context,
                    icon: Icons.image,
                    title: 'Medya',
                    index: 3,
                    isSelected: appProvider.selectedTabIndex == 3,
                    onTap: () => appProvider.setSelectedTabIndex(3),
                    isCollapsed: isCollapsed,
                  ),
                  const SizedBox(height: 3),
                  _buildNavItem(
                    context,
                    icon: Icons.settings,
                    title: 'Ayarlar',
                    index: 4,
                    isSelected: appProvider.selectedTabIndex == 4,
                    onTap: () => appProvider.setSelectedTabIndex(4),
                    isCollapsed: isCollapsed,
                  ),
                  const SizedBox(height: 3),
                  _buildNavItem(
                    context,
                    icon: Icons.download,
                    title: 'İndirilenler',
                    index: 5,
                    isSelected: appProvider.selectedTabIndex == 5,
                    onTap: () => appProvider.setSelectedTabIndex(5),
                    isCollapsed: isCollapsed,
                  ),
                ],
              ),
            ),
          ),

          // Hakkında butonu en altta
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: _buildNavItem(
              context,
              icon: Icons.info_outline,
              title: 'Hakkında',
              index: 6,
              isSelected: appProvider.selectedTabIndex == 6,
              onTap: () => appProvider.setSelectedTabIndex(6),
              isCollapsed: isCollapsed,
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
    required bool isCollapsed,
  }) {
    return Tooltip(
      message: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: double.infinity,
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: isCollapsed
                ? Center(
                    child: Icon(
                      icon,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 14,
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        icon,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
