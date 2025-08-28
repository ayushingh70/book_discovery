import 'package:book_discovery/features/common/widgets/search_filter_sheet.dart';
import 'package:book_discovery/features/home/presentation/book_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/books/books_repository.dart';
import '../../../core/books/book_models.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

enum _ViewMode { list, grid }

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();

  List<Book> _results = [];
  bool _loading = false;
  String? _error;

  _ViewMode _view = _ViewMode.list;

  // history
  List<String> _history = [];

  // --- FILTER STATE ---
  // (subject stays optional + local; categories/price come from sheet)
  String? _subject;

  static const List<String> _allCategories = [
    'Fiction', 'Sci-fi', 'Biography', 'Music', 'Non-fiction',
    'Mathematics', 'Horror', 'Magazine', 'Comics',
  ];
  Set<String> _selectedCats = {};

  // price range now 0..25000
  static const double _priceFloor = 0;
  static const double _priceCeil  = 25000;
  double _priceMin = _priceFloor;
  double _priceMax = 1000; // start a bit lower; still within ceil

  // new knobs from reusable sheet
  // availability -> maps to onlyFree/onlyPaid
  bool _onlyFree = false;
  bool _onlyPaid = false;

  String? _printType;   // null | 'books' | 'magazines'
  String? _orderBy;     // null | 'relevance' | 'newest'
  String? _langRestrict; // null | 'en' | 'hi' | 'es' | ...

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final repo = ref.read(booksRepoProvider);
    final list = await repo.latestHistory(limit: 8);
    if (!mounted) return;
    setState(() => _history = list);
  }

  Future<void> _runSearch(String raw) async {
    final q = raw.trim();
    if (q.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(booksRepoProvider);
      final filter = SearchFilter(
        subject: _subject,
        categories: _selectedCats.toList(),
        priceMin: _priceMin,
        priceMax: _priceMax,
        // new bits:
        onlyFree: _onlyFree,
        onlyPaid: _onlyPaid,
        printType: _printType,
        orderBy: _orderBy,
        langRestrict: _langRestrict,
      );

      final list = await repo.searchWithFilter(q, filter: filter, maxResults: 30);
      if (!mounted) return;
      setState(() => _results = list);
      _loadHistory();
      _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load this book.\nYou can try another search.');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // --- FILTER SHEET ---
  Future<void> _openFilterSheet() async {
    // derive availability label for the sheet from the two booleans
    String? availability;
    if (_onlyFree) availability = 'free';
    if (_onlyPaid) availability = 'paid';
    availability ??= 'any';

    final res = await showSearchFilterSheet(
      context,
      availableCategories: _allCategories,
      selectedCategories: _selectedCats.toList(),
      priceMin: _priceMin,
      priceMax: _priceMax,
      floor: _priceFloor,
      ceil: _priceCeil,
      availability: availability,
      printType: _printType,
      orderBy: _orderBy,
      langRestrict: _langRestrict,
    );

    if (res == null) return; // dismissed

    setState(() {
      _selectedCats = res.categories.toSet();
      _priceMin = (res.priceMin ?? _priceFloor).clamp(_priceFloor, _priceCeil);
      _priceMax = (res.priceMax ?? _priceCeil).clamp(_priceFloor, _priceCeil);

      // map back availability
      _onlyFree = res.onlyFree;
      _onlyPaid = res.onlyPaid;

      _printType = res.printType;
      _orderBy = res.orderBy;
      _langRestrict = res.langRestrict;
    });

    final q = _controller.text.trim();
    if (q.isNotEmpty) _runSearch(q);
  }

  @override
  Widget build(BuildContext context) {
    final padTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ---- Title ----
            Padding(
              padding: EdgeInsets.fromLTRB(16, padTop == 0 ? 12 : 4, 16, 8),
              child: Row(
                children: const [
                  Text('Search',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F1F39),
                      )),
                ],
              ),
            ),

            // ---- Search bar ----
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                textInputAction: TextInputAction.search,
                onSubmitted: _runSearch,
                decoration: InputDecoration(
                  hintText: 'Find books…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_controller.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _controller.clear();
                              _results = [];
                              _error = null;
                            });
                          },
                        ),
                      IconButton(
                        tooltip: 'Filter',
                        icon: const Icon(Icons.tune_rounded),
                        onPressed: _openFilterSheet,
                      ),
                    ],
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                ),
                onChanged: (_) => setState(() {}), // toggle clear icon
              ),
            ),

            // ---- Recent chips ----
            if (_history.isNotEmpty)
              SizedBox(
                height: 42,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, i) {
                    final q = _history[i];
                    return ActionChip(
                      label: Text(q, overflow: TextOverflow.ellipsis),
                      onPressed: () {
                        _controller.text = q;
                        _runSearch(q);
                      },
                      backgroundColor: const Color(0xFFF1F2F8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: _history.length,
                ),
              ),

            // ---- Results header with view toggle ----
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Results',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F1F39),
                        )),
                  ),
                  _viewIcon(Icons.view_list_rounded, _view == _ViewMode.list, () {
                    setState(() => _view = _ViewMode.list);
                  }),
                  const SizedBox(width: 8),
                  _viewIcon(Icons.grid_view_rounded, _view == _ViewMode.grid, () {
                    setState(() => _view = _ViewMode.grid);
                  }),
                ],
              ),
            ),

            // ---- Result area ----
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  final q = _controller.text.trim();
                  if (q.isNotEmpty) await _runSearch(q);
                },
                child: _loading
                    ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 200),
                    Center(child: CircularProgressIndicator()),
                  ],
                )
                    : (_error != null)
                    ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 160),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Color(0x143D5CFF), blurRadius: 18, offset: Offset(0, 10)),
                            BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 36, color: Color(0xFF3D5CFF)),
                            const SizedBox(height: 10),
                            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
                    : (_results.isEmpty)
                    ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 160),
                    Center(child: Text('Try searching for a book')),
                  ],
                )
                    : (_view == _ViewMode.grid
                    ? _GridResults(list: _results, onTap: _openDetails)
                    : _ListResults(list: _results, onTap: _openDetails)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetails(Book b) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, a, __) => FadeTransition(opacity: a, child: BookDetailScreen(book: b)), // Don,t know why its showing error but its correct
      ),
    );
  }

  Widget _viewIcon(IconData icon, bool selected, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAEAFF) : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: selected ? const Color(0xFF3D5CFF) : const Color(0xFFB8B8D2)),
      ),
    );
  }
}

// --- Result widgets ---
class _ListResults extends StatelessWidget {
  const _ListResults({required this.list, required this.onTap});
  final List<Book> list;
  final void Function(Book b) onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: PrimaryScrollController.of(context),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final b = list[i];
        final author = b.authors.isNotEmpty ? b.authors.join(', ') : 'Unknown author';
        return InkWell(
          onTap: () => onTap(b),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x143D5CFF), blurRadius: 18, offset: Offset(0, 10)),
                BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 72, height: 100,
                      child: (b.thumbnail != null)
                          ? Image.network(b.thumbnail!, fit: BoxFit.cover)
                          : Container(color: const Color(0xFFEDEEF3)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF1F1F39))),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.person_2_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(author,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.grey)),
                            ),
                          ],
                        ),
                        if (b.price != null) ...[
                          const SizedBox(height: 8),
                          Text('₹${b.price!.toStringAsFixed(0)}',
                              style: const TextStyle(color: Color(0xFF3D5CFF), fontWeight: FontWeight.w800)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GridResults extends StatelessWidget {
  const _GridResults({required this.list, required this.onTap});
  final List<Book> list;
  final void Function(Book b) onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, c) {
      final cols = c.maxWidth >= 680 ? 3 : 2;
      const spacing = 12.0;
      final tileW = (c.maxWidth - (cols - 1) * spacing) / cols;
      final coverH = tileW * 4 / 3;
      const pad = 10.0 + 8.0;
      const titleBlock = 32.0;
      const authorBlock = 16.0;
      const priceBlock = 18.0;
      final extent = pad + coverH + titleBlock + authorBlock + priceBlock;

      return GridView.builder(
        controller: PrimaryScrollController.of(context),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          mainAxisExtent: extent,
        ),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final b = list[i];
          final author = b.authors.isNotEmpty ? b.authors.first : 'Unknown';
          return InkWell(
            onTap: () => onTap(b),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 3)),
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: (b.thumbnail != null)
                          ? Image.network(b.thumbnail!, fit: BoxFit.cover)
                          : Container(color: const Color(0xFFEDEEF3)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(b.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F1F39))),
                  const SizedBox(height: 4),
                  Text(author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (b.price != null) ...[
                    const SizedBox(height: 6),
                    Text('₹${b.price!.toStringAsFixed(0)}',
                        style: const TextStyle(color: Color(0xFF3D5CFF), fontWeight: FontWeight.w800)),
                  ],
                ],
              ),
            ),
          );
        },
      );
    });
  }
}