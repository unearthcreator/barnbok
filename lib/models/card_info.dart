// lib/models/card_info.dart

import 'package:hive/hive.dart';

// This part directive links this file to the generated adapter file.
// It will likely show an error in your IDE until you run the build_runner command AGAIN.
part 'card_info.g.dart';

// Annotate the class with @HiveType and provide a unique typeId.
// Each Hive object type needs a unique ID (0, 1, 2, etc.).
@HiveType(typeId: 0) // Keep the same typeId unless you have conflicts
class CardInfo extends HiveObject { // Extending HiveObject is optional but often useful

  // --- NEW FIELD: Unique identifier for this specific card record ---
  // This will be used as the primary key in the Hive box.
  @HiveField(0) // Assign the next available field index
  String uniqueId;

  // --- EXISTING FIELDS (Indices shifted due to new field at 0) ---
  @HiveField(1) // Was 0
  String surname;

  @HiveField(2) // Was 1
  String lastName;

  @HiveField(3) // Was 2
  String imagePath; // Stores the path to the user's chosen image

  // --- NEW FIELD: The visual position index (0, 1, 2...) of the card ---
  @HiveField(4) // Assign the next available field index
  int positionIndex;

  // --- Optional field for future backend sync ID (Index shifted) ---
  @HiveField(5) // Was 3
  String? serverId;


  // --- Updated Constructor ---
  // Requires uniqueId and positionIndex now.
  CardInfo({
    required this.uniqueId, // Must provide a unique ID when creating
    required this.surname,
    required this.lastName,
    required this.imagePath,
    required this.positionIndex, // Must provide the position
    this.serverId, // Optional, can be null
  });

  // Optional: You might add toJson/fromJson methods later if communicating with a backend API

  // Optional: toString for easier debugging
  @override
  String toString() {
    return 'CardInfo(uniqueId: $uniqueId, surname: $surname, lastName: $lastName, imagePath: $imagePath, positionIndex: $positionIndex, serverId: $serverId)';
  }
}
