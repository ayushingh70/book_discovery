import 'package:flutter/material.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/contacts/presentation/contacts_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

class _NavColors {
  static const primary  = Color(0xFF3D5CFF); // active blue
  static const inactive = Color(0xFFCDD1E0); // inactive grey
  static const barBg    = Color(0xFFFFFFFF); // whole bar
  static const searchBg = Color(0xFFEFF2FF); // light grey/blue bubble
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _current = 0;

  final _screens = const [
    HomeScreen(),
    AnalyticsScreen(),
    SearchScreen(),
    ContactsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    const double barHeight   = 88;  // white rounded bar
    const double scoopRadius = 40;  // the white “scoop” radius
    const double bubbleSize  = 56;  // the light Search circle

    return Scaffold(
      body: _screens[_current],
      bottomNavigationBar: SizedBox(
        height: barHeight + 28 + bottom, // bar + “Search” label + safe inset
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // White rounded bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: barHeight + bottom,
                padding: EdgeInsets.only(bottom: bottom),
                decoration: const BoxDecoration(
                  color: _NavColors.barBg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x11000000),
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    )
                  ],
                ),
              ),
            ),

            // The “scoop”
            Positioned(
              bottom: barHeight - scoopRadius - 12 + bottom,
              child: Container(
                width: scoopRadius * 2,
                height: scoopRadius * 2,
                decoration: const BoxDecoration(
                  color: _NavColors.barBg,
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Row
            Positioned(
              left: 0,
              right: 0,
              bottom: 8 + bottom,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    label: 'Home',
                    asset: 'assets/icons/home.png',
                    selected: _current == 0,
                    onTap: () => setState(() => _current = 0),
                  ),
                  _NavItem(
                    label: 'Analytics',
                    asset: 'assets/icons/analytics.png',
                    selected: _current == 1,
                    onTap: () => setState(() => _current = 1),
                  ),
                  const SizedBox(width: 72), // gap under the center bubble
                  _NavItem(
                    label: 'Contacts',
                    asset: 'assets/icons/contacts.png',
                    selected: _current == 3,
                    onTap: () => setState(() => _current = 3),
                  ),
                  _NavItem(
                    label: 'Profile',
                    asset: 'assets/icons/profile.png',
                    selected: _current == 4,
                    onTap: () => setState(() => _current = 4),
                  ),
                ],
              ),
            ),

            // The Search bubble (light grey)
            Positioned(
              bottom: barHeight - bubbleSize * 0.70 + bottom,
              child: GestureDetector(
                onTap: () => setState(() => _current = 2),
                child: Container(
                  width: bubbleSize,
                  height: bubbleSize,
                  decoration: BoxDecoration(
                    color: _NavColors.searchBg,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 6)),
                    ],
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Center(
                    child: _TintedPng(
                      'assets/icons/search.png',
                      fixedColor: _NavColors.primary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),

            // Search
            Positioned(
              bottom: 16 + bottom,
              child: GestureDetector(
                onTap: () => setState(() => _current = 2),
                child: Text(
                  'Search',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: _current == 2 ? FontWeight.w600 : FontWeight.w500,
                    color: _current == 2 ? _NavColors.primary : _NavColors.inactive,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final String asset;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? _NavColors.primary : _NavColors.inactive;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TintedPng(asset, size: 22, fixedColor: color),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TintedPng extends StatelessWidget {
  final String asset;
  final double size;
  final Color? fixedColor;
  const _TintedPng(this.asset, {this.size = 22, this.fixedColor});

  @override
  Widget build(BuildContext context) {
    final color = fixedColor ?? IconTheme.of(context).color;
    return ImageIcon(AssetImage(asset), size: size, color: color);
  }
}