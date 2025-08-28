import 'package:flutter/material.dart';
import '../../../core/books/books_repository.dart'; // SearchFilter

Future<SearchFilter?> showSearchFilterSheet(
    BuildContext context, {
      required List<String> availableCategories,
      List<String> selectedCategories = const [],
      double priceMin = 0,
      double priceMax = 25000,
      double floor = 0,
      double ceil = 25000,

      // new knobs
      String? availability,      // 'any'|'free'|'paid'
      String? printType,         // null|'books'|'magazines'
      String? orderBy,           // null|'relevance'|'newest'
      String? langRestrict,      // null|'en'|'hi'|'es'|...
    }) {
  final selected = Set<String>.from(selectedCategories);
  double tempMin = priceMin;
  double tempMax = priceMax;

  String? avail = availability;   // 'any'|'free'|'paid'
  String? type  = printType;      // null|'books'|'magazines'
  String? sort  = orderBy;        // null|'relevance'|'newest'
  String? lang  = langRestrict;   // null|'en'|'hi'|'es'

  // helper for segmented chips
  Widget seg({
    required String title,
    required List<(String? value, String label)> items,
    required String? current,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F1F39))),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: items.map((it) {
            final v = it.$1; final label = it.$2;
            final isSel = current == v;
            return GestureDetector(
              onTap: () => onChanged(v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFF3D5CFF) : const Color(0xFFF1F2F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(label, style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSel ? Colors.white : const Color(0xFF858597),
                )),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  return showModalBottomSheet<SearchFilter?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final bottom = MediaQuery.of(ctx).viewInsets.bottom;
      // Divisions: one tick ≈ ₹100 to keep it smooth even at 25k range
      final divisions = ((ceil - floor) / 100).round().clamp(1, 400);

      return Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: bottom + 16),
        child: StatefulBuilder(
          builder: (ctx, setModal) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Search Filter',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins', fontSize: 20,
                              fontWeight: FontWeight.w700, color: Color(0xFF1F1F39),
                            )),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx, null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Categories
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Categories', style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F1F39))),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: availableCategories.map((cat) {
                      final isSelected = selected.contains(cat);
                      return GestureDetector(
                        onTap: () => setModal(() {
                          isSelected ? selected.remove(cat) : selected.add(cat);
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF3D5CFF) : const Color(0xFFF1F2F6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(cat, style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF858597),
                          )),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Price
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Price', style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F1F39))),
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF3D5CFF),
                      inactiveTrackColor: const Color(0xFFE1E6FF),
                      thumbColor: const Color(0xFF3D5CFF),
                      overlayColor: const Color(0x333D5CFF),
                      trackHeight: 3,
                    ),
                    child: RangeSlider(
                      values: RangeValues(tempMin, tempMax),
                      min: floor,
                      max: ceil,
                      divisions: divisions,
                      labels: RangeLabels(
                        '₹${tempMin.toStringAsFixed(0)}',
                        '₹${tempMax.toStringAsFixed(0)}',
                      ),
                      onChanged: (v) => setModal(() {
                        tempMin = v.start; tempMax = v.end;
                      }),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('₹${tempMin.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Text('₹${tempMax.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Availability (Any / Free / Paid)
                  seg(
                    title: 'Availability',
                    items: const [
                      ('any', 'Any'),
                      ('free', 'Free'),
                      ('paid', 'Paid'),
                    ],
                    current: avail ?? 'any',
                    onChanged: (v) => setModal(() => avail = v),
                  ),
                  const SizedBox(height: 16),

                  // Type (All / Books / Magazines)
                  seg(
                    title: 'Type',
                    items: const [
                      (null, 'All'),
                      ('books', 'Books'),
                      ('magazines', 'Magazines'),
                    ],
                    current: type,
                    onChanged: (v) => setModal(() => type = v),
                  ),
                  const SizedBox(height: 16),

                  // Sort (Relevance / Newest)
                  seg(
                    title: 'Sort by',
                    items: const [
                      ('relevance', 'Relevance'),
                      ('newest', 'Newest'),
                    ],
                    current: sort ?? 'relevance',
                    onChanged: (v) => setModal(() => sort = v),
                  ),
                  const SizedBox(height: 16),

                  // Language
                  seg(
                    title: 'Language',
                    items: const [
                      (null, 'Any'),
                      ('en', 'EN'),
                      ('hi', 'HI'),
                      ('es', 'ES'),
                    ],
                    current: lang,
                    onChanged: (v) => setModal(() => lang = v),
                  ),

                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(
                            ctx,
                            const SearchFilter(
                              categories: [],
                              priceMin: null,
                              priceMax: null,
                              // clear server-side knobs too
                              orderBy: null,
                              printType: null,
                              langRestrict: null,
                              onlyFree: false,
                              onlyPaid: false,
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: const BorderSide(color: Color(0xFF3D5CFF)),
                        ),
                        child: const Text('Clear', style: TextStyle(
                            color: Color(0xFF3D5CFF), fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(
                              ctx,
                              SearchFilter(
                                categories: selected.toList(),
                                priceMin: tempMin,
                                priceMax: tempMax,
                                orderBy: sort,
                                printType: type,
                                langRestrict: lang,
                                onlyFree: avail == 'free',
                                onlyPaid:  avail == 'paid',
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3D5CFF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Apply Filter',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}