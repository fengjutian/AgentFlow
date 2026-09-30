/// Workspace-wide semantic search page.
///
/// Provides a search bar with source filtering (code/docs/all) and displays
/// ranked results with file paths, locators, and highlighted snippets.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/search/semantic_search_service.dart';
import '../../l10n/l10n.dart';

/// Provider for search results.
final searchResultsProvider =
    NotifierProvider<SearchResultsNotifier, SearchResultsState>(
        SearchResultsNotifier.new);

class SearchResultsState {
  const SearchResultsState({
    this.results = const [],
    this.query = '',
    this.isLoading = false,
    this.source = 'all',
  });

  final List<SearchResult> results;
  final String query;
  final bool isLoading;
  final String source;

  SearchResultsState copyWith({
    List<SearchResult>? results,
    String? query,
    bool? isLoading,
    String? source,
  }) =>
      SearchResultsState(
        results: results ?? this.results,
        query: query ?? this.query,
        isLoading: isLoading ?? this.isLoading,
        source: source ?? this.source,
      );
}

class SearchResultsNotifier extends Notifier<SearchResultsState> {
  SemanticSearchService? _service;

  @override
  SearchResultsState build() => const SearchResultsState();

  Future<void> search(String query, {String source = 'all'}) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], query: query, source: source);
      return;
    }

    state = state.copyWith(isLoading: true, query: query, source: source);

    final db = ref.read(databaseProvider);
    _service ??= SemanticSearchService(db: db);

    final workspace = ref.read(currentWorkspaceProvider);
    if (workspace == null) {
      state = state.copyWith(isLoading: false, results: []);
      return;
    }

    try {
      final results = await _service!.searchAll(
        query: query,
        workspaceId: workspace.id,
        limit: 50,
        source: source,
      );
      state = state.copyWith(isLoading: false, results: results);
    } catch (_) {
      state = state.copyWith(isLoading: false, results: []);
    }
  }

  void setSource(String source) {
    state = state.copyWith(source: source);
    if (state.query.isNotEmpty) {
      search(state.query, source: source);
    }
  }

  void clear() {
    state = const SearchResultsState();
  }
}

/// Workspace search page.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(searchResultsProvider.notifier).search(widget.initialQuery);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _doSearch() {
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      ref.read(searchResultsProvider.notifier).search(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchResultsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.search),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: context.l10n.searchWorkspace,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              ref.read(searchResultsProvider.notifier).clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (_) => _doSearch(),
                ),
                const SizedBox(height: 8),
                // Source filter chips
                Row(
                  children: [
                    _SourceChip(
                      label: 'All',
                      selected: state.source == 'all',
                      onTap: () => ref
                          .read(searchResultsProvider.notifier)
                          .setSource('all'),
                    ),
                    const SizedBox(width: 8),
                    _SourceChip(
                      label: 'Code',
                      selected: state.source == 'code',
                      onTap: () => ref
                          .read(searchResultsProvider.notifier)
                          .setSource('code'),
                    ),
                    const SizedBox(width: 8),
                    _SourceChip(
                      label: 'Docs',
                      selected: state.source == 'docs',
                      onTap: () => ref
                          .read(searchResultsProvider.notifier)
                          .setSource('docs'),
                    ),
                    const Spacer(),
                    if (state.results.isNotEmpty)
                      Text(
                        '${state.results.length} results',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.query.isEmpty
                                  ? context.l10n.enterSearchQuery
                                  : context.l10n.noResultsFound,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.results.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final result = state.results[index];
                          return _SearchResultTile(
                            result: result,
                            onTap: () => _openResult(result),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _openResult(SearchResult result) {
    if (result.source == 'code') {
      // Navigate to editor with the file.
      // The caller handles the navigation based on the returned result.
      Navigator.of(context).pop(result);
    }
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.result, required this.onTap});

  final SearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCode = result.source == 'code';

    return ListTile(
      leading: Icon(
        isCode ? Icons.code : Icons.description,
        color: isCode ? theme.colorScheme.primary : theme.colorScheme.secondary,
      ),
      title: Text(
        result.filePath,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.locator + (result.languageId.isNotEmpty ? ' · ${result.languageId}' : ''),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            result.snippet,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: isCode ? 'monospace' : null,
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
    );
  }
}

/// Shows the search page as a modal route and returns the selected result.
Future<SearchResult?> showSearchPage(
  BuildContext context, {
  String initialQuery = '',
}) {
  return Navigator.of(context).push<SearchResult>(
    MaterialPageRoute(
      builder: (_) => SearchPage(initialQuery: initialQuery),
    ),
  );
}
