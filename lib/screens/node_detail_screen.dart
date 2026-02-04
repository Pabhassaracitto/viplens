import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/node_model.dart';
import '../models/mindmap_model.dart';
import '../providers/mindmap_provider.dart';
import '../services/media_service.dart';
import '../services/audio_service.dart';
import '../widgets/image_viewer_widget.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/audio_recorder_widget.dart';
import '../widgets/note_editor_widget.dart';
import '../utils/colors.dart';
import '../utils/helpers.dart';

class NodeDetailScreen extends StatefulWidget {
  final String mindmapId;
  final String nodeId;

  const NodeDetailScreen({
    super.key,
    required this.mindmapId,
    required this.nodeId,
  });

  @override
  State<NodeDetailScreen> createState() => _NodeDetailScreenState();
}

class _NodeDetailScreenState extends State<NodeDetailScreen> {
  late TextEditingController _contentController;
  late TextEditingController _paliController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<MindMapProvider>();
    provider.loadMindMap(widget.mindmapId);
    final node = provider.currentMindMap?.getNodeById(widget.nodeId);

    _contentController = TextEditingController(text: node?.content ?? '');
    _paliController = TextEditingController(text: node?.paliText ?? '');
  }

  @override
  void dispose() {
    _contentController.dispose();
    _paliController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final provider = context.read<MindMapProvider>();
    await provider.updateNodeContent(
      widget.nodeId,
      _contentController.text.trim(),
      paliText: _paliController.text.trim().isEmpty
          ? null
          : _paliController.text.trim(),
    );
    setState(() {
      _hasChanges = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MindMapProvider>(
      builder: (context, provider, child) {
        final mindmap = provider.currentMindMap;
        final node = mindmap?.getNodeById(widget.nodeId);

        if (mindmap == null || node == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Không tìm thấy node')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chi tiết'),
            actions: [
              if (_hasChanges)
                TextButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: const Text('Lưu'),
                ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, provider, node),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'flashcard',
                    child: ListTile(
                      leading: Icon(
                        node.isFlashcard ? Icons.style : Icons.style_outlined,
                        color: node.isFlashcard ? AppColors.accent : null,
                      ),
                      title: Text(
                          node.isFlashcard ? 'Bỏ flashcard' : 'Tạo flashcard'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: AppColors.error),
                      title:
                          Text('Xóa', style: TextStyle(color: AppColors.error)),
                      dense: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Content
                _buildSection(
                  title: 'Nội dung',
                  child: TextField(
                    controller: _contentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Nhập nội dung...',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) {
                      if (!_hasChanges) {
                        setState(() => _hasChanges = true);
                      }
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Pali
                _buildSection(
                  title: 'Pali',
                  child: TextField(
                    controller: _paliController,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                    decoration: InputDecoration(
                      hintText: 'Nhập văn bản Pali...',
                      hintStyle: const TextStyle(fontStyle: FontStyle.italic),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) {
                      if (!_hasChanges) {
                        setState(() => _hasChanges = true);
                      }
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Note
                _buildSection(
                  title: 'Ghi chú',
                  action: TextButton.icon(
                    onPressed: () => _editNote(provider, node),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Sửa'),
                  ),
                  child: node.hasNote
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            node.note!,
                            style: const TextStyle(height: 1.5),
                          ),
                        )
                      : _buildEmptyPlaceholder(
                          icon: Icons.note_alt_outlined,
                          label: 'Chưa có ghi chú',
                          onTap: () => _editNote(provider, node),
                        ),
                ),

                const SizedBox(height: 24),

                // Image
                _buildSection(
                  title: 'Hình ảnh',
                  action: TextButton.icon(
                    onPressed: () => _showImageOptions(provider, node),
                    icon: const Icon(Icons.add_photo_alternate, size: 16),
                    label: const Text('Thêm'),
                  ),
                  child: node.hasImage
                      ? ImageThumbnailWidget(
                          imagePath: node.imagePath,
                          imageUrl: node.imageUrl,
                          size: 120,
                          borderRadius: 12,
                          onDelete: () => _deleteImage(provider, node),
                        )
                      : _buildEmptyPlaceholder(
                          icon: Icons.image_outlined,
                          label: 'Chưa có hình ảnh',
                          onTap: () => _showImageOptions(provider, node),
                        ),
                ),

                const SizedBox(height: 24),

                // Audio
                _buildSection(
                  title: 'Ghi âm',
                  action: TextButton.icon(
                    onPressed: () => _showRecorder(provider, node),
                    icon: const Icon(Icons.mic, size: 16),
                    label: const Text('Ghi'),
                  ),
                  child: node.hasAudio
                      ? AudioPlayerWidget(
                          audioPath: node.audioPath!,
                          durationMs: node.audioDuration,
                          onDelete: () => _deleteAudio(provider, node),
                        )
                      : _buildEmptyPlaceholder(
                          icon: Icons.mic_none,
                          label: 'Chưa có ghi âm',
                          onTap: () => _showRecorder(provider, node),
                        ),
                ),

                const SizedBox(height: 24),

                // Info
                _buildSection(
                  title: 'Thông tin',
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.account_tree,
                          label: 'Cấp độ',
                          value: 'Level ${node.level}',
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          icon: Icons.style,
                          label: 'Flashcard',
                          value: node.isFlashcard ? 'Có' : 'Không',
                        ),
                        if (node.isFlashcard) ...[
                          const Divider(height: 24),
                          _buildInfoRow(
                            icon: Icons.repeat,
                            label: 'Lần ôn tập',
                            value: '${node.repetitionCount}',
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            icon: Icons.schedule,
                            label: 'Ôn tập tiếp',
                            value: node.nextReviewDate != null
                                ? Helpers.formatDate(node.nextReviewDate!)
                                : 'Chưa xác định',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    Widget? action,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            if (action != null) action,
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildEmptyPlaceholder({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(label),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  void _handleMenuAction(
      String action, MindMapProvider provider, NodeModel node) {
    switch (action) {
      case 'flashcard':
        provider.toggleFlashcard(node.id);
        break;
      case 'delete':
        _deleteNode(provider, node);
        break;
    }
  }

  Future<void> _editNote(MindMapProvider provider, NodeModel node) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorWidget(
          initialNote: node.note,
          initialPali: node.paliText,
          onSave: (note, pali) async {
            await provider.updateNodeNote(node.id, note, pali);
          },
        ),
      ),
    );
  }

  void _showImageOptions(MindMapProvider provider, NodeModel node) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () async {
                Navigator.pop(context);
                final path = await MediaService.pickImageFromGallery();
                if (path != null) {
                  await provider.updateNodeImage(node.id, path);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () async {
                Navigator.pop(context);
                final path = await MediaService.pickImageFromCamera();
                if (path != null) {
                  await provider.updateNodeImage(node.id, path);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteImage(MindMapProvider provider, NodeModel node) async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      title: 'Xóa hình ảnh?',
      message: 'Hành động này không thể hoàn tác.',
      confirmText: 'Xóa',
      isDestructive: true,
    );

    if (confirmed && node.imagePath != null) {
      await MediaService.deleteImage(node.imagePath!);
      await provider.updateNodeImage(node.id, null);
    }
  }

  void _showRecorder(MindMapProvider provider, NodeModel node) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AudioRecorderWidget(
        onRecordingComplete: (path, durationMs) async {
          await provider.updateNodeAudio(node.id, path, durationMs);
          if (mounted) Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _deleteAudio(MindMapProvider provider, NodeModel node) async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      title: 'Xóa ghi âm?',
      message: 'Hành động này không thể hoàn tác.',
      confirmText: 'Xóa',
      isDestructive: true,
    );

    if (confirmed && node.audioPath != null) {
      await MediaService.deleteAudio(node.audioPath!);
      await provider.updateNodeAudio(node.id, null, null);
    }
  }

  Future<void> _deleteNode(MindMapProvider provider, NodeModel node) async {
    if (node.id == provider.currentMindMap?.rootNodeId) {
      Helpers.showSnackBar(context, 'Không thể xóa node gốc', isError: true);
      return;
    }

    final confirmed = await Helpers.showConfirmDialog(
      context,
      title: 'Xóa nội dung?',
      message: 'Các nội dung con cũng sẽ bị xóa.',
      confirmText: 'Xóa',
      isDestructive: true,
    );

    if (confirmed) {
      await provider.deleteNode(node.id);
      if (mounted) Navigator.pop(context);
    }
  }
}
