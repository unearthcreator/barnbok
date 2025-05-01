// lib/models/card_info.dart

import 'package:hive/hive.dart';

// This part directive links this file to the generated adapter file.
// It will likely show an error in your IDE until you run the build_runner command.
part 'card_info.g.dart';

// Annotate the class with @HiveType and provide a unique typeId.
// Each Hive object type needs a unique ID (0, 1, 2, etc.).
@HiveType(typeId: 0)
class CardInfo extends HiveObject { // Extending HiveObject is optional but often useful

  // Annotate each field you want to store with @HiveField and a unique index (0, 1, 2...).
  // These indices must be unique *within this class*.
  @HiveField(0)
  String surname;

  @HiveField(1)
  String lastName;

  @HiveField(2)
  String imagePath; // Stores the path to the user's chosen image

  // Optional field for future backend sync ID
  @HiveField(3)
  String? serverId;

  // Constructor to easily create instances of this class
  CardInfo({
    required this.surname,
    required this.lastName,
    required this.imagePath,
    this.serverId, // Optional, can be null
  });

  // Optional: You might add toJson/fromJson methods later if communicating with a backend API

  // Optional: toString for easier debugging
  @override
  String toString() {
    return 'CardInfo(surname: $surname, lastName: $lastName, imagePath: $imagePath, serverId: $serverId)';
  }
}