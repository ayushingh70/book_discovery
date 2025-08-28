import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/books/books_repository.dart';
import '../../../core/books/book_models.dart';
import 'book_detail_screen.dart';
import '../../../features/common/widgets/search_filter_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

enum _Filter { all, popular, newOnes }

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _searchFocus = FocusNode();
  final _searchKey = GlobalKey();

  List<Book> _results = [];
  List<String> _history = [];
  bool _loading = false;
  bool _showingDiscovery = false;
  String? _error;

  _Filter _sort = _Filter.all;
  bool _grid = false;

  // --- SIMPLE FILTER STATE (categories + price via reusable sheet) ---
  static const List<String> _allCategories = [
    'Fiction',
    'Sci-fi',
    'Biography',
    'Music',
    'Non-fiction',
    'Mathematics',
    'Horror',
    'Magazine',
    'Comics',
  ];

  Set<String> _selectedCats = {}; // empty -> no category filter
  static const double _priceFloor = 0;
  static const double _priceCeil = 25000;
  double _priceMin = _priceFloor; // full range by default
  double _priceMax = _priceCeil;

  Future<void> _loadDiscoveryFeed() async {
    if (_loading) return;

    final repo = ref.read(booksRepoProvider);

    // A handful of broad/evergreen queries; Google Books handles these well.
    final seeds = <String>[
      'subject:fiction',
      'subject:nonfiction',
      'subject:romance',
      'subject:science',
      'subject:history',
      'bestseller books',
      'top novels',
      'technology books',
    ]..shuffle();

    setState(() {
      _loading = true;
      _error = null;
      _showingDiscovery = true;
    });

    try {
      List<Book> found = [];
      for (final q in seeds.take(3)) {
        final r = await repo.search(q, maxResults: 30);
        if (r.isNotEmpty) {
          found = r;
          break;
        }
      }
      if (!mounted) return;

      // For discovery feed we DON’T apply local category/price filters
      // so users always see something immediately.
      setState(() => _results = found);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Couldn’t load suggestions');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadDiscoveryFeed();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final repo = ref.read(booksRepoProvider);
    final h = await repo.loadHistory();
    if (!mounted) return;
    setState(() => _history = h);
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    setState(() {
      _showingDiscovery = false;
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(booksRepoProvider);
      // Basic fetch (fast). Then client-side filter with our two knobs.
      final list = await repo.search(q, maxResults: 30);
      if (!mounted) return;

      final catsLower = _selectedCats.map((e) => e.toLowerCase()).toList();

      final filtered = list.where((b) {
        // Categories: pass if any selected matches (if none -> pass all)
        final passCat = _selectedCats.isEmpty
            ? true
            : b.categories
            .map((e) => e.toLowerCase())
            .any((c) => catsLower.contains(c));
        if (!passCat) return false;

        // Price: only pass when price present and in range
        if (b.price == null) return false;
        if (b.price! < _priceMin || b.price! > _priceMax) return false;

        return true;
      }).toList();

      // Small sort demo
      switch (_sort) {
        case _Filter.popular:
          filtered.sort(
                  (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
          break;
        case _Filter.newOnes:
          filtered.sort(
                  (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
          break;
        case _Filter.all:
          break;
      }

      setState(() => _results = filtered);

      _loadHistory(); // refresh recent list

      if (_scroll.hasClients) {
        _scroll.animateTo(0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load books');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  bool get _showSuggestions =>
      _searchFocus.hasFocus && _history.isNotEmpty && !_loading;

  double _suggestionsTopPx(BuildContext context) {
    final box = _searchKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return 0;
    final offset = box.localToGlobal(Offset.zero);
    return offset.dy + box.size.height;
    // SafeArea top already excluded because the Stack is inside SafeArea.
  }

  List<Book> _sortedForView() {
    final list = List<Book>.from(_results);
    switch (_sort) {
      case _Filter.all:
        return list;
      case _Filter.popular:
        list.sort(
                (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        return list;
      case _Filter.newOnes:
        list.sort(
                (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        return list;
    }
  }

  // --- Open reusable Search Filter sheet ---
  Future<void> _openFilterSheet() async {
    final res = await showSearchFilterSheet(
      context,
      availableCategories: _allCategories,
      selectedCategories: _selectedCats.toList(),
      priceMin: _priceMin,
      priceMax: _priceMax,
      floor: _priceFloor,
      ceil: _priceCeil,
    );

    if (res == null) return; // dismissed

    setState(() {
      _selectedCats = res.categories.toSet();
      _priceMin = res.priceMin ?? _priceFloor;
      _priceMax = res.priceMax ?? _priceCeil;
    });

    // Re-run current search if there is text
    final q = _controller.text.trim();
    if (q.isNotEmpty) _search(q);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // --- Main content ---
          Column(
            children: [
              // Title + avatar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const Text(
                      ' Course',
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F1F39),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/images/avatar.png',
                          width: 36,
                          height: 52,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search bar (keyed)
              Padding(
                key: _searchKey,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _controller,
                  focusNode: _searchFocus,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (q) {
                    _search(q);
                    _searchFocus.unfocus();
                  },
                  decoration: InputDecoration(
                    hintText: 'Find Course',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Filter',
                          icon: const Icon(Icons.tune),
                          onPressed: _openFilterSheet,
                        ),
                        if (_controller.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _controller.clear();
                                _results = [];
                                _error = null;
                              });
                              _searchFocus.unfocus();
                            },
                          ),
                      ],
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 12),
                  ),
                  onChanged: (_) => setState(() {}), // toggles clear icon
                ),
              ),

              // Promo cards (ads1 + ads2)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: const [
                    _AdCard(asset: 'assets/images/ads1.png'),
                    SizedBox(width: 16),
                    _AdCard(asset: 'assets/images/ads2.png'),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Choice header + view icons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        ' Choice your course',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F1F39),
                        ),
                      ),
                    ),
                    _ViewIcon(
                      icon: Icons.view_list_rounded,
                      selected: !_grid,
                      onTap: () => setState(() => _grid = false),
                    ),
                    const SizedBox(width: 8),
                    _ViewIcon(
                      icon: Icons.grid_view_rounded,
                      selected: _grid,
                      onTap: () => setState(() => _grid = true),
                    ),
                  ],
                ),
              ),

              // Filter pills (All / Asc / Desc)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: 'All',
                      selected: _sort == _Filter.all,
                      onTap: () => setState(() => _sort = _Filter.all),
                    ),
                    const SizedBox(width: 12),
                    _FilterPill(
                      label: 'Ascending',
                      selected: _sort == _Filter.popular,
                      onTap: () => setState(() => _sort = _Filter.popular),
                    ),
                    const SizedBox(width: 12),
                    _FilterPill(
                      label: 'Descending',
                      selected: _sort == _Filter.newOnes,
                      onTap: () => setState(() => _sort = _Filter.newOnes),
                    ),
                  ],
                ),
              ),

              // Results / empty / loading + pull-to-refresh
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    final q = _controller.text.trim();
                    if (q.isEmpty) {
                      await _loadDiscoveryFeed(); // refresh random/discovery books
                    } else {
                      await _search(q); // rerun current search
                    }
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
                    physics:
                    const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 200),
                      Center(child: Text(_error!)),
                    ],
                  )
                      : (_sortedForView().isEmpty)
                      ? ListView(
                    physics:
                    const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 200),
                      _EmptyState(),
                    ],
                  )
                      : (_grid
                      ? GridView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(
                        16, 8, 16, 16),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.58,
                    ),
                    itemCount:
                    _sortedForView().length,
                    itemBuilder: (_, i) =>
                        _BookCardGrid(
                            book:
                            _sortedForView()[i]),
                  )
                      : ListView.builder(
                    controller: _scroll,
                    padding:
                    const EdgeInsets.fromLTRB(
                        16, 8, 16, 16),
                    itemCount:
                    _sortedForView().length,
                    itemBuilder: (_, i) => _BookTile(
                        book:
                        _sortedForView()[i]),
                  )),
                ),
              )
            ],
          ),

          // Tap-outside backdrop (only when suggestions showing)
          if (_showSuggestions)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _searchFocus.unfocus()),
                child: Container(color: Colors.transparent),
              ),
            ),

          // Overlay suggestions panel (doesn’t push layout)
          if (_showSuggestions)
            Positioned(
              left: 16,
              right: 16,
              top: _suggestionsTopPx(context) + 8,
              child: Material(
                color: Colors.white.withOpacity(0.92),
                elevation: 10,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: _history.length > 5 ? 5 : _history.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, color: Color(0xFFEFEFEF)),
                    itemBuilder: (_, i) {
                      final q = _history[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.history,
                            color: Color(0xFF9AA0B4)),
                        title: Text(q,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        trailing: TextButton(
                          onPressed: () => _search(q),
                          child: const Text('Search'),
                        ),
                        onTap: () {
                          _controller.text = q;
                          _search(q);
                          _searchFocus.unfocus();
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Sorry, no results found for these filters',
        style: TextStyle(color: Colors.grey.shade600),
      ),
    );
  }
}

class _AdCard extends StatelessWidget {
  final String asset;
  const _AdCard({required this.asset});

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - 16 - 16 - 16) / 2;
    const h = 120.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: w,
        height: h,
        child: Image.asset(asset, fit: BoxFit.cover),
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  final Book book;
  const _BookTile({required this.book});

  @override
  Widget build(BuildContext context) {
    final authors =
    book.authors.isNotEmpty ? book.authors.join(', ') : 'Unknown author';
    final desc = (book.description ?? '').replaceAll(RegExp(r'\s+'), ' ');
    final short = desc.isEmpty
        ? ''
        : (desc.length > 140 ? '${desc.substring(0, 140)}…' : desc);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 280),
            pageBuilder: (_, a, __) =>
                FadeTransition(opacity: a, child: BookDetailScreen(book: book)),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x143D5CFF),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'thumb_${book.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 72,
                    height: 100,
                    child: book.thumbnail != null
                        ? Image.network(book.thumbnail!, fit: BoxFit.cover)
                        : Container(color: const Color(0xFFEDEEF3)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F1F39),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Author row
                    Row(
                      children: [
                        const Icon(Icons.person_2_outlined,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            authors,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    if (short.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        short,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black54,
                          height: 1.25,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    // Optional bottom meta row (price / year)
                    Row(
                      children: [
                        if (book.price != null &&
                            book.currencyCode != null) ...[
                          const Icon(Icons.sell_outlined,
                              size: 16, color: Color(0xFF3D5CFF)),
                          const SizedBox(width: 4),
                          Text(
                            '${book.currencyCode} ${book.price!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3D5CFF),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (book.publishedYear != null) ...[
                          const Icon(Icons.calendar_today_outlined,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${book.publishedYear}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Compact grid card (smaller, fixed 3:4 cover)
class _BookCardGrid extends StatelessWidget {
  final Book book;
  const _BookCardGrid({required this.book});

  @override
  Widget build(BuildContext context) {
    final author =
    book.authors.isNotEmpty ? book.authors.first : 'Unknown author';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 240),
            pageBuilder: (_, a, __) => FadeTransition(
                opacity: a, child: BookDetailScreen(book: book)),
          ),
        );
      },
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
            // --- Cover keeps a perfect 3:4 ratio and fills nicely
            Hero(
              tag: 'thumb_${book.id}_grid',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 3 / 4, // consistent thumbnails
                  child: book.thumbnail != null
                      ? Image.network(book.thumbnail!, fit: BoxFit.cover)
                      : Container(
                    color: const Color(0xFFEDEEF3),
                    alignment: Alignment.center,
                    child: const Icon(Icons.menu_book_rounded,
                        size: 28, color: Color(0xFFB8B8D2)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // --- Title (2 lines max)
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1F39),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),

            // --- Author (1 line)
            Text(
              author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, color: Colors.grey),
            ),

            // --- Price (optional)
            if (book.price != null) ...[
              const SizedBox(height: 6),
              Text(
                '₹${book.price!.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF3D5CFF),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3D5CFF) : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF858597),
          ),
        ),
      ),
    );
  }
}

class _ViewIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ViewIcon({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAEAFF) : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: selected ? const Color(0xFF3D5CFF) : const Color(0xFFB8B8D2),
        ),
      ),
    );
  }
}