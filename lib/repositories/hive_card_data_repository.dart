// lib/repositories/hive_card_data_repository.dart

import 'package:hive/hive.dart';
// Using collection package for potential sorting stability, optional but good practice
import 'package:collection/collection.dart';

import '../models/card_info.dart';       // Adjust path as needed
import 'card_data_repository.dart';   // Adjust path as needed

/// Concrete implementation of CardDataRepository using Hive for local storage.
/// Assumes CardInfo objects have a unique `uniqueId` field used as the Hive key,
/// and a `positionIndex` field for ordering.
class HiveCardDataRepository implements CardDataRepository {

  /// The name of the Hive box used to store card information.
  static const String boxName = 'cardDataBox'; // Keep using the same box name

  /// Reference to the opened Hive box.
  /// The box stores CardInfo objects, using their uniqueId (String) as the key.
  final Box<CardInfo> _cardBox;

  /// Constructor requires an opened Box<CardInfo> instance.
  HiveCardDataRepository(this._cardBox);

  /// Retrieves CardInfo from the Hive box using the uniqueId as the key.
  /// Matches the updated interface signature.
  @override
  Future<CardInfo?> getCardInfo(String uniqueId) async {
    // Hive's box.get() is synchronous, but we fulfill the Future-based contract.
    return _cardBox.get(uniqueId);
  }

  /// Saves/updates CardInfo in the Hive box using the object's uniqueId as the key.
  /// Matches the updated interface signature.
  /// Assumes data.uniqueId is a non-null, non-empty string.
  @override
  Future<void> saveCardInfo(CardInfo data) async {
    // Use the uniqueId from the data object itself as the key
    // Ensure uniqueId is not null or empty before putting, or handle error
    if (data.uniqueId.isEmpty) {
       throw ArgumentError('CardInfo uniqueId cannot be empty when saving.');
    }
    await _cardBox.put(data.uniqueId, data);
  }

  /// Retrieves all CardInfo objects from the box and sorts them by positionIndex.
  /// Implements the new interface method.
  @override
  Future<List<CardInfo>> getAllCardsSortedByPosition() async {
    // Get all values currently stored in the box.
    // .values returns an Iterable<CardInfo> containing only non-null objects.
    final List<CardInfo> allCards = _cardBox.values.toList();

    // Sort the list based on the positionIndex field within each CardInfo object.
    allCards.sort((a, b) => compareInt(a.positionIndex, b.positionIndex));
    // Alternative simpler sort if positionIndex is guaranteed non-null:
    // allCards.sort((a, b) => a.positionIndex.compareTo(b.positionIndex));

    return allCards;
  }

  /// Deletes the CardInfo object associated with the given unique ID.
  /// Implements the new interface method.
  @override
  Future<void> deleteCardInfo(String uniqueId) async {
    // Ensure uniqueId is not null or empty before deleting, or handle error
    if (uniqueId.isEmpty) {
       throw ArgumentError('uniqueId cannot be empty when deleting.');
    }
    await _cardBox.delete(uniqueId);
  }

  // Helper function for stable sorting (optional but good practice)
  int compareInt(int a, int b) {
    // Basic comparison
    return a.compareTo(b);
    /* // More robust comparison if needed
    if (a < b) {
      return -1;
    } else if (a > b) {
      return 1;
    } else {
      return 0; // Keep original order if equal (stable sort behavior)
    }
    */
  }
}
