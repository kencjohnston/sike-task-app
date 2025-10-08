import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/search_query.dart';
import '../providers/task_provider.dart';
import '../services/search_service.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/search_filter_chip.dart';
import '../widgets/search_result_item.dart';
import '../widgets/advanced_filters_sheet.dart';
import '../widgets/empty_state.dart';
import 'task_form_screen.dart';

/// Screen for searching tasks with advanced filtering
class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late SearchService _searchService;
  List<SearchQuery> _recentSearches = [];
  List<Task> _searchResults = [];
  SearchQuery? _currentQuery;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initSearchService();
  }

  Future<void> _initSearchService() async {
    final prefs = await SharedPreferences.getInstance();
    _searchService = SearchService(prefs);
    await _loadRecentSearches();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadRecentSearches() async {
    final searches = await _searchService.getRecentSearches();
    setState(() {
      _recentSearches = searches;
    });
  }

  void _performSearch(String text) {
    final taskProvider = context.read<TaskProvider>();
    final allTasks = taskProvider.tasks;

    setState(() {
      _currentQuery = SearchQuery(text: text);
      _searchResults = _searchService.searchTasks(text, allTasks);
    });

    // Save to recent searches if not empty
    if (text.trim().isNotEmpty) {
      _searchService.saveRecentSearch(text);
      _loadRecentSearches();
    }
  }

  void _performAdvancedSearch(SearchQuery query) {
    final taskProvider = context.read<TaskProvider>();
    final allTasks = taskProvider.tasks;

    setState(() {
      _currentQuery = query;
      _searchResults = _searchService.searchWithFilters(
        text: query.text.isNotEmpty ? query.text : null,
        taskTypes: query.taskTypes,
        priorities: query.priorities,
        contexts: query.contexts,
        isCompleted: query.isCompleted,
        isRecurring: query.isRecurring,
        tasks: allTasks,
      );
    });

    // Save to recent searches if text is not empty
    if (query.text.trim().isNotEmpty) {
      _searchService.saveRecentSearch(query.text);
      _loadRecentSearches();
    }
  }

  void _clearSearch() {
    setState(() {
      _currentQuery = null;
      _searchResults = [];
    });
  }

  Future<void> _showAdvancedFilters() async {
    final result = await showAdvancedFiltersSheet(
      context,
      initialQuery: _currentQuery,
    );

    if (result != null) {
      _performAdvancedSearch(result);
    }
  }

  void _removeFilter(String filterType) {
    if (_currentQuery == null) return;

    SearchQuery updatedQuery;
    switch (filterType) {
      case 'taskTypes':
        updatedQuery = _currentQuery!.copyWith(taskTypes: []);
        break;
      case 'priorities':
        updatedQuery = _currentQuery!.copyWith(priorities: []);
        break;
      case 'contexts':
        updatedQuery = _currentQuery!.copyWith(contexts: []);
        break;
      case 'completed':
        updatedQuery = _currentQuery!.copyWith(isCompleted: null);
        break;
      case 'recurring':
        updatedQuery = _currentQuery!.copyWith(isRecurring: null);
        break;
      default:
        return;
    }

    _performAdvancedSearch(updatedQuery);
  }

  Future<void> _refreshResults() async {
    if (_currentQuery != null) {
      _performAdvancedSearch(_currentQuery!);
    }
  }

  void _navigateToTaskDetail(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(task: task),
      ),
    ).then((_) {
      // Refresh results after returning from task detail
      _refreshResults();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final hasQuery = _currentQuery != null && _currentQuery!.text.isNotEmpty;
    final hasFilters = _currentQuery?.hasFilters ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          SearchBarWidget(
            initialValue: _currentQuery?.text,
            onChanged: _performSearch,
            onClear: _clearSearch,
          ),

          // Active filter chips row
          if (hasFilters)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Task type filters
                    if (_currentQuery!.taskTypes != null &&
                        _currentQuery!.taskTypes!.isNotEmpty)
                      SearchFilterChip(
                        label:
                            '${_currentQuery!.taskTypes!.length} Type${_currentQuery!.taskTypes!.length > 1 ? 's' : ''}',
                        icon: Icons.category,
                        onRemove: () => _removeFilter('taskTypes'),
                      ),

                    const SizedBox(width: 8),

                    // Priority filters
                    if (_currentQuery!.priorities != null &&
                        _currentQuery!.priorities!.isNotEmpty)
                      SearchFilterChip(
                        label:
                            '${_currentQuery!.priorities!.length} Priorit${_currentQuery!.priorities!.length > 1 ? 'ies' : 'y'}',
                        icon: Icons.priority_high,
                        onRemove: () => _removeFilter('priorities'),
                      ),

                    const SizedBox(width: 8),

                    // Context filters
                    if (_currentQuery!.contexts != null &&
                        _currentQuery!.contexts!.isNotEmpty)
                      SearchFilterChip(
                        label:
                            '${_currentQuery!.contexts!.length} Context${_currentQuery!.contexts!.length > 1 ? 's' : ''}',
                        icon: Icons.location_on,
                        onRemove: () => _removeFilter('contexts'),
                      ),

                    const SizedBox(width: 8),

                    // Completion status filter
                    if (_currentQuery!.isCompleted != null)
                      SearchFilterChip(
                        label: _currentQuery!.isCompleted!
                            ? 'Completed'
                            : 'Active',
                        icon: _currentQuery!.isCompleted!
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        onRemove: () => _removeFilter('completed'),
                      ),

                    const SizedBox(width: 8),

                    // Recurring filter
                    if (_currentQuery!.isRecurring != null)
                      SearchFilterChip(
                        label: _currentQuery!.isRecurring!
                            ? 'Recurring'
                            : 'One-time',
                        icon: _currentQuery!.isRecurring!
                            ? Icons.repeat
                            : Icons.event,
                        onRemove: () => _removeFilter('recurring'),
                      ),
                  ],
                ),
              ),
            ),

          // Advanced filters button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showAdvancedFilters,
                icon: const Icon(Icons.filter_list),
                label: Text(hasFilters ? 'Modify Filters' : 'Advanced Filters'),
              ),
            ),
          ),

          const Divider(height: 1),

          // Main content
          Expanded(
            child: hasQuery ? _buildSearchResults() : _buildRecentSearches(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return const EmptyState(
        message: 'No recent searches',
        subMessage: 'Start typing to search for tasks',
        icon: Icons.search,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecentSearches,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () async {
                  await _searchService.clearSearchHistory();
                  _loadRecentSearches();
                },
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...(_recentSearches.map((query) {
            return ListTile(
              leading: const Icon(Icons.history),
              title: Text(query.text),
              subtitle: query.hasFilters
                  ? const Text('With filters', style: TextStyle(fontSize: 12))
                  : null,
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                _performSearch(query.text);
              },
            );
          }).toList()),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const EmptyState(
        message: 'No results found',
        subMessage: 'Try adjusting your search or filters',
        icon: Icons.search_off,
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshResults,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '${_searchResults.length} result${_searchResults.length != 1 ? 's' : ''} found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
          ),

          // Results list
          ...(_searchResults.map((task) {
            return SearchResultItem(
              task: task,
              searchQuery: _currentQuery?.text ?? '',
              onTap: () => _navigateToTaskDetail(task),
            );
          }).toList()),
        ],
      ),
    );
  }
}
