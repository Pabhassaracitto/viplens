import 'package:flutter/foundation.dart';

import '../models/mindmap_model.dart';
import '../models/node_model.dart';
import '../models/review_data.dart';
import '../services/database_service.dart';
import '../services/spaced_repetition_service.dart';

class ReviewProvider extends ChangeNotifier {
  List<MapEntry<MindMapModel, NodeModel>> _dueFlashcards = [];
  int _currentIndex = 0;
  bool _isShowingAnswer = false;
  bool _isLoading = false;
  int _reviewedCount = 0;
  bool _disposed = false;

  // Getters
  List<MapEntry<MindMapModel, NodeModel>> get dueFlashcards => _dueFlashcards;
  int get currentIndex => _currentIndex;
  bool get isShowingAnswer => _isShowingAnswer;
  bool get isLoading => _isLoading;
  int get reviewedCount => _reviewedCount;

  int get totalCount => _dueFlashcards.length;
  int get remainingCount => totalCount - _currentIndex;

  bool get hasCards => _dueFlashcards.isNotEmpty;
  bool get isComplete => _currentIndex >= totalCount;

  MapEntry<MindMapModel, NodeModel>? get currentCard {
    if (_currentIndex >= _dueFlashcards.length) return null;
    return _dueFlashcards[_currentIndex];
  }

  NodeModel? get currentNode => currentCard?.value;
  MindMapModel? get currentMindMap => currentCard?.key;

  double get progress {
    if (totalCount == 0) return 0;
    return _currentIndex / totalCount;
  }

  /// Load tất cả flashcards cần ôn tập
  Future<void> loadDueFlashcards() async {
    _isLoading = true;
    if (!_disposed) notifyListeners();

    try {
      _dueFlashcards = DatabaseService.getAllDueFlashcards();
      _currentIndex = 0;
      _reviewedCount = 0;
      _isShowingAnswer = false;
    } catch (e) {
      debugPrint('Error loading flashcards: $e');
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Hiện/ẩn đáp án
  void toggleAnswer() {
    _isShowingAnswer = !_isShowingAnswer;
    notifyListeners();
  }

  /// Hiện đáp án
  void showAnswer() {
    _isShowingAnswer = true;
    notifyListeners();
  }

  /// Ẩn đáp án
  void hideAnswer() {
    _isShowingAnswer = false;
    notifyListeners();
  }

  /// Trả lời và chuyển sang card tiếp theo
  Future<void> answerCard(ReviewQuality quality) async {
    if (currentCard == null) return;

    final mindmap = currentCard!.key;
    final node = currentCard!.value;

    // Cập nhật node với kết quả ôn tập
    final updatedMindMap = SpacedRepetitionService.updateMindMapAfterReview(
      mindmap,
      node.id,
      quality,
    );

    // Lưu vào database
    await DatabaseService.saveMindMap(updatedMindMap);

    // Chuyển sang card tiếp theo
    _reviewedCount++;
    _currentIndex++;
    _isShowingAnswer = false;

    if (!_disposed) notifyListeners();
  }

  /// Đánh giá nhanh: Quên
  Future<void> markForgot() async {
    await answerCard(ReviewQuality.forgot);
  }

  /// Đánh giá nhanh: Khó
  Future<void> markHard() async {
    await answerCard(ReviewQuality.difficult);
  }

  /// Đánh giá nhanh: Tốt
  Future<void> markGood() async {
    await answerCard(ReviewQuality.good);
  }

  /// Đánh giá nhanh: Dễ
  Future<void> markEasy() async {
    await answerCard(ReviewQuality.easy);
  }

  /// Bỏ qua card hiện tại (không tính điểm)
  void skipCard() {
    if (_currentIndex < _dueFlashcards.length) {
      // Di chuyển card hiện tại về cuối
      final skippedCard = _dueFlashcards.removeAt(_currentIndex);
      _dueFlashcards.add(skippedCard);
      _isShowingAnswer = false;
      notifyListeners();
    }
  }

  /// Reset phiên ôn tập
  void reset() {
    _currentIndex = 0;
    _reviewedCount = 0;
    _isShowingAnswer = false;
    notifyListeners();
  }

  /// Lấy hint cho node (node cha)
  String? getHint() {
    if (currentNode == null || currentMindMap == null) return null;

    final parentId = currentNode!.parentId;
    if (parentId == null) return null;

    final parent = currentMindMap!.getNodeById(parentId);
    return parent?.content;
  }

  /// Lấy thống kê tổng
  ReviewStats getTotalStats() {
    final mindmaps = DatabaseService.getAllMindMaps();
    return SpacedRepetitionService.calculateTotalStats(mindmaps);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
