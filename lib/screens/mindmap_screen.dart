import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/node_model.dart';
import '../providers/mindmap_provider.dart';
import '../utils/colors.dart';
import '../utils/helpers.dart';
import '../widgets/mindmap_canvas.dart';
import '../widgets/node_widget.dart';
import 'editor_screen.dart';
import 'review_screen.dart';

class MindMapScreen extends StatefulWidget {
  final String mindmapId;

  const MindMapScreen({super.key, required this.mindmapId});

  @override
  State<MindMapScreen> createState() => _MindMapScreenState();
}

class _MindMapScreenState extends State<MindMapScreen> {
  bool _isZenMode = false;
  bool _showList = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MindMapProvider>().loadMindMap(widget.mindmapId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MindMapProvider>(
      builder: (context, provider, child) {
        final mindmap = provider.currentMindMap;

        if (mindmap == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: _isZenMode ? AppColors.zenBackground : null,
          appBar: _isZenMode
              ? null
              : AppBar(
                  title: Text(mindmap.title),
                  actions: [
                    // Toggle view
                    IconButton(
                      icon: Icon(_showList ? Icons.account_tree : Icons.list),
                      onPressed: () {
                        setState(() {
                          _showList = !_showList;
                        });
                      },
                      tooltip: _showList ? 'Xem sơ đồ' : 'Xem danh sách',
                    ),
                    // Zen mode
                    IconButton(
                      icon: const Icon(Icons.self_improvement),
                      onPressed: () {
                        setState(() {
                          _isZenMode = true;
                        });
                      },
                      tooltip: 'Chế độ thiền định',
                    ),
                    // More options
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleMenuAction(value, provider),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Chỉnh sửa'),
                            dense: true,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'review',
                          child: ListTile(
                            leading: Icon(Icons.style),
                            title: Text('Ôn tập'),
                            dense: true,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'export',
                          child: ListTile(
                            leading: Icon(Icons.share),
                            title: Text('Chia sẻ'),
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          body: Stack(
            children: [
              // Main content
              _showList
                  ? _buildListView(mindmap, provider)
                  : MindMapCanvas(
                      mindmap: mindmap,
                      selectedNodeId: provider.selectedNodeId,
                      isZenMode: _isZenMode,
                      onNodeTap: (nodeId) {
                        provider.selectNode(nodeId);
                      },
                      onNodeDoubleTap: (nodeId) {
                        _editNode(nodeId, provider);
                      },
                      onNodeLongPress: (nodeId) {
                        _showNodeOptions(nodeId, provider);
                      },
                    ),

              // Zen mode exit button
              if (_isZenMode)
                Positioned(
                  bottom: 32,
                  right: 32,
                  child: FloatingActionButton.small(
                    onPressed: () {
                      setState(() {
                        _isZenMode = false;
                      });
                    },
                    backgroundColor: AppColors.zenAccent,
                    child: const Icon(Icons.close),
                  ),
                ),
            ],
          ),

          // Bottom action bar (when node selected)
          bottomNavigationBar: provider.selectedNode != null && !_isZenMode
              ? _buildBottomBar(provider)
              : null,

          // FAB for adding nodes
          floatingActionButton: !_isZenMode && !_showList
              ? FloatingActionButton(
                  onPressed: () => _addChildNode(provider),
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  Widget _buildListView(mindmap, MindMapProvider provider) {
    // Flatten nodes for list view
    List<NodeModel> flatNodes = [];

    void addNode(String nodeId) {
      final node = mindmap.getNodeById(nodeId);
      if (node == null) return;
      flatNodes.add(node);
      for (final childId in node.childIds) {
        addNode(childId);
      }
    }

    addNode(mindmap.rootNodeId);

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: flatNodes.length,
      itemBuilder: (context, index) {
        final node = flatNodes[index];
        return NodeListTile(
          node: node,
          isSelected: node.id == provider.selectedNodeId,
          onTap: () => provider.selectNode(node.id),
          onEdit: () => _editNode(node.id, provider),
        );
      },
    );
  }

  Widget _buildBottomBar(MindMapProvider provider) {
    final node = provider.selectedNode!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.edit,
              label: 'Sửa',
              onTap: () => _editNode(node.id, provider),
            ),
            _buildActionButton(
              icon: Icons.add,
              label: 'Thêm con',
              onTap: () => _addChildNode(provider),
            ),
            _buildActionButton(
              icon: node.isFlashcard ? Icons.style : Icons.style_outlined,
              label: node.isFlashcard ? 'Bỏ thẻ' : 'Tạo thẻ',
              color: node.isFlashcard ? AppColors.accent : null,
              onTap: () => provider.toggleFlashcard(node.id),
            ),
            if (node.id != provider.currentMindMap?.rootNodeId)
              _buildActionButton(
                icon: Icons.delete_outline,
                label: 'Xóa',
                color: AppColors.error,
                onTap: () => _deleteNode(node.id, provider),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action, MindMapProvider provider) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditorScreen(mindmapId: widget.mindmapId),
          ),
        );
        break;
      case 'review':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ReviewScreen()),
        );
        break;
      case 'export':
        _exportMindmap(provider);
        break;
    }
  }

  Future<void> _addChildNode(MindMapProvider provider) async {
    final parentId =
        provider.selectedNodeId ?? provider.currentMindMap?.rootNodeId;

    if (parentId == null) return;

    final result = await Helpers.showInputDialog(
      context,
      title: 'Thêm nội dung mới',
      hintText: 'Nhập nội dung...',
    );

    if (result != null && result.isNotEmpty) {
      await provider.addChildNode(parentId, result);
    }
  }

  Future<void> _editNode(String nodeId, MindMapProvider provider) async {
    final node = provider.currentMindMap?.getNodeById(nodeId);
    if (node == null) return;

    final result = await Helpers.showInputDialog(
      context,
      title: 'Chỉnh sửa',
      initialValue: node.content,
      hintText: 'Nhập nội dung...',
    );

    if (result != null && result.isNotEmpty) {
      await provider.updateNodeContent(nodeId, result);
    }
  }

  Future<void> _deleteNode(String nodeId, MindMapProvider provider) async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      title: 'Xóa nội dung?',
      message: 'Các nội dung con cũng sẽ bị xóa.',
      confirmText: 'Xóa',
      isDestructive: true,
    );

    if (confirmed) {
      await provider.deleteNode(nodeId);
    }
  }

  void _showNodeOptions(String nodeId, MindMapProvider provider) {
    final node = provider.currentMindMap?.getNodeById(nodeId);
    if (node == null) return;

    provider.selectNode(nodeId);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Chỉnh sửa'),
              onTap: () {
                Navigator.pop(context);
                _editNode(nodeId, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Thêm nội dung con'),
              onTap: () {
                Navigator.pop(context);
                _addChildNode(provider);
              },
            ),
            ListTile(
              leading: Icon(
                node.isFlashcard ? Icons.style : Icons.style_outlined,
                color: node.isFlashcard ? AppColors.accent : null,
              ),
              title: Text(node.isFlashcard ? 'Bỏ flashcard' : 'Tạo flashcard'),
              onTap: () {
                Navigator.pop(context);
                provider.toggleFlashcard(nodeId);
              },
            ),
            if (nodeId != provider.currentMindMap?.rootNodeId)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Xóa',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteNode(nodeId, provider);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _exportMindmap(MindMapProvider provider) {
    // TODO: Implement export
    Helpers.showSnackBar(context, 'Tính năng đang phát triển');
  }
}
