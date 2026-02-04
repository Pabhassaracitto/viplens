import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:viplens/models/mindmap_model.dart';

import '../models/node_model.dart';
import '../providers/mindmap_provider.dart';
import '../utils/colors.dart';
import '../utils/helpers.dart';
import '../widgets/mindmap_canvas.dart';
import '../widgets/node_widget.dart';
import 'editor_screen.dart';
import 'node_detail_screen.dart';
import 'presentation_screen.dart';
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
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _loadData();
    }
  }

  void _loadData() {
    // Đảm bảo load sau frame hiện tại
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
                    IconButton(
                      icon: Icon(_showList ? Icons.account_tree : Icons.list),
                      onPressed: () {
                        setState(() {
                          _showList = !_showList;
                        });
                      },
                      tooltip: _showList ? 'Xem sơ đồ' : 'Xem danh sách',
                    ),
                    IconButton(
                      icon: const Icon(Icons.self_improvement),
                      onPressed: () {
                        setState(() {
                          _isZenMode = true;
                        });
                      },
                      tooltip: 'Chế độ thiền định',
                    ),
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
                        const PopupMenuItem(
                          value: 'present',
                          child: ListTile(
                            leading: Icon(Icons.slideshow),
                            title: Text('Trình chiếu'),
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          body: Stack(
            children: [
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NodeDetailScreen(
                              mindmapId: widget.mindmapId,
                              nodeId: nodeId,
                            ),
                          ),
                        );
                      },
                      onNodeLongPress: (nodeId) {
                        _showNodeOptions(nodeId, provider);
                      },
                    ),
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
          bottomNavigationBar: provider.selectedNode != null && !_isZenMode
              ? _buildBottomBar(provider)
              : null,
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

  Widget _buildListView(MindMapModel mindmap, MindMapProvider provider) {
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
            // THÊM NÚT GHI CHÚ
            _buildActionButton(
              icon: node.hasNote ? Icons.note : Icons.note_add_outlined,
              label: 'Ghi chú',
              color: node.hasNote ? AppColors.info : null,
              onTap: () => _editNodeNote(node, provider),
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

// THÊM HÀM MỚI
  Future<void> _editNodeNote(NodeModel node, MindMapProvider provider) async {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => _NoteDialog(
        initialNote: node.note,
        initialPali: node.paliText,
      ),
    );

    if (result != null) {
      await provider.updateNodeNote(
        node.id,
        result['note'] ?? '',
        result['pali'],
      );
    }
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
      case 'present':
        if (provider.currentMindMap != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PresentationScreen(mindmap: provider.currentMindMap!),
            ),
          );
        }
        break;
    }
  }

  Future<void> _addChildNode(MindMapProvider provider) async {
    final parentId =
        provider.selectedNodeId ?? provider.currentMindMap?.rootNodeId;

    if (parentId == null) return;

    // Tạm dừng frame render để tránh xung đột bàn phím
    final result = await Helpers.showInputDialog(
      context,
      title: 'Thêm nội dung mới',
      hintText: 'Nhập nội dung...',
    );

    // Kiểm tra mounted lần 1
    if (!mounted) return;

    if (result != null && result.isNotEmpty) {
      // Chờ bàn phím ẩn xong (quan trọng)
      await Future.delayed(const Duration(milliseconds: 300));

      // Kiểm tra mounted lần 2 trước khi gọi provider
      if (mounted) {
        await provider.addChildNode(parentId, result);
      }
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

    if (!mounted) return;

    if (result != null && result.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        await provider.updateNodeContent(nodeId, result);
      }
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

    if (confirmed && mounted) {
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
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Chỉnh sửa'),
              onTap: () {
                Navigator.pop(sheetContext);
                _editNode(nodeId, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Thêm nội dung con'),
              onTap: () {
                Navigator.pop(sheetContext);
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
                Navigator.pop(sheetContext);
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
                  Navigator.pop(sheetContext);
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
    Helpers.showSnackBar(context, 'Tính năng đang phát triển');
  }
}

class _NoteDialog extends StatefulWidget {
  final String? initialNote;
  final String? initialPali;

  const _NoteDialog({
    this.initialNote,
    this.initialPali,
  });

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late TextEditingController _noteController;
  late TextEditingController _paliController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote);
    _paliController = TextEditingController(text: widget.initialPali);
  }

  @override
  void dispose() {
    _noteController.dispose();
    _paliController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ghi chú'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _paliController,
              decoration: const InputDecoration(
                labelText: 'Văn bản Pali',
                hintText: 'Nhập văn bản Pali...',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                hintText: 'Nhập ghi chú...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'note': _noteController.text.trim(),
              'pali': _paliController.text.trim().isEmpty
                  ? null
                  : _paliController.text.trim(),
            });
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
