import 'package:flutter/material.dart';
import '../utils/colors.dart';

class NoteEditorWidget extends StatefulWidget {
  final String? initialNote;
  final String? initialPali;
  final Function(String note, String? pali) onSave;

  const NoteEditorWidget({
    super.key,
    this.initialNote,
    this.initialPali,
    required this.onSave,
  });

  @override
  State<NoteEditorWidget> createState() => _NoteEditorWidgetState();
}

class _NoteEditorWidgetState extends State<NoteEditorWidget>
    with SingleTickerProviderStateMixin {
  late TextEditingController _noteController;
  late TextEditingController _paliController;
  late TabController _tabController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote);
    _paliController = TextEditingController(text: widget.initialPali);
    _tabController = TabController(length: 2, vsync: this);

    _noteController.addListener(_onChanged);
    _paliController.addListener(_onChanged);
  }

  void _onChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _paliController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _save() {
    widget.onSave(
      _noteController.text.trim(),
      _paliController.text.trim().isEmpty ? null : _paliController.text.trim(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi chú'),
        actions: [
          TextButton.icon(
            onPressed: _hasChanges ? _save : null,
            icon: const Icon(Icons.check),
            label: const Text('Lưu'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ghi chú'),
            Tab(text: 'Pali'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Note tab
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _noteController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: 'Nhập ghi chú...',
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Pali tab
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Nhập văn bản Pali tương ứng',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TextField(
                    controller: _paliController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Nhập văn bản Pali...',
                      hintStyle: const TextStyle(fontStyle: FontStyle.italic),
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
