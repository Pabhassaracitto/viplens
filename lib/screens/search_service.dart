import '../models/mindmap_model.dart';
import '../models/node_model.dart';
import '../services/database_service.dart';

enum SearchScope { all, titles, pali, notes }

enum SortOrder { relevance, date, name }

class SearchResult {
  final MindMapModel mindmap;
  final List<NodeModel> matchedNodes;

  SearchResult({required this.mindmap, required this.matchedNodes});
}

class SearchService {
  static List<SearchResult> advancedSearch({
    required String query,
    SearchScope scope = SearchScope.all,
    SortOrder sortOrder = SortOrder.relevance,
    bool flashcardsOnly = false,
  }) {
    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) return [];

    final allMaps = DatabaseService.getAllMindMaps();
    final results = <SearchResult>[];

    for (final map in allMaps) {
      final matchedNodes = <NodeModel>[];
      bool mapMatched = false;

      // 1. Kiểm tra tiêu đề Mindmap
      if (scope == SearchScope.all || scope == SearchScope.titles) {
        if (map.title.toLowerCase().contains(lowerQuery)) {
          mapMatched = true;
        }
      }

      // 2. Kiểm tra các Node
      for (final node in map.nodes) {
        if (flashcardsOnly && !node.isFlashcard) continue;

        bool nodeMatched = false;

        // Tìm trong nội dung
        if (scope == SearchScope.all) {
          if (node.content.toLowerCase().contains(lowerQuery)) {
            nodeMatched = true;
          }
        }

        // Tìm trong Pali
        if (!nodeMatched &&
            (scope == SearchScope.all || scope == SearchScope.pali)) {
          if (node.paliText?.toLowerCase().contains(lowerQuery) ?? false) {
            nodeMatched = true;
          }
        }

        // Tìm trong Ghi chú
        if (!nodeMatched &&
            (scope == SearchScope.all || scope == SearchScope.notes)) {
          if (node.note?.toLowerCase().contains(lowerQuery) ?? false) {
            nodeMatched = true;
          }
        }

        if (nodeMatched) {
          matchedNodes.add(node);
        }
      }

      // Nếu map khớp hoặc có node khớp thì thêm vào kết quả
      if (mapMatched || matchedNodes.isNotEmpty) {
        results.add(SearchResult(mindmap: map, matchedNodes: matchedNodes));
      }
    }

    // Sắp xếp kết quả
    if (sortOrder == SortOrder.relevance) {
      results.sort((a, b) {
        // Ưu tiên số lượng node khớp
        return b.matchedNodes.length.compareTo(a.matchedNodes.length);
      });
    }

    return results;
  }
}
