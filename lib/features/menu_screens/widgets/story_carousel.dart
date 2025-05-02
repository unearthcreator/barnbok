import 'dart:io'; // Keep for File usage
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart'; // Needed for kIsWeb
import 'package:hive/hive.dart';
import 'package:collection/collection.dart';

import 'package:barnbok/models/card_info.dart';
import 'package:barnbok/repositories/card_data_repository.dart';
import 'package:barnbok/repositories/hive_card_data_repository.dart';
import 'package:barnbok/features/menu_screens/widgets/story_dialog.dart';

class StoryCarousel extends StatefulWidget {
  const StoryCarousel({super.key});

  @override
  State<StoryCarousel> createState() => _StoryCarouselState();
}

class _StoryCarouselState extends State<StoryCarousel> {
  final List<String> _stories = [
     'Item 1', 'Item 2', 'Item 3', 'Item 4', 'Item 5', 'Item 6', 'Item 7',
   ];
  final String _defaultImagePath = 'assets/images/baby_foot_ceramic.jpg';
  late PageController _pageController;
  Orientation? _lastOrientation; // Start as null
  // Initialize with default portrait value
  double _currentViewportFraction = 0.55;

  Future<void>? _initFuture;
  late final CardDataRepository _repository;
  List<CardInfo> _savedCards = [];
  bool _isLoading = true;
  bool _hasError = false;

  // --- FIXED initState ---
  @override
  void initState() {
    super.initState();
    // Initialize PageController with the DEFAULT viewport fraction.
    // Do NOT use MediaQuery or context here.
    _pageController = PageController(
      viewportFraction: _currentViewportFraction, // Use the default value
      initialPage: (_stories.length / 2).floor(),
    );
    _initFuture = _initializeAndLoadData();
    print("initState completed.");
  }
  // --- End FIX ---

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

  Future<void> _loadInitialCardData() async {
     print("StoryCarousel: Loading initial card data...");
     _savedCards = await _repository.getAllCardsSortedByPosition();
     print("StoryCarousel: Loaded ${_savedCards.length} cards.");
  }

  // Correctly placed calculation (no context needed here)
  double _calculateViewportFraction(Orientation orientation) {
    if (kIsWeb) {
      return 0.15;
    } else {
      return orientation == Orientation.landscape ? 0.35 : 0.55;
    }
  }

  // Correctly placed context-dependent logic
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.of(context).orientation; // Safe to use context here
    final newViewportFraction = _calculateViewportFraction(orientation);

    // Check if orientation or viewport fraction actually changed OR if first run
    if (_lastOrientation != orientation || _currentViewportFraction != newViewportFraction) {
       print("didChangeDependencies: Orientation or Viewport change detected.");

      _lastOrientation = orientation; // Update _lastOrientation
      _currentViewportFraction = newViewportFraction; // Update fraction

      // Determine current page robustly
      final currentPage = (_pageController.hasClients && _pageController.position.hasContentDimensions && _pageController.page != null)
                          ? _pageController.page!.round()
                          : (_stories.length / 2).floor();

      final oldPageController = _pageController;

      // Create new controller with CORRECT fraction
      _pageController = PageController(
        viewportFraction: _currentViewportFraction,
        initialPage: currentPage,
      );

      // Clean up old controller safely
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && oldPageController.hasClients && oldPageController != _pageController ) {
          oldPageController.dispose();
          print("Old PageController disposed in didChangeDependencies.");
        }
      });

      // Ensure UI uses the correct fraction, especially for baseCardWidth calculation in build
      setState(() {});
    }
     print("didChangeDependencies completed.");
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onCardTap(int index) async {
     // ... (No changes needed in _onCardTap) ...
      if (_isLoading || _hasError) {
       print("StoryCarousel: Cannot handle tap, repository not ready or error occurred.");
       return;
     }

     print('Card tapped at index: $index');
     try {
       final CardInfo? existingCard = _savedCards.firstWhereOrNull(
         (card) => card.positionIndex == index
       );

       if (existingCard != null) {
         print('Card data already exists for index $index!');
         print('Existing Card Info: $existingCard');
         // TODO: Navigate to the timeline screen, passing existingCard.uniqueId
       } else {
         print('No card data found for index $index. Showing create dialog...');
         final result = await showCreateStoryDialog(context, index);

         if (result == true) {
           print('Create dialog confirmed successful save.');
           if (!mounted) return;
           print("StoryCarousel: Reloading data after save...");
           await _loadInitialCardData();
           if (mounted) {
             setState(() {});
             print("StoryCarousel: Data reloaded, UI should update.");
           }
         } else {
           print('Create dialog cancelled or save failed.');
         }
       }
     } catch (e, stackTrace) {
       print('Error handling card tap for index $index: $e\n$stackTrace');
     }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (_isLoading || snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (_hasError || snapshot.hasError) {
          print("FutureBuilder Error: ${snapshot.error}");
          // Simplified error display for brevity
          return const Center(child: Text('Error loading data', style: TextStyle(color: Colors.red)));
        } else {
          // Main Carousel build
          return SizedBox(
            height: 290.0,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: { PointerDeviceKind.touch, PointerDeviceKind.mouse },
              ),
              child: PageView.builder(
                controller: _pageController, // Use the potentially updated controller
                itemCount: _stories.length,
                itemBuilder: (context, index) {
                  final CardInfo? cardInfo = _savedCards.firstWhereOrNull(
                    (card) => card.positionIndex == index
                  );
                  final String imagePathToShow = cardInfo?.imagePath ?? _defaultImagePath;

                  // Use MediaQuery HERE (safe within build) to get width
                  double availableWidth = MediaQuery.of(context).size.width * _currentViewportFraction;
                  // Adjust multiplier to control how much of the viewport the base card takes
                  double baseCardWidth = availableWidth * 0.85; // Example: 85% of viewport item width

                  return _buildStoryItemContent(
                    imagePathToShow,
                    index,
                    cardInfo,
                    baseCardWidth, // Pass calculated base width
                  );
                },
              ),
            ),
          );
        }
      },
    );
  }

  // --- _buildStoryItemContent method (with conditional image loading) remains the same ---
  Widget _buildStoryItemContent(String imagePath, int index, CardInfo? cardInfo, double baseCardWidth) {
      final bool isAsset = !imagePath.startsWith('/');
      Widget errorFallbackWidget = Container( /* ... */ ); // Keep fallback
      Widget imageWidget;

      if (isAsset) {
        imageWidget = Image.asset(
           imagePath,
           fit: BoxFit.cover,
           errorBuilder: (context, error, stackTrace) {
             print("Error loading asset image: $imagePath, Error: $error");
             if (imagePath != _defaultImagePath) {
               return Image.asset(_defaultImagePath, fit: BoxFit.cover, errorBuilder: (ctx, err, st) => errorFallbackWidget);
             } else { return errorFallbackWidget; }
           },
         );
      } else {
         File imageFile = File(imagePath);
         imageWidget = Image.file(
           imageFile,
           fit: BoxFit.cover,
           errorBuilder: (context, error, stackTrace) {
             print("Error loading file image: $imagePath, Error: $error");
             return Image.asset(_defaultImagePath, fit: BoxFit.cover, errorBuilder: (ctx, err, st) => errorFallbackWidget);
           },
         );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 0.0;
              double cardHeight = 250.0; // Base height
              double animatedCardWidth = baseCardWidth; // Base width for calculation

              if (_pageController.hasClients && _pageController.position.hasContentDimensions && _pageController.page != null) {
                 value = index - _pageController.page!;
                 value = (1 - (value.abs() * 0.3)).clamp(0.8, 1.0);
                 animatedCardWidth = Curves.easeOut.transform(value) * baseCardWidth;
                 cardHeight = Curves.easeOut.transform(value) * cardHeight; // Apply scaling
              } else {
                 value = (index == _pageController.initialPage) ? 1.0 : 0.8;
                 animatedCardWidth = Curves.easeOut.transform(value) * baseCardWidth;
                 cardHeight = Curves.easeOut.transform(value) * cardHeight; // Apply scaling
              }

              return Center(
                child: SizedBox(
                  height: cardHeight,
                  width: animatedCardWidth,
                  child: GestureDetector(
                    onTap: () => _onCardTap(index),
                    child: child,
                  ),
                ),
              );
            },
            child: Card(
              margin: EdgeInsets.symmetric(horizontal: kIsWeb ? 8.0 : 10.0, vertical: 10.0),
              elevation: 4.0,
              clipBehavior: Clip.antiAlias,
              child: imageWidget, // Use the conditional image widget
            ),
          ),
          // --- Conditional Indicator Box (remains the same) ---
          if (cardInfo != null && cardInfo.surname.isNotEmpty) ...[
             const SizedBox(height: 4),
             Container(
               width: baseCardWidth * 0.9, // Use baseCardWidth for consistency
               height: 20,
               padding: const EdgeInsets.symmetric(horizontal: 4.0),
               decoration: BoxDecoration(
                 color: Colors.grey[200],
                 borderRadius: BorderRadius.circular(4),
               ),
               child: Center(
                 child: Text(
                   cardInfo.surname,
                   style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black87, overflow: TextOverflow.ellipsis),
                   textAlign: TextAlign.center,
                 ),
               ),
             ),
           ] else ...[
             const SizedBox(height: 24),
           ],
        ],
      );
    }
}