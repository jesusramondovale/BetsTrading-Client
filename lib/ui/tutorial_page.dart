import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../locale/localized_texts.dart';

class TutorialScreen extends StatefulWidget {
  final VoidCallback onDone;

  const TutorialScreen({Key? key, required this.onDone}) : super(key: key);

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> _tutorialPages = [
    {
      "title": "onboarding_title_intro",
      "description": "onboarding_description_intro",
      "image": "assets/new_icon.png",
      "width": "200"
    },
    {
      "title": "onboarding_title_favorites",
      "description": "onboarding_description_favorites",
      "image": "assets/favorites.png",
      "width": "280"
    },
    {
      "title": "onboarding_title_graphs",
      "description": "onboarding_description_graphs",
      "image": "assets/bet_graph.png",
      "width": "240"
    },
    {
      "title": "onboarding_title_confirm_bet",
      "description": "onboarding_description_confirm_bet",
      "image": "assets/make_bet.png",
      "width": "240"
    },
    {
      "title": "onboarding_title_more",
      "description": "onboarding_description_more",
      "image": "assets/and_more.png",
      "width": "420"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Imagen de fondo
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.1),
                BlendMode.darken,
              ),
              child: Image.asset(
                'assets/backgn.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(color: Colors.transparent),
            ),
          ),
          // Contenido principal
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _tutorialPages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final page = _tutorialPages[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.asset(
                            page["image"]!,
                            width:
                                double.tryParse(page["width"] ?? '') ?? 120.0,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              textAlign: TextAlign.center,
                              LocalizedStrings.of(context)
                                      ?.get(page["title"]!) ??
                                  '',
                              style: GoogleFonts.montserrat(
                                fontSize: 36,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueAccent,
                              ),
                            )),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Text(
                            LocalizedStrings.of(context)
                                    ?.get(page["description"]!) ??
                                '',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _tutorialPages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    height: 10,
                    width: _currentIndex == index ? 20 : 10,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? Colors.deepPurple
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                  onPressed: _currentIndex == _tutorialPages.length - 1
                      ? widget.onDone
                      : () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                  child: Text(
                    _currentIndex == _tutorialPages.length - 1
                        ? LocalizedStrings.of(context)
                                ?.get('onboarding_title_get_started') ??
                            'Get Started'
                        : LocalizedStrings.of(context)
                                ?.get('continue') ??
                            'Continue',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }
}
