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
      "image": "assets/logo_simple.png",
      "width" : "200"
    },
    {
      "title": "onboarding_title_favorites",
      "description": "onboarding_description_favorites",
      "image": "assets/favorites.png",
      "width" : "280"
    },
    {
      "title": "onboarding_title_graphs",
      "description": "onboarding_description_graphs",
      "image": "assets/bet_graph.png",
      "width" : "240"
    },
    {
      "title": "onboarding_title_confirm_bet",
      "description": "onboarding_description_confirm_bet",
      "image": "assets/make_bet.png",
      "width" : "240"
    },
    {
      "title": "onboarding_title_more",
      "description": "onboarding_description_more",
      "image": "assets/and_more.png",
      "width" : "420"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
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
                        width: double.tryParse(page["width"] ?? '') ?? 120.0,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      LocalizedStrings.of(context)?.getMessage(page["title"]!) ?? '',
                      style: GoogleFonts.roboto(
                        fontSize: 30,
                        fontWeight: FontWeight.w100,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        LocalizedStrings.of(context)?.getMessage(page["description"]!) ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
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
                  color: _currentIndex == index ? Colors.deepPurple : Colors.grey,
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
                    ? LocalizedStrings.of(context)?.getMessage('onboarding_title_get_started') ?? 'Get Started'
                    : LocalizedStrings.of(context)?.getMessage('continue') ?? 'Continue',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
