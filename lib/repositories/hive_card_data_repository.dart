// lib/repositories/hive_card_data_repository.dart

import 'package:hive/hive.dart'; // You might use hive_flutter instead/as well
import '../models/card_info.dart';       // Adjust path as needed
import 'card_data_repository.dart';   // Adjust path as needed

/// Concrete implementation of CardDataRepository using Hive for local storage.
class HiveCardDataRepository implements CardDataRepository {

  /// The name of the Hive box used to store card information.
  /// It's good practice to define box names as constants.
  static const String boxName = 'cardDataBox';

  /// Reference to the opened Hive box.
  /// We get this instance rather than opening it here directly.
  final Box<CardInfo> _cardBox;

  /// Constructor requires an opened Box<CardInfo> instance.
  /// This promotes dependency injection and makes testing easier.
  HiveCardDataRepository(this._cardBox) {
     // Optional: You could add a check here to ensure the box is actually open,
     // though typically the injection setup should guarantee this.
     // assert(_cardBox.isOpen, 'The Hive box "$boxName" must be opened before injecting it.');
  }

  /// Retrieves CardInfo from the Hive box using the slotIndex as the key.
  @override
  Future<CardInfo?> getCardInfo(int slotIndex) async {
    // Hive's box.get() is synchronous, but we fulfill the Future-based contract.
    // The 'async' keyword automatically wraps the return value in a Future.
    return _cardBox.get(slotIndex);
  }

  /// Saves/updates CardInfo in the Hive box using the slotIndex as the key.
  @override
  Future<void> saveCardInfo(int slotIndex, CardInfo data) async {
    // Hive's box.put() can return Future<void>, so we await it.
    await _cardBox.put(slotIndex, data);
  }

  // --- Implementation for Optional Methods (if you added them to the interface) ---

  /*
  @override
  Future<List<CardInfo?>> getAllCardInfos() async {
    // Assuming a fixed number of slots, e.g., 7, is desired.
    // If you just want all *existing* entries regardless of index,
    // you could use _cardBox.values.toList(), but that might not
    // match the concept of fixed slots 0-6.
    const int numberOfSlots = 7; // Or get this dynamically if needed
    final List<CardInfo?> allInfos = [];
    for (int i = 0; i < numberOfSlots; i++) {
      allInfos.add(_cardBox.get(i)); // Add entry or null if key doesn't exist
    }
    return allInfos;
  }
  */

  /*
  @override
  Future<void> deleteCardInfo(int slotIndex) async {
    await _cardBox.delete(slotIndex);
  }
  */

}