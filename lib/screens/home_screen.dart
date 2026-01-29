import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/mindmap_provider.dart';
import '../providers/review_provider.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/mindmap_card.dart';
import 'editor_screen.dart';
import 'mindmap_screen.dart';
import 'review_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MindMapProvider>().loadMindMaps();
        context.read<ReviewProvider>().loadDueFlashcards();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      context.read<MindMapProvider>().clearSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm...',
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (value) {
                  context.read<MindMapProvider>().search(value);
                },
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🪷', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  const Text('Dhamma Mind'),
                ],
              ),
        actions: [
          if (_isSearching)
            IconButton(icon: const Icon(Icons.close), onPressed: _stopSearch)
          else ...[
            IconButton(icon: const Icon(Icons.search), onPressed: _startSearch),
            IconButton(
              icon: Icon(
                widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              ),
              onPressed: widget.onToggleTheme,
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'templates',
                  child: ListTile(
                    leading: Icon(Icons.auto_awesome),
                    title: Text('Mẫu Phật học'),
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'backup',
                  child: ListTile(
                    leading: Icon(Icons.backup),
                    title: Text('Sao lưu'),
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'about',
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Giới thiệu'),
                    dense: true,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: Consumer<MindMapProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadMindMaps();
              await context.read<ReviewProvider>().loadDueFlashcards();
            },
            child: CustomScrollView(
              slivers: [
                // Review banner
                Consumer<ReviewProvider>(
                  builder: (context, reviewProvider, _) {
                    final dueCount = reviewProvider.totalCount;
                    if (dueCount == 0) return const SliverToBoxAdapter();

                    return SliverToBoxAdapter(
                      child: _buildReviewBanner(dueCount),
                    );
                  },
                ),

                // Empty state
                if (provider.mindmaps.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState())
                else ...[
                  // Section header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            'Sơ đồ của bạn',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          Text(
                            '${provider.mindmaps.length} sơ đồ',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Mindmap list
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final mindmap = provider.mindmaps[index];
                      return MindMapCard(
                        mindmap: mindmap,
                        onTap: () => _openMindMap(mindmap.id),
                        onEdit: () => _editMindMap(mindmap.id),
                        onDelete: () => _deleteMindMap(mindmap.id),
                        onReview: mindmap.dueFlashcardCount > 0
                            ? () => _reviewMindMap(mindmap.id)
                            : null,
                      );
                    }, childCount: provider.mindmaps.length),
                  ),

                  // Bottom padding
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewMindMap,
        icon: const Icon(Icons.add),
        label: const Text('Tạo mới'),
      ),
    );
  }

  Widget _buildReviewBanner(int dueCount) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.style, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ôn tập hôm nay',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '$dueCount thẻ cần ôn tập',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _startReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
            ),
            child: const Text('Bắt đầu'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_tree_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa có sơ đồ nào',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tạo sơ đồ đầu tiên của bạn\nđể bắt đầu học tập',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _createNewMindMap,
              icon: const Icon(Icons.add),
              label: const Text('Tạo sơ đồ mới'),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _showTemplates,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Dùng mẫu Phật học'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'templates':
        _showTemplates();
        break;
      case 'backup':
        _showBackupDialog();
        break;
      case 'about':
        _showAboutDialog();
        break;
    }
  }

  void _createNewMindMap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditorScreen()),
    );
  }

  void _openMindMap(String id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MindMapScreen(mindmapId: id)),
    );
  }

  void _editMindMap(String id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditorScreen(mindmapId: id)),
    );
  }

  Future<void> _deleteMindMap(String id) async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      title: 'Xóa sơ đồ?',
      message: 'Hành động này không thể hoàn tác.',
      confirmText: 'Xóa',
      isDestructive: true,
    );

    if (confirmed) {
      await context.read<MindMapProvider>().deleteMindMap(id);
      if (mounted) {
        Helpers.showSnackBar(context, 'Đã xóa sơ đồ');
      }
    }
  }

  void _reviewMindMap(String id) {
    // TODO: Review specific mindmap
    _startReview();
  }

  void _startReview() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReviewScreen()),
    );
  }

  void _showTemplates() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Mẫu Phật học',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: BuddhistTemplates.templateNames.length,
                itemBuilder: (context, index) {
                  final name = BuddhistTemplates.templateNames[index];
                  final items = BuddhistTemplates.getTemplate(name)!;

                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.getNodeColor(index).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.account_tree,
                        color: AppColors.getNodeColor(index),
                        size: 20,
                      ),
                    ),
                    title: Text(name),
                    subtitle: Text('${items.length} mục'),
                    trailing: const Icon(Icons.add_circle_outline),
                    onTap: () async {
                      Navigator.pop(context);
                      final mindmap = await context
                          .read<MindMapProvider>()
                          .createMindMapFromTemplate(name, items);
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MindMapScreen(mindmapId: mindmap.id),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBackupDialog() {
    // TODO: Implement backup/restore
    Helpers.showSnackBar(context, 'Tính năng đang phát triển');
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: const Text('🪷', style: TextStyle(fontSize: 48)),
      children: [
        const Text(AppConstants.appDescription),
        const SizedBox(height: 16),
        const Text(
          'Ứng dụng mã nguồn mở, phi lợi nhuận.\n'
          'Dành cho việc học tập và tu tập Phật pháp.',
          style: TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}
