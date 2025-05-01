// lib/repositories/card_data_repository.dart

// Import the data model you'll be working with
import '../models/card_info.dart'; // <-- Adjust path if needed

/// Abstract class defining the contract for managing CardInfo data.
/// Uses a unique String ID as the primary key for storage.
abstract class CardDataRepository {

  /// Retrieves a specific CardInfo object using its unique ID.
  /// Returns null if no data is saved for that unique ID.
  Future<CardInfo?> getCardInfo(String uniqueId);

  /// Saves or updates a CardInfo object.
  /// The object's `uniqueId` field MUST be set and will be used as the storage key.
  Future<void> saveCardInfo(CardInfo data);

  /// Retrieves all saved CardInfo objects, sorted by their `positionIndex`.
  Future<List<CardInfo>> getAllCardsSortedByPosition();

  /// Deletes the CardInfo object associated with the given unique ID.
  Future<void> deleteCardInfo(String uniqueId);

  // Optional: You might add methods for batch operations later
  // Future<void> saveAllCards(List<CardInfo> cards);

}
