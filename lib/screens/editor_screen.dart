import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/mindmap_model.dart';
import '../providers/mindmap_provider.dart';
import '../utils/colors.dart';
import '../utils/helpers.dart';
import 'mindmap_screen.dart';

class EditorScreen extends StatefulWidget {
  final String? mindmapId;

  const EditorScreen({super.key, this.mindmapId});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();

  bool _isEditing = false;
  MindMapModel? _existingMindmap;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.mindmapId != null;

    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadExistingMindmap();
        }
      });
    }
  }

  void _loadExistingMindmap() {
    final provider = context.read<MindMapProvider>();
    provider.loadMindMap(widget.mindmapId!);
    _existingMindmap = provider.currentMindMap;

    if (_existingMindmap != null) {
      _titleController.text = _existingMindmap!.title;
      _contentController.text = _mindmapToText(_existingMindmap!);
    }
  }

  String _mindmapToText(MindMapModel mindmap) {
    final buffer = StringBuffer();

    void writeNode(String nodeId, int level) {
      final node = mindmap.getNodeById(nodeId);
      if (node == null) return;

      // Skip root node as it's the title
      if (level > 0) {
        final indent = '  ' * (level - 1);
        String line = '$indent- ${node.content}';
        if (node.paliText != null && node.paliText!.isNotEmpty) {
          line += ' (${node.paliText})';
        }
        buffer.writeln(line);
      }

      for (final childId in node.childIds) {
        writeNode(childId, level + 1);
      }
    }

    writeNode(mindmap.rootNodeId, 0);
    return buffer.toString();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Chỉnh sửa' : 'Tạo mới'),
        actions: [
          TextButton.icon(
            onPressed: _canSave() ? _save : null,
            icon: const Icon(Icons.check),
            label: const Text('Lưu'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title input
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Tiêu đề',
                hintText: 'Nhập tiêu đề sơ đồ...',
                prefixIcon: const Icon(Icons.title),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                _contentFocusNode.requestFocus();
              },
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 16),

            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: AppColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Dùng dấu - hoặc Tab để tạo cấp độ.\n'
                      'Văn bản Pali đặt trong ngoặc đơn (Pali).',
                      style: TextStyle(fontSize: 13, color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Content input
            TextField(
              controller: _contentController,
              focusNode: _contentFocusNode,
              decoration: InputDecoration(
                labelText: 'Nội dung',
                hintText:
                    'Nhập nội dung...\n\n'
                    'Ví dụ:\n'
                    '- Khổ đế (Dukkha)\n'
                    '  - Sinh là khổ\n'
                    '  - Già là khổ\n'
                    '- Tập đế (Samudaya)\n'
                    '  - Tham ái',
                alignLabelWithHint: true,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 15,
              keyboardType: TextInputType.multiline,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 24),

            // Preview hint
            if (_contentController.text.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.preview, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Xem trước cấu trúc',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildPreview(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final lines = _contentController.text.split('\n');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Root node
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.getNodeColor(0).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _titleController.text.isEmpty ? 'Tiêu đề' : _titleController.text,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          // Child nodes preview
          ...lines.take(10).map((line) {
            if (line.trim().isEmpty) return const SizedBox.shrink();

            // Count indent level
            int level = 0;
            String content = line;

            while (content.startsWith('  ') || content.startsWith('\t')) {
              level++;
              if (content.startsWith('  ')) {
                content = content.substring(2);
              } else {
                content = content.substring(1);
              }
            }

            content = content.replaceFirst(RegExp(r'^[-+*•]\s*'), '');

            if (content.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: EdgeInsets.only(left: (level + 1) * 16.0, top: 4),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.getNodeColor(level + 1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      content,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),

          if (lines.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '... và ${lines.length - 10} dòng nữa',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _canSave() {
    return _titleController.text.trim().isNotEmpty;
  }

  Future<void> _save() async {
    if (!_canSave()) return;

    final provider = context.read<MindMapProvider>();
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    try {
      MindMapModel mindmap;

      if (_isEditing && _existingMindmap != null) {
        // Update existing
        await provider.updateMindMapTitle(title);
        // TODO: Handle content update more gracefully
        mindmap = provider.currentMindMap!;
      } else {
        // Create new
        mindmap = await provider.createMindMapFromText(content, title);
      }

      if (mounted) {
        // Navigate to mindmap view
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MindMapScreen(mindmapId: mindmap.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Có lỗi xảy ra: $e', isError: true);
      }
    }
  }
}
