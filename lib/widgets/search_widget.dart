import 'package:flutter/material.dart';
import '../services/search_service.dart';
import '../utils/colors.dart';

class AdvancedSearchWidget extends StatefulWidget {
  final Function(List<SearchResult>) onResults;
  final VoidCallback? onClose;

  const AdvancedSearchWidget({
    super.key,
    required this.onResults,
    this.onClose,
  });

  @override
  State<AdvancedSearchWidget> createState() => _AdvancedSearchWidgetState();
}

class _AdvancedSearchWidgetState extends State<AdvancedSearchWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  SearchScope _scope = SearchScope.all;
  SortOrder _sortOrder = SortOrder.relevance;
  bool _flashcardsOnly = false;
  List<String> _suggestions = [];
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _search() {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      widget.onResults([]);
      return;
    }

    final results = SearchService.advancedSearch(
      query: query,
      scope: _scope,
      sortOrder: _sortOrder,
      flashcardsOnly: _flashcardsOnly,
    );

    widget.onResults(results);
  }

  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    setState(() {
      _suggestions = SearchService.getSuggestions(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              // Search input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _controller.clear();
                                  _updateSuggestions('');
                                  widget.onResults([]);
                                },
                              )
                            : null,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        _updateSuggestions(value);
                        _search();
                      },
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.tune,
                      color: _showFilters ? AppColors.primary : null,
                    ),
                    onPressed: () {
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                  ),
                  if (widget.onClose != null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onClose,
                    ),
                ],
              ),

              // Filters
              if (_showFilters) ...[
                const SizedBox(height: 16),
                _buildFilters(),
              ],
            ],
          ),
        ),

        // Suggestions
        if (_suggestions.isNotEmpty)
          Container(
            color: Theme.of(context).cardColor,
            child: Column(
              children: _suggestions
                  .map((suggestion) => ListTile(
                        leading: const Icon(Icons.history, size: 20),
                        title: Text(suggestion),
                        dense: true,
                        onTap: () {
                          _controller.text = suggestion;
                          _controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: suggestion.length),
                          );
                          _search();
                          setState(() {
                            _suggestions = [];
                          });
                        },
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scope
        Text(
          'Tìm trong',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: SearchScope.values.map((scope) {
            final isSelected = _scope == scope;
            return FilterChip(
              label: Text(_getScopeLabel(scope)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _scope = scope;
                });
                _search();
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Sort order
        Text(
          'Sắp xếp',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: SortOrder.values.map((order) {
            final isSelected = _sortOrder == order;
            return FilterChip(
              label: Text(_getSortLabel(order)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _sortOrder = order;
                });
                _search();
              },
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Flashcards only
        SwitchListTile(
          title: const Text('Chỉ flashcards'),
          value: _flashcardsOnly,
          onChanged: (value) {
            setState(() {
              _flashcardsOnly = value;
            });
            _search();
          },
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  String _getScopeLabel(SearchScope scope) {
    switch (scope) {
      case SearchScope.all:
        return 'Tất cả';
      case SearchScope.titles:
        return 'Tiêu đề';
      case SearchScope.content:
        return 'Nội dung';
      case SearchScope.pali:
        return 'Pali';
      case SearchScope.notes:
        return 'Ghi chú';
      case SearchScope.tags:
        return 'Tags';
    }
  }

  String _getSortLabel(SortOrder order) {
    switch (order) {
      case SortOrder.relevance:
        return 'Liên quan';
      case SortOrder.dateNewest:
        return 'Mới nhất';
      case SortOrder.dateOldest:
        return 'Cũ nhất';
      case SortOrder.alphabetical:
        return 'A-Z';
      case SortOrder.nodeCount:
        return 'Số nodes';
    }
  }
}
