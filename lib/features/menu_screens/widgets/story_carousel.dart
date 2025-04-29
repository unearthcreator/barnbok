// lib/features/menu_screens/widgets/story_carousel.dart

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // Needed for PointerDeviceKind

class StoryCarousel extends StatefulWidget {
  const StoryCarousel({super.key});

  @override
  State<StoryCarousel> createState() => _StoryCarouselState();
}

class _StoryCarouselState extends State<StoryCarousel> {
  final List<String> _stories = [
    'Story 1: The Brave Knight',
    'Story 2: The Lost Astronaut',
    'Story 3: The Magical Forest',
    'Story 4: The Clever Fox',
    'Story 5: The Flying Pig',
  ];

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250.0,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          },
        ),
        child: PageView.builder(
          controller: _pageController,
          itemCount: _stories.length,
          itemBuilder: (context, index) {
            return _buildStoryItemContent(_stories[index], index);
          },
        ),
      ),
    );
  }

  Widget _buildStoryItemContent(String storyTitle, int index) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 0.0;
        if (_pageController.position.haveDimensions) {
          value = index - (_pageController.page ?? 0);
          value = (1 - (value.abs() * 0.3)).clamp(0.8, 1.0);
        } else {
          value = index == 0 ? 1.0 : 0.8;
        }

        return Center(
          child: SizedBox(
            height: Curves.easeOut.transform(value) * 250,
            width: Curves.easeOut.transform(value) *
                MediaQuery.of(context).size.width *
                0.75,
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        elevation: 4.0,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              storyTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18.0),
            ),
          ),
        ),
      ),
    );
  }
}
