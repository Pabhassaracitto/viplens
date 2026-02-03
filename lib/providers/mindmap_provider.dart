import 'package:flutter/material.dart'; // Cần import này cho WidgetsBinding
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

  // === FIX: Hàm notify an toàn ===
  void _safeNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Load tất cả mindmaps từ database
  Future<void> loadMindMaps() async {
    _isLoading = true;
    notifyListeners();

    try {
      _mindmaps = DatabaseService.getAllMindMaps();
    } catch (e) {
      debugPrint('Error loading mindmaps: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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

  /// Chọn node (Đã áp dụng FIX)
  void selectNode(String? nodeId) {
    if (_selectedNodeId != nodeId) {
      _selectedNodeId = nodeId;
      _safeNotify(); // Dùng hàm notify an toàn
    }
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
    notifyListeners();
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
    notifyListeners();
  }

  /// Cập nhật ghi chú node
  Future<void> updateNodeNote(String nodeId, String note, String? pali) async {
    if (_currentMindMap == null) return;

    final nodeIndex = _currentMindMap!.nodes.indexWhere((n) => n.id == nodeId);
    if (nodeIndex < 0) return;

    final updatedNode = _currentMindMap!.nodes[nodeIndex].copyWith(
      note: note.isEmpty ? null : note,
      paliText: pali,
      updatedAt: DateTime.now(),
    );

    final updatedNodes = List<NodeModel>.from(_currentMindMap!.nodes);
    updatedNodes[nodeIndex] = updatedNode;

    _currentMindMap = _currentMindMap!.copyWith(
      nodes: updatedNodes,
      updatedAt: DateTime.now(),
    );

    await DatabaseService.saveMindMap(_currentMindMap!);
    notifyListeners();
  }

  /// Cập nhật hình ảnh node
  Future<void> updateNodeImage(String nodeId, String? imagePath) async {
    if (_currentMindMap == null) return;

    final nodeIndex = _currentMindMap!.nodes.indexWhere((n) => n.id == nodeId);
    if (nodeIndex < 0) return;

    final updatedNode = _currentMindMap!.nodes[nodeIndex].copyWith(
      imagePath: imagePath,
      updatedAt: DateTime.now(),
    );

    final updatedNodes = List<NodeModel>.from(_currentMindMap!.nodes);
    updatedNodes[nodeIndex] = updatedNode;

    _currentMindMap = _currentMindMap!.copyWith(
      nodes: updatedNodes,
      updatedAt: DateTime.now(),
    );

    await DatabaseService.saveMindMap(_currentMindMap!);
    notifyListeners();
  }

  /// Cập nhật audio node
  Future<void> updateNodeAudio(
    String nodeId,
    String? audioPath,
    int? durationMs,
  ) async {
    if (_currentMindMap == null) return;

    final nodeIndex = _currentMindMap!.nodes.indexWhere((n) => n.id == nodeId);
    if (nodeIndex < 0) return;

    final updatedNode = _currentMindMap!.nodes[nodeIndex].copyWith(
      audioPath: audioPath,
      audioDuration: durationMs,
      updatedAt: DateTime.now(),
    );

    final updatedNodes = List<NodeModel>.from(_currentMindMap!.nodes);
    updatedNodes[nodeIndex] = updatedNode;

    _currentMindMap = _currentMindMap!.copyWith(
      nodes: updatedNodes,
      updatedAt: DateTime.now(),
    );

    await DatabaseService.saveMindMap(_currentMindMap!);
    notifyListeners();
  }

  /// Cập nhật link node
  Future<void> updateNodeLink(String nodeId, String? link) async {
    if (_currentMindMap == null) return;

    final nodeIndex = _currentMindMap!.nodes.indexWhere((n) => n.id == nodeId);
    if (nodeIndex < 0) return;

    final updatedNode = _currentMindMap!.nodes[nodeIndex].copyWith(
      link: link,
      updatedAt: DateTime.now(),
    );

    final updatedNodes = List<NodeModel>.from(_currentMindMap!.nodes);
    updatedNodes[nodeIndex] = updatedNode;

    _currentMindMap = _currentMindMap!.copyWith(
      nodes: updatedNodes,
      updatedAt: DateTime.now(),
    );

    await DatabaseService.saveMindMap(_currentMindMap!);
    notifyListeners();
  }

  /// Xóa node
  Future<void> deleteNode(String nodeId) async {
    if (_currentMindMap == null) return;
    if (nodeId == _currentMindMap!.rootNodeId) return;

    _currentMindMap = TextParserService.deleteNode(_currentMindMap!, nodeId);

    if (_selectedNodeId == nodeId) {
      _selectedNodeId = _currentMindMap!.rootNodeId;
    }

    await DatabaseService.saveMindMap(_currentMindMap!);
    await loadMindMaps();
    notifyListeners();
  }

  /// Toggle flashcard
  Future<void> toggleFlashcard(String nodeId) async {
    if (_currentMindMap == null) return;

    _currentMindMap = TextParserService.toggleFlashcard(
      _currentMindMap!,
      nodeId,
    );
    await DatabaseService.saveMindMap(_currentMindMap!);
    notifyListeners();
  }

  /// Cập nhật title mindmap
  Future<void> updateMindMapTitle(String newTitle) async {
    if (_currentMindMap == null) return;

    _currentMindMap = _currentMindMap!.copyWith(
      title: newTitle,
      updatedAt: DateTime.now(),
    );

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
    notifyListeners();
  }

  /// Xóa mindmap
  Future<void> deleteMindMap(String id) async {
    await DatabaseService.deleteMindMap(id);

    if (_currentMindMap?.id == id) {
      _currentMindMap = null;
      _selectedNodeId = null;
    }

    await loadMindMaps();
    notifyListeners();
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
}
