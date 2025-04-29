import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart'; // Needed for kIsWeb

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
  Orientation? _lastOrientation;
  // Initialize with a sensible default, will be corrected in didChangeDependencies
  double _currentViewportFraction = 0.55;

  @override
  void initState() {
    super.initState();
    // --- CORRECTED initState ---
    // Initialize controller with default values ONLY.
    // DO NOT use MediaQuery.of(context) here.
    _pageController = PageController(
      viewportFraction: _currentViewportFraction, // Use default fraction initially
      initialPage: (_stories.length / 2).floor(),
    );
    // The correct fraction based on platform/orientation will be set
    // in the first call to didChangeDependencies.
  }

  // Helper function remains the same
  double _calculateViewportFraction(Orientation orientation) {
    if (kIsWeb) {
      return 0.25; // Adjust as needed for web
    } else {
      return orientation == Orientation.landscape ? 0.35 : 0.55;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // This method IS the correct place to access MediaQuery
    final orientation = MediaQuery.of(context).orientation;
    final newViewportFraction = _calculateViewportFraction(orientation);

    // Check if orientation OR platform (implicitly via fraction) changes
    // This condition will be TRUE on the first run after initState because:
    // - _lastOrientation is null initially.
    // - OR _currentViewportFraction (default 0.55) might differ from newViewportFraction.
    if (_lastOrientation != orientation || _currentViewportFraction != newViewportFraction) {

      // Store the current state
      _lastOrientation = orientation;
      _currentViewportFraction = newViewportFraction;

      // Determine the page to jump to (try to keep current, else reset)
      // Check if the controller is attached and has a valid page first
      final currentPage = (_pageController.hasClients && _pageController.position.hasContentDimensions && _pageController.page != null)
                           ? _pageController.page!.round()
                           : (_stories.length / 2).floor(); // Fallback to initialPage

      // Dispose the old controller *before* creating the new one IF IT EXISTS AND HAS CLIENTS
      // (Check hasClients to avoid issues if dispose is called before it's fully attached)
      // A safer pattern is often to dispose in the next frame (as shown before),
      // but simple disposal here might work if the state change handles it cleanly.
      // Let's revert to the safer post-frame disposal just in case.
      final oldPageController = _pageController;

      // Create the new controller with updated fraction and correct initial page
      _pageController = PageController(
        viewportFraction: _currentViewportFraction,
        initialPage: currentPage, // Use determined page
      );

      // Safely dispose the old controller after the frame build
       WidgetsBinding.instance.addPostFrameCallback((_) {
         // Check if it's the same object in case didChangeDependencies runs rapidly
         if (mounted && oldPageController != _pageController) {
            oldPageController.dispose();
         }
       });


      // No explicit setState needed here if the build method only reads _pageController,
      // as the controller instance itself changes. However, if other parts of build
      // depend on _currentViewportFraction or _lastOrientation, setState is needed.
      // To be safe and ensure AnimatedBuilder updates correctly with the NEW controller:
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
    // The build method remains largely the same
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
          controller: _pageController, // Uses the latest controller instance
          itemCount: _stories.length,
          itemBuilder: (context, index) {
            return _buildStoryItemContent(_stories[index], index);
          },
        ),
      ),
    );
  }

  // _buildStoryItemContent remains the same
  Widget _buildStoryItemContent(String storyTitle, int index) {
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

        double cardHeight = 250;
        double cardWidth = cardHeight * 0.6;

        return Center(
          child: SizedBox(
            height: Curves.easeOut.transform(value) * cardHeight,
            width: Curves.easeOut.transform(value) * cardWidth,
            child: child,
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.symmetric(
            horizontal: kIsWeb ? 8.0 : 10.0,
            vertical: 10.0
        ),
        elevation: 4.0,
        clipBehavior: Clip.antiAlias,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              storyTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18.0),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ),
      ),
    );
  }
}