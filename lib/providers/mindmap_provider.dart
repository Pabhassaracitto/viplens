import 'package:flutter/foundation.dart';

import '../models/mindmap_model.dart';
import '../models/node_model.dart';
import '../services/database_service.dart';
import '../services/text_parser_service.dart';

class MindMapProvider extends ChangeNotifier {
  List<MindMapModel> _mindmaps = [];
  MindMapModel? _currentMindMap;
  String? _selectedNodeId;
  bool _isLoading = false;
  String _searchQuery = '';
  bool _disposed = false;

  // Getters
  List<MindMapModel> get mindmaps => _searchQuery.isEmpty
      ? _mindmaps
      : DatabaseService.searchMindMaps(_searchQuery);

  MindMapModel? get currentMindMap => _currentMindMap;
  String? get selectedNodeId => _selectedNodeId;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  NodeModel? get selectedNode {
    if (_currentMindMap == null || _selectedNodeId == null) return null;
    return _currentMindMap!.getNodeById(_selectedNodeId!);
  }

  int get totalDueFlashcards => DatabaseService.getTotalDueFlashcardCount();

  /// Load tất cả mindmaps từ database
  Future<void> loadMindMaps() async {
    _isLoading = true;
    if (!_disposed) notifyListeners();

    try {
      _mindmaps = DatabaseService.getAllMindMaps();
    } catch (e) {
      debugPrint('Error loading mindmaps: $e');
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Tìm kiếm mindmaps
  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Xóa tìm kiếm
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  /// Tạo mindmap mới từ text
  Future<MindMapModel> createMindMapFromText(String text, String title) async {
    final mindmap = TextParserService.parseTextToMindMap(text, title);
    await DatabaseService.saveMindMap(mindmap);
    await loadMindMaps();
    return mindmap;
  }

  /// Tạo mindmap mới từ template
  Future<MindMapModel> createMindMapFromTemplate(
    String title,
    List<String> items,
  ) async {
    // Tạo text từ template
    final text = items.map((item) => '- $item').join('\n');
    return createMindMapFromText(text, title);
  }

  /// Load một mindmap cụ thể
  void loadMindMap(String id) {
    _currentMindMap = DatabaseService.getMindMapById(id);
    _selectedNodeId = _currentMindMap?.rootNodeId;
    notifyListeners();
  }

  /// Đóng mindmap hiện tại
  void closeMindMap() {
    _currentMindMap = null;
    _selectedNodeId = null;
    notifyListeners();
  }

  /// Chọn node
  void selectNode(String? nodeId) {
    _selectedNodeId = nodeId;
    notifyListeners();
  }

  /// Thêm node con
  Future<void> addChildNode(
    String parentId,
    String content, {
    String? paliText,
  }) async {
    if (_currentMindMap == null) return;

    _currentMindMap = TextParserService.addNode(
      _currentMindMap!,
      parentId,
      content,
      paliText: paliText,
    );

    await DatabaseService.saveMindMap(_currentMindMap!);
    if (!_disposed) notifyListeners();
  }

  /// Cập nhật nội dung node
  Future<void> updateNodeContent(
    String nodeId,
    String content, {
    String? paliText,
  }) async {
    if (_currentMindMap == null) return;

    _currentMindMap = TextParserService.updateNodeContent(
      _currentMindMap!,
      nodeId,
      content,
      newPaliText: paliText,
    );

    await DatabaseService.saveMindMap(_currentMindMap!);
    if (!_disposed) notifyListeners();
  }

  /// Xóa node
  Future<void> deleteNode(String nodeId) async {
    if (_currentMindMap == null) return;
    if (nodeId == _currentMindMap!.rootNodeId) return; // Không xóa root

    _currentMindMap = TextParserService.deleteNode(_currentMindMap!, nodeId);

    // Nếu đang chọn node bị xóa, chuyển về root
    if (_selectedNodeId == nodeId) {
      _selectedNodeId = _currentMindMap!.rootNodeId;
    }

    await DatabaseService.saveMindMap(_currentMindMap!);
    await loadMindMaps(); // Refresh list
    if (!_disposed) notifyListeners();
  }

  /// Toggle flashcard
  Future<void> toggleFlashcard(String nodeId) async {
    if (_currentMindMap == null) return;

    _currentMindMap = TextParserService.toggleFlashcard(
      _currentMindMap!,
      nodeId,
    );
    await DatabaseService.saveMindMap(_currentMindMap!);
    if (!_disposed) notifyListeners();
  }

  /// Cập nhật title mindmap
  Future<void> updateMindMapTitle(String newTitle) async {
    if (_currentMindMap == null) return;

    _currentMindMap = _currentMindMap!.copyWith(
      title: newTitle,
      updatedAt: DateTime.now(),
    );

    // Cập nhật cả root node
    final rootIndex = _currentMindMap!.nodes.indexWhere(
      (n) => n.id == _currentMindMap!.rootNodeId,
    );
    if (rootIndex >= 0) {
      final updatedNodes = List<NodeModel>.from(_currentMindMap!.nodes);
      updatedNodes[rootIndex] = updatedNodes[rootIndex].copyWith(
        content: newTitle,
      );
      _currentMindMap = _currentMindMap!.copyWith(nodes: updatedNodes);
    }

    await DatabaseService.saveMindMap(_currentMindMap!);
    await loadMindMaps();
    if (!_disposed) notifyListeners();
  }

  /// Xóa mindmap
  Future<void> deleteMindMap(String id) async {
    await DatabaseService.deleteMindMap(id);

    if (_currentMindMap?.id == id) {
      _currentMindMap = null;
      _selectedNodeId = null;
    }

    await loadMindMaps();
    if (!_disposed) notifyListeners();
  }

  /// Lưu mindmap hiện tại
  Future<void> saveCurrent() async {
    if (_currentMindMap == null) return;
    await DatabaseService.saveMindMap(_currentMindMap!);
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadMindMaps();
    if (_currentMindMap != null) {
      loadMindMap(_currentMindMap!.id);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
