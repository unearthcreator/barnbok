// lib/repositories/card_data_repository.dart

// Import the data model you'll be working with
import '../models/card_info.dart'; // <-- Adjust this import path based on where your CardInfo class is!

// Define the abstract class (the contract)
abstract class CardDataRepository {

  /// Retrieves the CardInfo for a specific slot index.
  /// Returns null if no data is saved for that slot.
  Future<CardInfo?> getCardInfo(int slotIndex);

  /// Saves or updates the CardInfo for a specific slot index.
  Future<void> saveCardInfo(int slotIndex, CardInfo data);

  // --- Optional methods you might add later ---

  /// Retrieves information for all card slots (e.g., 0 to 6).
  // Future<List<CardInfo?>> getAllCardInfos();

  /// Deletes the information for a specific slot index.
  // Future<void> deleteCardInfo(int slotIndex);

}