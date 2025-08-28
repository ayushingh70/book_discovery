import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/books/book_models.dart';
import '../../../core/books/books_repository.dart';
import '../../../core/favorites/favorites_store.dart';
class BookDetailScreen extends ConsumerStatefulWidget {
  const BookDetailScreen({super.key, required this.book});
  final Book book;

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  bool _expanded = false;
  bool _fav = false; // simple local favorite toggle for now
  Book? _full;       // detailed volume (fetched on open)


  // --- html → plain text (very lightweight) ---
  String _unescapeHtml(String s) => s
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");

  String _plainText(String html) {
    final noTags = html.replaceAll(RegExp(r'<[^>]+>'), ' ');
    return _unescapeHtml(noTags).replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // Helpers
  Book get b => _full ?? widget.book;
  String get _googleBooksUrl => 'https://books.google.com/books?id=${widget.book.id}';

  Future<void> _loadFull() async {
    try {
      final repo = ref.read(booksRepoProvider);
      final detailed = await repo.volume(widget.book.id);
      if (!mounted) return;
      setState(() => _full = detailed);
    } catch (_) {
      // Silently keep the lightweight book if the extra call fails.
    }
  }

  Future<void> _openExternal(String? urlFallback) async {
    final url = urlFallback ?? _googleBooksUrl;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  Future<void> _copyText(String text, {String label = 'Copied'}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(color: Color(0x143D5CFF), blurRadius: 18, offset: Offset(0, 10)),
      BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
    ],
  );

  Widget _coverPlaceholder() => Container(
    color: const Color(0xFFEDEEF3),
    child: const Icon(Icons.menu_book, color: Colors.grey, size: 40),
  );

  Widget _kv(String label, String? value) {
    final shown = (value == null || value.trim().isEmpty) ? 'N/A' : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
          ),
          Flexible(
            child: Text(
              shown,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1F1F39)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kvCopyable({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
          ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: Color(0xFF1F1F39)),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => _copyText(value, label: 'ISBN copied'),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.copy_rounded, size: 16, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _authorJoined =>
      b.authors.isNotEmpty ? b.authors.join(', ') : 'N/A';

  @override
  void initState() {
    super.initState();
    _loadFull();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favs = ref.watch(favoritesProvider);
    final isFav = favs.contains(widget.book.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Book details'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F1F39),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // --- Header: cover + info ---
          Container(
            padding: const EdgeInsets.all(14),
            decoration: _cardDecoration(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'thumb_${widget.book.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 110,
                      height: 160,
                      child: (b.thumbnail != null && b.thumbnail!.isNotEmpty)
                          ? Image.network(b.thumbnail!, fit: BoxFit.cover)
                          : _coverPlaceholder(),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        b.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Color(0xFF1F1F39),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Author & year
                      Row(
                        children: [
                          const Icon(Icons.person_2_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _authorJoined,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ),
                          if (b.publishedYear != null) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.calendar_today_outlined,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('${b.publishedYear}',
                                style: const TextStyle(color: Colors.black54)),
                          ],
                        ],
                      ),

                      // Ratings (if available)
                      if (b.averageRating != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _Stars(rating: b.averageRating!),
                            const SizedBox(width: 8),
                            Text(
                              b.ratingsCount != null
                                  ? '${b.averageRating} • ${b.ratingsCount} ratings'
                                  : '${b.averageRating}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ],

                      // Price chip (if any)
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (b.price != null && b.currencyCode != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAEAFF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${b.currencyCode} ${b.price!.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF3D5CFF),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          // Heart
                          InkWell(
                            onTap: () {
                              setState(() => _fav = !_fav);

                              // Show feedback
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _fav ? 'Added to Favorites ❤️' : 'Removed from Favorites',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.all(12),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _fav ? const Color(0xFFFCEBEE) : const Color(0xFFF5F6FA),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _fav ? Icons.favorite : Icons.favorite_border,
                                size: 20,
                                color: _fav ? const Color(0xFFE53935) : const Color(0xFFB8B8D2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // --- Details ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Details'),
                const SizedBox(height: 8),
                _kv('Author', b.authors.isEmpty ? null : _authorJoined),
                _kv('Language', b.languageNice),
                if (b.publisher != null && b.publisher!.trim().isNotEmpty)
                  _kv('Publisher', b.publisher),
                if (b.maturityRating != null && b.maturityRating!.trim().isNotEmpty)
                  _kv('Maturity', b.maturityRating),
                if ((b.isbn13 ?? b.isbn10) != null)
                  _kvCopyable(
                      label: 'ISBN',
                      value: (b.isbn13 != null && b.isbn13!.isNotEmpty)
                          ? b.isbn13!
                          : b.isbn10!),
                if (b.pageCount != null) _kv('Pages', '${b.pageCount}'),
                if (b.categories.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Categories',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: b.categories
                        .map((c) => Chip(
                      label: Text(c, style: const TextStyle(fontSize: 12)),
                      backgroundColor: const Color(0xFFF5F6FA),
                      visualDensity: VisualDensity.compact,
                    ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // --- Description ---
          if (b.description != null && b.description!.trim().isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Description'),
                  const SizedBox(height: 8),
                  Builder(builder: (_) {
                    final desc = _plainText(b.description!);
                    return AnimatedCrossFade(
                      crossFadeState: _expanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 200),
                      firstChild: Text(
                        desc,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, height: 1.35),
                      ),
                      secondChild: Text(
                        desc,
                        style: const TextStyle(fontSize: 15, height: 1.35),
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => setState(() => _expanded = !_expanded),
                      child: Text(_expanded ? 'Show less' : 'Read more'),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 14),

          // --- Actions ---
          Container(
            padding: const EdgeInsets.all(14),
            decoration: _cardDecoration(),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D5CFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                  onPressed: () => _openExternal(b.infoLink),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open in Google Books',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _copyText(_googleBooksUrl, label: 'Link copied'),
                  icon: const Icon(Icons.link_rounded),
                  label: const Text('Copy link'),
                ),
              ],
            ),
          ),

          // --- More by same author ---
          if (b.authors.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'More by ${b.authors.first}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F1F39),
              ),
            ),
            const SizedBox(height: 10),
            _MoreByAuthor(author: b.authors.first),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// --- Small widgets ---

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: Color(0xFF1F1F39),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating});
  final double rating; // 0..5
  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final half = (rating - full) >= 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < full) return const Icon(Icons.star, size: 16, color: Color(0xFFFFC107));
        if (i == full && half) return const Icon(Icons.star_half, size: 16, color: Color(0xFFFFC107));
        return const Icon(Icons.star_border, size: 16, color: Color(0xFFFFC107));
      }),
    );
  }
}

class _MoreByAuthor extends ConsumerWidget {
  const _MoreByAuthor({required this.author});
  final String author;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(booksRepoProvider);

    const cardW = 130.0;
    const innerPad = 10.0;
    const coverAR = 3 / 4;
    final coverW = cardW - innerPad * 2;
    final coverH = coverW / coverAR;
    final ts = MediaQuery.of(context).textScaleFactor.clamp(1.0, 1.3);
    final titleBlock = 34.0 * ts; // room for 2 lines
    final rowH = innerPad + coverH + 8 + titleBlock + innerPad;

    return FutureBuilder<List<Book>>(
      future: repo.moreByAuthor(author),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
        }
        final books = snap.data ?? [];
        if (books.isEmpty) {
          return const SizedBox(height: 60, child: Center(child: Text('No more books found')));
        }

        return SizedBox(
          height: rowH,
          child: ListView.separated(
            padding: const EdgeInsets.only(right: 16),
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final b = books[i];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 260),
                      pageBuilder: (_, a, __) =>
                          FadeTransition(opacity: a, child: BookDetailScreen(book: b)),
                    ),
                  );
                },
                child: Container(
                  width: cardW,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Color(0x143D5CFF), blurRadius: 14, offset: Offset(0, 8)),
                      BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(innerPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AspectRatio(
                            aspectRatio: coverAR,
                            child: (b.thumbnail != null && b.thumbnail!.isNotEmpty)
                                ? Image.network(b.thumbnail!, fit: BoxFit.cover)
                                : Container(color: const Color(0xFFEDEEF3)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: titleBlock,
                          child: Text(
                            b.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F1F39),
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}