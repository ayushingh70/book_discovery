import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  // Pages data (image + text + subtitle)
  final List<Map<String, String>> pages = const [
    {
      "image": "assets/images/onboarding1.png",
      "title": "Numerous free\ntrial courses",
      "subtitle": "Free courses for you to \nfind your way to learning",
    },
    {
      "image": "assets/images/onboarding2.png",
      "title": "Quick and easy\nlearning",
      "subtitle": "Easy and fast learning at any time \nto help you improve skills",
    },
    {
      "image": "assets/images/onboarding3.png",
      "title": "Create your own\nstudy plan",
      "subtitle": "Study according to the plan, \nmake study more motivated",
    },
  ];

  @override
  void initState() {
    super.initState();
    // Precache images to avoid first-frame flicker when swiping
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final p in pages) {
        precacheImage(AssetImage(p["image"]!), context);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentPage < pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Maintain your look, but adapt to device sizes safely
    final size = MediaQuery.of(context).size;
    final pad = MediaQuery.of(context).padding; // status/bottom safe areas
    final ts = MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.2); // avoid overblown text
    final isTall = size.height >= 720;

    // Image target size (keeps your visual weight but becomes responsive)
    final imgSide = isTall ? size.width * 0.58 : size.width * 0.50;

    return Scaffold(
      backgroundColor: Colors.white,
      body: ScrollConfiguration(
        behavior: const _NoGlow(),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Pages
              PageView.builder(
                controller: _controller,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  HapticFeedback.selectionClick(); // gentle haptic
                  setState(() => _currentPage = index);
                },
                itemCount: pages.length,
                itemBuilder: (_, index) {
                  final page = pages[index];
                  return Semantics(
                    label: 'Onboarding page ${index + 1} of ${pages.length}',
                    child: Column(
                      children: [
                        SizedBox(height: isTall ? 80 : 48),
                        // Image
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          child: Image.asset(
                            page["image"]!,
                            width: imgSide,
                            height: imgSide,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: isTall ? 36 : 24),
                        // Title
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            page["title"]!,
                            textAlign: TextAlign.center,
                            textScaleFactor: ts,
                            style: const TextStyle(
                              fontFamily: "Poppins",
                              fontWeight: FontWeight.w700,
                              fontSize: 35,
                              height: 1.2,
                              color: Color(0xFF1F1F39),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Subtitle
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            page["subtitle"]!,
                            textAlign: TextAlign.center,
                            textScaleFactor: ts,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                              fontSize: 20,
                              color: Color(0xFF858597),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Page indicator (centered above buttons)
              Positioned(
                left: 0,
                right: 0,
                bottom: (isTall ? 200 : 176) + pad.bottom,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
                        (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 35 : 15,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? const Color(0xFF3D5CFF)
                            : const Color(0xFFEAEAFF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom CTA area (Next or Sign up / Log in)
              Positioned(
                left: 0,
                right: 0,
                bottom: (isTall ? 120 : 104) + pad.bottom,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _currentPage < pages.length - 1
                        ? SizedBox(
                      key: const ValueKey('next'),
                      width: 350,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3D5CFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _goNext,
                        child: const Text(
                          "Next",
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                        : Row(
                      key: const ValueKey('auth'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 170,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3D5CFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, '/signup');
                            },
                            child: const Text(
                              "Sign up",
                              style: TextStyle(
                                fontFamily: "Poppins",
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 170,
                          height: 56,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(
                                  color: Color(0xFF3D5CFF), width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            child: const Text(
                              "Log in",
                              style: TextStyle(
                                fontFamily: "Poppins",
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Color(0xFF3D5CFF),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Skip
              if (_currentPage != pages.length - 1)
                Positioned(
                  top: 12 + pad.top,
                  right: 12,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      _controller.animateToPage(
                        pages.length - 1,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                        fontSize: 15,
                        color: Color(0xFF858597),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Removes the glow effect on overscroll to keep the clean look
class _NoGlow extends ScrollBehavior {
  const _NoGlow();
  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}