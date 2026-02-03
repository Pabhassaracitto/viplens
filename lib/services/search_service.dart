import 'package:flutter/material.dart';
import '../models/mindmap_model.dart';
import '../models/node_model.dart';
import 'database_service.dart';

enum SearchScope {
  all,
  titles,
  content,
  pali,
  notes,
  tags,
}

enum SortOrder {
  relevance,
  dateNewest,
  dateOldest,
  alphabetical,
  nodeCount,
}

class SearchResult {
  final MindMapModel mindmap;
  final List<NodeModel> matchedNodes;
  final double relevanceScore;

  SearchResult({
    required this.mindmap,
    required this.matchedNodes,
    required this.relevanceScore,
  });
}

class SearchService {
  /// Tìm kiếm nâng cao
  static List<SearchResult> advancedSearch({
    required String query,
    SearchScope scope = SearchScope.all,
    SortOrder sortOrder = SortOrder.relevance,
    String? folderId,
    bool flashcardsOnly = false,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    if (query.isEmpty) return [];

    final allMindmaps = DatabaseService.getAllMindMaps();
    final results = <SearchResult>[];
    final lowerQuery = query.toLowerCase();
    final queryWords =
        lowerQuery.split(' ').where((w) => w.isNotEmpty).toList();

    for (final mindmap in allMindmaps) {
      // Filter by folder
      if (folderId != null && mindmap.folderId != folderId) continue;

      // Filter by date
      if (fromDate != null && mindmap.createdAt.isBefore(fromDate)) continue;
      if (toDate != null && mindmap.createdAt.isAfter(toDate)) continue;

      double score = 0;
      final matchedNodes = <NodeModel>[];

      // Search in title
      if (scope == SearchScope.all || scope == SearchScope.titles) {
        final titleScore = _calculateScore(mindmap.title, queryWords);
        if (titleScore > 0) {
          score += titleScore * 2; // Title matches are more important
        }
      }

      // Search in tags
      if (scope == SearchScope.all || scope == SearchScope.tags) {
        for (final tag in mindmap.tags) {
          final tagScore = _calculateScore(tag, queryWords);
          if (tagScore > 0) {
            score += tagScore * 1.5;
          }
        }
      }

      // Search in nodes
      for (final node in mindmap.nodes) {
        // Filter flashcards only
        if (flashcardsOnly && !node.isFlashcard) continue;

        double nodeScore = 0;

        // Search in content
        if (scope == SearchScope.all || scope == SearchScope.content) {
          nodeScore += _calculateScore(node.content, queryWords);
        }

        // Search in Pali
        if (scope == SearchScope.all || scope == SearchScope.pali) {
          if (node.paliText != null) {
            nodeScore += _calculateScore(node.paliText!, queryWords) * 1.2;
          }
        }

        // Search in notes
        if (scope == SearchScope.all || scope == SearchScope.notes) {
          if (node.note != null) {
            nodeScore += _calculateScore(node.note!, queryWords) * 0.8;
          }
        }

        if (nodeScore > 0) {
          matchedNodes.add(node);
          score += nodeScore;
        }
      }

      if (score > 0 || matchedNodes.isNotEmpty) {
        results.add(SearchResult(
          mindmap: mindmap,
          matchedNodes: matchedNodes,
          relevanceScore: score,
        ));
      }
    }

    // Sort results
    switch (sortOrder) {
      case SortOrder.relevance:
        results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
        break;
      case SortOrder.dateNewest:
        results
            .sort((a, b) => b.mindmap.updatedAt.compareTo(a.mindmap.updatedAt));
        break;
      case SortOrder.dateOldest:
        results
            .sort((a, b) => a.mindmap.updatedAt.compareTo(b.mindmap.updatedAt));
        break;
      case SortOrder.alphabetical:
        results.sort((a, b) => a.mindmap.title.compareTo(b.mindmap.title));
        break;
      case SortOrder.nodeCount:
        results.sort(
            (a, b) => b.mindmap.nodes.length.compareTo(a.mindmap.nodes.length));
        break;
    }

    return results;
  }

  /// Tính điểm match
  static double _calculateScore(String text, List<String> queryWords) {
    final lowerText = text.toLowerCase();
    double score = 0;

    for (final word in queryWords) {
      if (lowerText.contains(word)) {
        score += 1;

        // Bonus cho exact word match
        if (lowerText.split(' ').contains(word)) {
          score += 0.5;
        }

        // Bonus cho match ở đầu
        if (lowerText.startsWith(word)) {
          score += 0.3;
        }
      }
    }

    return score;
  }

  /// Tìm kiếm nhanh (chỉ title và content)
  static List<MindMapModel> quickSearch(String query) {
    if (query.isEmpty) return DatabaseService.getAllMindMaps();

    final results = advancedSearch(
      query: query,
      scope: SearchScope.all,
      sortOrder: SortOrder.relevance,
    );

    return results.map((r) => r.mindmap).toList();
  }

  /// Lấy suggestions
  static List<String> getSuggestions(String query, {int limit = 5}) {
    if (query.isEmpty) return [];

    final suggestions = <String>{};
    final lowerQuery = query.toLowerCase();
    final mindmaps = DatabaseService.getAllMindMaps();

    // Từ titles
    for (final map in mindmaps) {
      if (map.title.toLowerCase().contains(lowerQuery)) {
        suggestions.add(map.title);
      }

      // Từ tags
      for (final tag in map.tags) {
        if (tag.toLowerCase().contains(lowerQuery)) {
          suggestions.add(tag);
        }
      }

      // Từ node content
      for (final node in map.nodes) {
        if (node.content.toLowerCase().contains(lowerQuery)) {
          // Chỉ thêm nếu ngắn
          if (node.content.length <= 50) {
            suggestions.add(node.content);
          }
        }
      }

      if (suggestions.length >= limit * 2) break;
    }

    return suggestions.take(limit).toList();
  }

  /// Highlight text với query
  static List<TextSpan> highlightText(
    String text,
    String query, {
    TextStyle? normalStyle,
    TextStyle? highlightStyle,
  }) {
    if (query.isEmpty) {
      return [TextSpan(text: text, style: normalStyle)];
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    int start = 0;
    int index = lowerText.indexOf(lowerQuery);

    while (index != -1) {
      // Text trước match
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: normalStyle,
        ));
      }

      // Highlighted text
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: highlightStyle ??
            TextStyle(
              backgroundColor: Colors.yellow.withOpacity(0.5),
              fontWeight: FontWeight.bold,
            ),
      ));

      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    // Text còn lại
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: normalStyle,
      ));
    }

    return spans;
  }
}
