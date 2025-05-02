import 'dart:io'; // Keep for File usage
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart'; // Needed for kIsWeb
import 'package:hive/hive.dart';
import 'package:collection/collection.dart';

import 'package:barnbok/models/card_info.dart';
import 'package:barnbok/repositories/card_data_repository.dart';
import 'package:barnbok/repositories/hive_card_data_repository.dart';
import 'package:barnbok/features/menu_screens/widgets/story_dialog.dart'; // Ensure this path is correct

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
  Orientation? _lastOrientation;
  double _currentViewportFraction = 0.55;

  Future<void>? _initFuture;
  late final CardDataRepository _repository;
  List<CardInfo> _savedCards = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: _currentViewportFraction,
      initialPage: (_stories.length / 2).floor(),
    );
    _initFuture = _initializeAndLoadData();
    print("initState completed.");
  }

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
       print("didChangeDependencies: Orientation or Viewport change detected.");

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
        if (mounted && oldPageController.hasClients && oldPageController != _pageController ) {
          oldPageController.dispose();
          print("Old PageController disposed in didChangeDependencies.");
        }
      });

      setState(() {});
    }
     print("didChangeDependencies completed.");
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- Handler for TAPPING a card ---
  Future<void> _onCardTap(int index) async {
    if (_isLoading || _hasError) {
      print("StoryCarousel: Cannot handle tap, repository not ready.");
      return;
    }
    print('Card tapped at index: $index');

    final CardInfo? existingCard = _savedCards.firstWhereOrNull(
      (card) => card.positionIndex == index
    );

    if (existingCard != null) {
      // --- TAP on EXISTING card ---
      print('Existing card tapped. Navigating to timeline (TODO)...');
      print('Existing Card Info: $existingCard');
      // TODO: Navigate to the timeline screen, passing existingCard.uniqueId
    } else {
      // --- TAP on EMPTY card ---
      print('Empty card tapped. Showing create dialog...');
      // Call dialog in CREATE mode (no existingCard passed)
      final result = await showCreateStoryDialog(context, index); // No existingCard

      if (result == true) {
        print('Create dialog successful.');
        if (!mounted) return;
        print("Reloading data...");
        await _loadInitialCardData();
        if (mounted) {
          setState(() {});
          print("Data reloaded.");
        }
      } else {
        print('Create dialog cancelled or failed.');
      }
    }
  }

  // --- NEW: Handler for LONG PRESSING a card ---
  Future<void> _onCardLongPress(CardInfo cardToEdit) async {
      if (_isLoading || _hasError) {
        print("StoryCarousel: Cannot handle long press, repository not ready.");
        return;
      }
      print('Card long pressed at index: ${cardToEdit.positionIndex}. Showing edit dialog...');
      print('Card to Edit Info: $cardToEdit');

      // Call dialog in EDIT mode, passing the existing card
      final result = await showCreateStoryDialog(
        context,
        cardToEdit.positionIndex, // Pass index just in case dialog needs it
        existingCard: cardToEdit,  // <-- Pass the card data for editing
      );

      if (result == true) {
        print('Edit dialog successful.');
        if (!mounted) return;
        print("Reloading data after edit...");
        await _loadInitialCardData(); // Reload data to reflect changes
        if (mounted) {
          setState(() {}); // Rebuild UI
          print("Data reloaded.");
        }
      } else {
        print('Edit dialog cancelled or failed.');
      }
    }
  // --- End NEW Handler ---


  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (_isLoading || snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (_hasError || snapshot.hasError) {
          print("FutureBuilder Error: ${snapshot.error}");
          return const Center(child: Text('Error loading data', style: TextStyle(color: Colors.red)));
        } else {
          return SizedBox(
            height: 290.0,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: { PointerDeviceKind.touch, PointerDeviceKind.mouse },
              ),
              child: PageView.builder(
                controller: _pageController,
                itemCount: _stories.length,
                itemBuilder: (context, index) {
                  final CardInfo? cardInfo = _savedCards.firstWhereOrNull(
                    (card) => card.positionIndex == index
                  );
                  final String imagePathToShow = cardInfo?.imagePath ?? _defaultImagePath;
                  double availableWidth = MediaQuery.of(context).size.width * _currentViewportFraction;
                  double baseCardWidth = availableWidth * 0.85;

                  // Pass all necessary info down, including cardInfo for long press check
                  return _buildStoryItemContent(
                    imagePathToShow,
                    index,
                    cardInfo, // Pass the potential card info
                    baseCardWidth,
                  );
                },
              ),
            ),
          );
        }
      },
    );
  }


   // --- CORRECTED _buildStoryItemContent method ---
  Widget _buildStoryItemContent(String imagePath, int index, CardInfo? cardInfo, double baseCardWidth) {
    final bool isAsset = !imagePath.startsWith('/'); // Basic check for asset vs file path
    Widget errorFallbackWidget = Container(
        color: Colors.grey[300],
        child: Center(child: Icon(Icons.broken_image, color: Colors.grey[600]))
    );

    // Define the actual image widget conditionally
    Widget imageWidget;
    if (isAsset) {
      // Use Image.asset for asset paths
      imageWidget = Image.asset( // <-- Was previously /* ... */
        imagePath, // Pass the asset path string
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("Error loading asset image: $imagePath, Error: $error");
          // Fallback to default asset *if* the failed asset wasn't already the default
          if (imagePath != _defaultImagePath) {
            return Image.asset(
              _defaultImagePath,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, st) {
                 print("Error loading fallback asset image: $_defaultImagePath, Error: $err");
                 return errorFallbackWidget; // Final fallback
              },
            );
          } else {
             return errorFallbackWidget; // Already failed on default
          }
        },
      );
    } else {
      // Use Image.file for file paths
      File imageFile = File(imagePath);
      imageWidget = Image.file( // <-- Was previously /* ... */
        imageFile, // Pass the File object
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("Error loading file image: $imagePath, Error: $error");
          // Fallback to default ASSET image if file loading fails
          return Image.asset(
             _defaultImagePath,
             fit: BoxFit.cover,
             errorBuilder: (ctx, err, st) {
                print("Error loading fallback asset image: $_defaultImagePath, Error: $err");
                return errorFallbackWidget; // Final fallback
             },
           );
        },
      );
    }

    // --- Build the Column structure ---
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
             // ... (Animation logic remains the same) ...
               double value = 0.0;
               double cardHeight = 250.0;
               double animatedCardWidth = baseCardWidth;

               if (_pageController.hasClients && _pageController.position.hasContentDimensions && _pageController.page != null) {
                  value = index - _pageController.page!;
                  value = (1 - (value.abs() * 0.3)).clamp(0.8, 1.0);
                  animatedCardWidth = Curves.easeOut.transform(value) * baseCardWidth;
                  cardHeight = Curves.easeOut.transform(value) * cardHeight;
               } else {
                  value = (index == _pageController.initialPage) ? 1.0 : 0.8;
                  animatedCardWidth = Curves.easeOut.transform(value) * baseCardWidth;
                  cardHeight = Curves.easeOut.transform(value) * cardHeight;
               }

            return Center(
              child: SizedBox(
                height: cardHeight,
                width: animatedCardWidth,
                child: GestureDetector(
                  onTap: () => _onCardTap(index),
                  // Only enable long press if cardInfo exists
                  onLongPress: cardInfo != null ? () => _onCardLongPress(cardInfo) : null,
                  child: child,
                ),
              ),
            );
          },
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: kIsWeb ? 8.0 : 10.0, vertical: 10.0),
            elevation: 4.0,
            clipBehavior: Clip.antiAlias,
            // --- Use the correctly created imageWidget ---
            child: imageWidget,
          ),
        ),
        // --- Conditional Indicator Box (remains the same) ---
        if (cardInfo != null && cardInfo.surname.isNotEmpty) ...[
            const SizedBox(height: 4),
             Container(
               width: baseCardWidth * 0.9,
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
  // --- End CORRECTED _buildStoryItemContent method ---
}

// Helper extension for safety (if not already defined elsewhere)
// extension IterableExtensions<E> on Iterable<E> {
//   E? firstWhereOrNull(bool Function(E element) test) {
//     for (E element in this) {
//       if (test(element)) return element;
//     }
//     return null;
//   }
// }