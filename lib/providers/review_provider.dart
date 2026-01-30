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
  bool _isDisposed = false;

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

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (_isDisposed) return;
    Future.microtask(() {
      if (!_isDisposed) {
        notifyListeners();
      }
    });
  }

  Future<void> loadDueFlashcards() async {
    _isLoading = true;
    _safeNotify();

    try {
      _dueFlashcards = DatabaseService.getAllDueFlashcards();
      _currentIndex = 0;
      _reviewedCount = 0;
      _isShowingAnswer = false;
    } catch (e) {
      debugPrint('Error loading flashcards: $e');
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  void toggleAnswer() {
    _isShowingAnswer = !_isShowingAnswer;
    _safeNotify();
  }

  void showAnswer() {
    _isShowingAnswer = true;
    _safeNotify();
  }

  void hideAnswer() {
    _isShowingAnswer = false;
    _safeNotify();
  }

  Future<void> answerCard(ReviewQuality quality) async {
    if (currentCard == null) return;

    final mindmap = currentCard!.key;
    final node = currentCard!.value;

    final updatedMindMap = SpacedRepetitionService.updateMindMapAfterReview(
      mindmap,
      node.id,
      quality,
    );

    await DatabaseService.saveMindMap(updatedMindMap);

    _reviewedCount++;
    _currentIndex++;
    _isShowingAnswer = false;

    _safeNotify();
  }

  Future<void> markForgot() async {
    await answerCard(ReviewQuality.forgot);
  }

  Future<void> markHard() async {
    await answerCard(ReviewQuality.difficult);
  }

  Future<void> markGood() async {
    await answerCard(ReviewQuality.good);
  }

  Future<void> markEasy() async {
    await answerCard(ReviewQuality.easy);
  }

  void skipCard() {
    if (_currentIndex < _dueFlashcards.length) {
      final skippedCard = _dueFlashcards.removeAt(_currentIndex);
      _dueFlashcards.add(skippedCard);
      _isShowingAnswer = false;
      _safeNotify();
    }
  }

  void reset() {
    _currentIndex = 0;
    _reviewedCount = 0;
    _isShowingAnswer = false;
    _safeNotify();
  }

  String? getHint() {
    if (currentNode == null || currentMindMap == null) return null;

    final parentId = currentNode!.parentId;
    if (parentId == null) return null;

    final parent = currentMindMap!.getNodeById(parentId);
    return parent?.content;
  }
}
