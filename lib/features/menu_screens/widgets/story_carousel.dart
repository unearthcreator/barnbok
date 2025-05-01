import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart'; // Needed for kIsWeb

class StoryCarousel extends StatefulWidget {
  const StoryCarousel({super.key});

  @override
  State<StoryCarousel> createState() => _StoryCarouselState();
}

class _StoryCarouselState extends State<StoryCarousel> {
  // This list still determines the *number* of cards (itemCount)
  // The actual string content isn't used for display anymore in this version.
  final List<String> _stories = [
    'Item 1', // Content doesn't matter if showing the same image
    'Item 2',
    'Item 3',
    'Item 4',
    'Item 5',
    'Item 6',
    'Item 7',
  ];

  // --- The image path we want to display ---
  final String _imagePath = 'assets/images/baby_foot_ceramic.jpg';


  late PageController _pageController;
  Orientation? _lastOrientation;
  double _currentViewportFraction = 0.55;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: _currentViewportFraction,
      initialPage: (_stories.length / 2).floor(), // Centers the 4th item (index 3)
    );
  }

  double _calculateViewportFraction(Orientation orientation) {
    if (kIsWeb) {
      return 0.15;
    } else {
      return orientation == Orientation.landscape ? 0.35 : 0.55;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.of(context).orientation;
    final newViewportFraction = _calculateViewportFraction(orientation);

    if (_lastOrientation != orientation || _currentViewportFraction != newViewportFraction) {
      _lastOrientation = orientation;
      _currentViewportFraction = newViewportFraction;

      final currentPage = (_pageController.hasClients && _pageController.position.hasContentDimensions && _pageController.page != null)
                          ? _pageController.page!.round()
                          : (_stories.length / 2).floor();

      final oldPageController = _pageController;

      _pageController = PageController(
        viewportFraction: _currentViewportFraction,
        initialPage: currentPage,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && oldPageController != _pageController) {
          oldPageController.dispose();
        }
      });

      setState(() {});
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250.0, // You might want to adjust height based on image aspect ratio
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          },
        ),
        child: PageView.builder(
          controller: _pageController,
          itemCount: _stories.length, // Still uses length here
          itemBuilder: (context, index) {
            // Pass the image path and index to the build method
            // The actual string from _stories isn't needed for display now
            return _buildStoryItemContent(_imagePath, index);
          },
        ),
      ),
    );
  }

  // --- MODIFIED build method for the card content ---
  Widget _buildStoryItemContent(String imageAssetPath, int index) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 0.0;
        if (_pageController.hasClients && _pageController.position.hasContentDimensions) {
          value = index - (_pageController.page ?? _pageController.initialPage.toDouble());
          value = (1 - (value.abs() * 0.3)).clamp(0.8, 1.0);
        } else {
          value = index == _pageController.initialPage ? 1.0 : 0.8;
        }

        double cardHeight = 250; // Make sure this fits your image well
        double cardWidth = cardHeight * 0.6; // Adjust aspect ratio if needed

        return Center(
          child: SizedBox(
            height: Curves.easeOut.transform(value) * cardHeight,
            width: Curves.easeOut.transform(value) * cardWidth,
            child: child, // This 'child' is the Card defined below
          ),
        );
      },
      // The child passed to the builder above
      child: Card(
        margin: EdgeInsets.symmetric(
            horizontal: kIsWeb ? 8.0 : 10.0,
            vertical: 10.0
        ),
        elevation: 4.0,
        clipBehavior: Clip.antiAlias, // Good practice for images in cards
        child: Image.asset( // <-- Use Image.asset here
          imageAssetPath, // Use the path passed to the function
          fit: BoxFit.cover, // Makes the image cover the card space
                           // Other options: BoxFit.contain, BoxFit.fill, etc.
        ),
        /* // --- REMOVED the previous Text widget ---
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              storyTitle, // No longer using storyTitle for display
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18.0),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ),
        */
      ),
    );
  }
}