import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart'; // Needed for kIsWeb
import 'package:uuid/uuid.dart'; // Import the UUID package
import 'package:hive/hive.dart'; // Import Hive
import 'package:collection/collection.dart'; // Import for firstWhereOrNull

// Adjust these paths according to your project structure
import 'package:barnbok/models/card_info.dart';
import 'package:barnbok/repositories/card_data_repository.dart';
import 'package:barnbok/repositories/hive_card_data_repository.dart';


class StoryCarousel extends StatefulWidget {
  const StoryCarousel({super.key});

  @override
  State<StoryCarousel> createState() => _StoryCarouselState();
}

class _StoryCarouselState extends State<StoryCarousel> {
  // This list still determines the *number* of cards (itemCount)
  final List<String> _stories = [
    'Item 1', 'Item 2', 'Item 3', 'Item 4', 'Item 5', 'Item 6', 'Item 7',
  ];

  // Image paths
  final String _defaultImagePath = 'assets/images/baby_foot_ceramic.jpg';
  final String _newUserImagePath = 'assets/images/placeholder_user.png';

  late PageController _pageController;
  Orientation? _lastOrientation;
  double _currentViewportFraction = 0.55;

  // --- Repository Handling ---
  // Use a Future to track repository initialization
  Future<void>? _initRepoFuture;
  // Repository instance, initialized by the Future
  late final CardDataRepository _repository;
  // --- End Repository Handling ---

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: _currentViewportFraction,
      initialPage: (_stories.length / 2).floor(),
    );

    // Start the asynchronous repository initialization
    _initRepoFuture = _initializeRepository();
  }

  // --- Asynchronous function to initialize the repository ---
  Future<void> _initializeRepository() async {
    try {
       // Ensure the box is open before accessing it
       // Note: Hive.isBoxOpen check might be useful but openBox is idempotent
       if (!Hive.isBoxOpen(HiveCardDataRepository.boxName)) {
          print("StoryCarousel: Warning - Box was not open. Attempting to open again.");
          // This shouldn't ideally happen if main.dart awaits openBox,
          // but as a safeguard:
          await Hive.openBox<CardInfo>(HiveCardDataRepository.boxName);
       }
       final cardInfoBox = Hive.box<CardInfo>(HiveCardDataRepository.boxName);
       // Assign the real repository instance
       _repository = HiveCardDataRepository(cardInfoBox);
       print("StoryCarousel: Repository initialized successfully.");
    } catch (e, stackTrace) {
       print("StoryCarousel: FATAL Error initializing repository: $e\n$stackTrace");
       // Re-throw the error to be caught by the FutureBuilder
       rethrow;
    }
  }
  // --- End Initialization Function ---

  double _calculateViewportFraction(Orientation orientation) {
    if (kIsWeb) {
      return 0.15;
    } else {
      return orientation == Orientation.landscape ? 0.35 : 0.55;
    }
  }

  @override
  void didChangeDependencies() {
    // Resetting page controller logic remains the same
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

      // Trigger rebuild if needed (FutureBuilder will handle repo state)
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Note: We don't typically close the Hive box here,
    // as it's usually managed globally for the app's lifetime.
    super.dispose();
  }

  // --- Function to handle card taps ---
  // Now assumes _repository is initialized because it's only called
  // after the FutureBuilder completes successfully.
  Future<void> _onCardTap(int index) async {
    print('Card tapped at index: $index');

    try {
      print('Checking for existing card data at position $index...');
      final List<CardInfo> allCards = await _repository.getAllCardsSortedByPosition();

      final CardInfo? existingCard = allCards.firstWhereOrNull(
        (card) => card.positionIndex == index
      );

      if (existingCard != null) {
        // Card data FOUND
        print('Card data already exists for index $index!');
        print('Existing Card Info: $existingCard'); // Log existing info
        // TODO: Navigate to the timeline or show details for this card
      } else {
        // Card data NOT FOUND
        print('No card data found for index $index. Creating new entry...');

        final uniqueId = Uuid().v4();
        print('Generated unique ID: $uniqueId');

        final newCardData = CardInfo(
          uniqueId: uniqueId,
          surname: 'Förnamn?',
          lastName: 'Efternamn?',
          imagePath: _newUserImagePath,
          positionIndex: index,
        );

        print('Saving new card data: $newCardData');
        await _repository.saveCardInfo(newCardData);

        print('Successfully saved new card data for index $index with ID $uniqueId!');
        // TODO: Navigate to a screen to edit the new card's details
        // TODO: Consider refreshing the UI to show the new card's image/data
      }
    } catch (e, stackTrace) {
      print('Error handling card tap for index $index: $e\n$stackTrace');
      // TODO: Show an error message to the user
    }
  }
  // --- End card tap handler ---


  @override
  Widget build(BuildContext context) {
    // Use FutureBuilder to wait for repository initialization
    return FutureBuilder(
      future: _initRepoFuture, // The future we defined in initState
      builder: (context, snapshot) {
        // Check connection state
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator while waiting
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // Show an error message if initialization failed
          print("FutureBuilder Error: Failed to initialize repository: ${snapshot.error}");
          return Center(
             child: Text(
                'Error initializing storage.\nPlease restart the app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[700]),
             ),
          );
        } else {
          // --- Repository is ready, build the actual carousel ---
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
                  // TODO: Fetch actual image path based on saved data
                  // This part still needs updating to show saved images,
                  // potentially using another FutureBuilder inside here
                  // or a different state management approach.
                  return _buildStoryItemContent(_defaultImagePath, index);
                },
              ),
            ),
          );
          // --- End actual carousel build ---
        }
      },
    );
  }

  // _buildStoryItemContent remains largely the same, but the GestureDetector
  // is now only active when the FutureBuilder has completed successfully.
  Widget _buildStoryItemContent(String imageAssetPath, int index) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        // Animation logic remains the same
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
            child: GestureDetector( // GestureDetector is here
              onTap: () => _onCardTap(index), // This is now safe to call
              child: child,
            ),
          ),
        );
      },
      child: Card( // Card definition remains the same
        margin: EdgeInsets.symmetric(
            horizontal: kIsWeb ? 8.0 : 10.0,
            vertical: 10.0
        ),
        elevation: 4.0,
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          imageAssetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
             print("Error loading image: $imageAssetPath, Error: $error");
             return Container(
                color: Colors.grey[300],
                child: Center(child: Icon(Icons.broken_image, color: Colors.grey[600]))
             );
          },
        ),
      ),
    );
  }
}

// Dummy Repository is no longer needed as the FutureBuilder handles initialization errors
// class DummyCardDataRepository implements CardDataRepository { ... }
