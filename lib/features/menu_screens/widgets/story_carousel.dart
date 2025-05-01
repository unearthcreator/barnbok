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

  // --- Repository and Data Handling ---
  Future<void>? _initFuture; // Combined future for repo and initial data load
  late final CardDataRepository _repository;
  // State variable to hold the loaded card data
  List<CardInfo> _savedCards = [];
  bool _isLoading = true; // Track loading state
  bool _hasError = false; // Track error state
  // --- End Data Handling ---

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: _currentViewportFraction,
      initialPage: (_stories.length / 2).floor(),
    );

    // Start the asynchronous initialization and data loading
    _initFuture = _initializeAndLoadData();
  }

  // --- Combined initialization and data loading function ---
  Future<void> _initializeAndLoadData() async {
    setState(() { // Set loading state
      _isLoading = true;
      _hasError = false;
    });
    try {
       // 1. Initialize Repository
       if (!Hive.isBoxOpen(HiveCardDataRepository.boxName)) {
          print("StoryCarousel: Warning - Box was not open. Attempting to open again.");
          await Hive.openBox<CardInfo>(HiveCardDataRepository.boxName);
       }
       final cardInfoBox = Hive.box<CardInfo>(HiveCardDataRepository.boxName);
       _repository = HiveCardDataRepository(cardInfoBox);
       print("StoryCarousel: Repository initialized successfully.");

       // 2. Load Initial Card Data
       await _loadInitialCardData();

       // 3. Update state: loading finished, no error
       if (mounted) { // Check if widget is still in the tree
         setState(() {
           _isLoading = false;
           _hasError = false;
         });
       }

    } catch (e, stackTrace) {
       print("StoryCarousel: FATAL Error initializing/loading data: $e\n$stackTrace");
       if (mounted) {
         setState(() {
           _isLoading = false;
           _hasError = true; // Set error state
         });
       }
       // Optionally rethrow if needed elsewhere, but FutureBuilder handles it
       // rethrow;
    }
  }
  // --- End Initialization Function ---

  // --- Function to load card data from repository ---
  Future<void> _loadInitialCardData() async {
    print("StoryCarousel: Loading initial card data...");
    _savedCards = await _repository.getAllCardsSortedByPosition();
    print("StoryCarousel: Loaded ${_savedCards.length} cards.");
    // No need for setState here, it's called in _initializeAndLoadData
  }
  // --- End Load Data Function ---


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

      setState(() {});
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- Function to handle card taps ---
  Future<void> _onCardTap(int index) async {
    // Ensure repository is initialized before proceeding
    if (_isLoading || _hasError) {
      print("StoryCarousel: Cannot handle tap, repository not ready or error occurred.");
      return;
    }

    print('Card tapped at index: $index');
    try {
      // Find existing card directly from the loaded state
      final CardInfo? existingCard = _savedCards.firstWhereOrNull(
        (card) => card.positionIndex == index
      );

      if (existingCard != null) {
        // Card data FOUND
        print('Card data already exists for index $index!');
        print('Existing Card Info: $existingCard');
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

        // --- Update local state to reflect the new save ---
        if (mounted) {
          setState(() {
            _savedCards.add(newCardData);
            // Re-sort if necessary, though adding at the end might be fine if positions are unique
            _savedCards.sort((a, b) => a.positionIndex.compareTo(b.positionIndex));
            print("StoryCarousel: Updated local state with new card.");
          });
        }
        // --- End state update ---

        // TODO: Navigate to a screen to edit the new card's details
      }
    } catch (e, stackTrace) {
      print('Error handling card tap for index $index: $e\n$stackTrace');
      // TODO: Show an error message to the user
    }
  }
  // --- End card tap handler ---


  @override
  Widget build(BuildContext context) {
    // Use FutureBuilder to wait for initialization and initial data load
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        // Show loading or error states
        if (_isLoading || snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (_hasError || snapshot.hasError) {
           print("FutureBuilder Error: Failed to initialize/load data: ${snapshot.error}");
           return Center(
             child: Text(
                'Error initializing storage.\nPlease restart the app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[700]),
             ),
           );
        } else {
          // --- Data is ready, build the actual carousel ---
          // Increased height to accommodate potentially taller indicator box + spacing
          return SizedBox(
            height: 290.0, // Increased height: 250 (card) + 4 (space) + 20 (indicator) + ~16 (extra padding)
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
                  // Find the corresponding saved card from the loaded state
                  final CardInfo? cardInfo = _savedCards.firstWhereOrNull(
                    (card) => card.positionIndex == index
                  );

                  // Determine image path: use saved path if available, else default
                  final String imagePathToShow = cardInfo?.imagePath ?? _defaultImagePath;

                  // Pass the found cardInfo (or null) and image path down
                  return _buildStoryItemContent(
                     imagePathToShow,
                     index,
                     cardInfo, // Pass the CardInfo object itself
                  );
                },
              ),
            ),
          );
          // --- End actual carousel build ---
        }
      },
    );
  }

  // --- Updated to accept CardInfo and build indicator ---
  Widget _buildStoryItemContent(String imageAssetPath, int index, CardInfo? cardInfo) {
    // Calculate base card width for indicator sizing
    double baseCardWidth = 250 * 0.6;

    return Column( // Wrap content in a Column
      mainAxisSize: MainAxisSize.min, // Take minimum vertical space needed
      children: [
        // --- Existing Animated Card Structure ---
        AnimatedBuilder(
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
            // Use the same value transformation for width to keep aspect ratio during animation
            double animatedCardWidth = Curves.easeOut.transform(value) * baseCardWidth;

            return Center(
              child: SizedBox(
                height: Curves.easeOut.transform(value) * cardHeight,
                width: animatedCardWidth, // Use animated width
                child: GestureDetector(
                  onTap: () => _onCardTap(index),
                  child: child,
                ),
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
            child: Image.asset(
              imageAssetPath, // Use the determined image path
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                 print("Error loading image: $imageAssetPath, Error: $error");
                 // Use default image if saved one fails? Or a generic placeholder?
                 return Image.asset( // Fallback to default image on error
                    _defaultImagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => Container( // Final fallback
                       color: Colors.grey[300],
                       child: Center(child: Icon(Icons.broken_image, color: Colors.grey[600]))
                    ),
                 );
              },
            ),
          ),
        ),
        // --- End Existing Card Structure ---

        // --- Conditional Indicator Box ---
        if (cardInfo != null) ...[ // Use spread operator for conditional element
          const SizedBox(height: 4), // Add small space
          Container(
            // Use the base card width for the indicator width
            width: baseCardWidth * 0.9, // Approx 90% of base card width
            height: 20, // << INCREASED HEIGHT (was 10)
            decoration: BoxDecoration(
              color: Colors.grey[200], // << CHANGED COLOR (was blueGrey[200])
              borderRadius: BorderRadius.circular(4), // Rounded corners
            ),
            // Later, you can add the surname Text widget inside this container
            // child: Center(child: Text(cardInfo.surname, style: TextStyle(fontSize: 8))),
          ),
        ] else ...[
          // If no cardInfo, add space equivalent to the NEW indicator's height + spacing
          // to prevent layout jumps when cards are saved/deleted.
          const SizedBox(height: 24), // << UPDATED HEIGHT (20 indicator + 4 spacing)
        ],
        // --- End Conditional Indicator Box ---
      ],
    );
  }
}