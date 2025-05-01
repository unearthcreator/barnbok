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
// --- Import the new dialog file ---
import 'package:barnbok/features/menu_screens/widgets/story_dialog.dart';

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
  // Default image path for newly created cards (if needed by dialog)
  // final String _newUserImagePath = 'assets/images/placeholder_user.png'; // Now handled in dialog

  late PageController _pageController;
  Orientation? _lastOrientation;
  double _currentViewportFraction = 0.55;

  // --- Repository and Data Handling ---
  Future<void>? _initFuture;
  late final CardDataRepository _repository;
  List<CardInfo> _savedCards = [];
  bool _isLoading = true;
  bool _hasError = false;
  // --- End Data Handling ---

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: _currentViewportFraction,
      initialPage: (_stories.length / 2).floor(),
    );
    _initFuture = _initializeAndLoadData();
  }

  // --- Combined initialization and data loading function ---
  Future<void> _initializeAndLoadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
       if (!Hive.isBoxOpen(HiveCardDataRepository.boxName)) {
          print("StoryCarousel: Warning - Box was not open. Attempting to open again.");
          await Hive.openBox<CardInfo>(HiveCardDataRepository.boxName);
       }
       final cardInfoBox = Hive.box<CardInfo>(HiveCardDataRepository.boxName);
       _repository = HiveCardDataRepository(cardInfoBox);
       print("StoryCarousel: Repository initialized successfully.");
       await _loadInitialCardData();
       if (mounted) {
         setState(() { _isLoading = false; });
       }
    } catch (e, stackTrace) {
       print("StoryCarousel: FATAL Error initializing/loading data: $e\n$stackTrace");
       if (mounted) {
         setState(() {
           _isLoading = false;
           _hasError = true;
         });
       }
    }
  }
  // --- End Initialization Function ---

  // --- Function to load card data from repository ---
  Future<void> _loadInitialCardData() async {
    print("StoryCarousel: Loading initial card data...");
    _savedCards = await _repository.getAllCardsSortedByPosition();
    print("StoryCarousel: Loaded ${_savedCards.length} cards.");
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
        // TODO: Navigate to the timeline screen, passing existingCard.uniqueId
      } else {
        // Card data NOT FOUND - Show the external dialog
        print('No card data found for index $index. Showing create dialog...');

        // --- Call the external dialog function, passing the index ---
        // Expecting bool? result (true if saved, null/false otherwise)
        final result = await showCreateStoryDialog(context, index);

        // --- Check if the dialog confirmed a successful save ---
        if (result == true) {
           print('Create dialog confirmed successful save.');

           // --- Refresh local data AFTER dialog saved ---
           // Add a slight delay before reloading and setting state
           await Future.delayed(Duration.zero); // Delay to allow dialog dismissal to settle

           if (mounted) { // Check if widget is still mounted after delay
              print("StoryCarousel: Reloading data after save...");
              await _loadInitialCardData(); // Fetch updated list from Hive
              setState(() {}); // Trigger rebuild to show the new indicator
              print("StoryCarousel: Data reloaded, UI should update.");
           }
           // --- End refresh ---
        } else {
           // Dialog was cancelled or save failed within the dialog
           print('Create dialog cancelled or save failed.');
        }
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
          return SizedBox(
            height: 290.0,
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
                     cardInfo,
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

  // --- Updated to accept CardInfo and build indicator with text ---
  Widget _buildStoryItemContent(String imageAssetPath, int index, CardInfo? cardInfo) {
    double baseCardWidth = 250 * 0.6;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // --- Existing Animated Card Structure ---
        AnimatedBuilder(
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
            double animatedCardWidth = Curves.easeOut.transform(value) * baseCardWidth;

            return Center(
              child: SizedBox(
                height: Curves.easeOut.transform(value) * cardHeight,
                width: animatedCardWidth,
                child: GestureDetector(
                  onTap: () => _onCardTap(index),
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
              imageAssetPath, // Use the determined image path
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                 // Log error for the *original* image path attempted
                 print("Error loading image: $imageAssetPath, Error: $error");
                 // Fallback to default image
                 return Image.asset(
                    _defaultImagePath,
                    fit: BoxFit.cover,
                    // Error builder for the fallback image itself
                    errorBuilder: (ctx, err, st) {
                       // Log error for the *fallback* image path
                       print("Error loading fallback image: $_defaultImagePath, Error: $err");
                       // Final fallback: display an icon/placeholder
                       return Container(
                          color: Colors.grey[300],
                          child: Center(child: Icon(Icons.broken_image, color: Colors.grey[600]))
                       );
                    },
                 );
              },
            ),
          ),
        ),
        // --- End Existing Card Structure ---

        // --- Conditional Indicator Box with Text ---
        if (cardInfo != null) ...[
          const SizedBox(height: 4),
          Container(
            width: baseCardWidth * 0.9,
            height: 20,
            padding: const EdgeInsets.symmetric(horizontal: 4.0), // Add padding for text
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            // Add centered text displaying the surname
            child: Center(
              child: Text(
                cardInfo.surname, // Display the surname
                style: const TextStyle(
                  fontSize: 11, // Slightly larger font size
                  fontWeight: FontWeight.w500, // Medium weight
                  color: Colors.black87, // Darker text color
                  overflow: TextOverflow.ellipsis, // Handle long names
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ] else ...[
          // Keep consistent height when no indicator is shown
          const SizedBox(height: 24),
        ],
        // --- End Conditional Indicator Box ---
      ],
    );
  }
}
