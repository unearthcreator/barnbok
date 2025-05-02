// lib/models/card_info.dart

import 'package:hive/hive.dart';

part 'card_info.g.dart'; // Link to generated adapter

@HiveType(typeId: 0)
class CardInfo extends HiveObject {

  @HiveField(0)
  String uniqueId;

  @HiveField(1)
  String surname; // First name remains required

  // --- CHANGE HERE: Make lastName nullable ---
  @HiveField(2)
  String? lastName; // Changed from String to String?

  @HiveField(3)
  String imagePath;

  @HiveField(4)
  int positionIndex;

  @HiveField(5)
  String? serverId;


  // --- Constructor Update ---
  CardInfo({
    required this.uniqueId,
    required this.surname,
    // --- CHANGE HERE: Allow lastName to be null ---
    this.lastName, // No longer strictly required to be non-null, but still required parameter in constructor call (can pass null or empty string)
    required this.imagePath,
    required this.positionIndex,
    this.serverId,
  });

  // Optional: Update toString for easier debugging with nullable lastName
  @override
  String toString() {
    return 'CardInfo(uniqueId: $uniqueId, surname: $surname, lastName: ${lastName ?? "N/A"}, imagePath: $imagePath, positionIndex: $positionIndex, serverId: $serverId)';
  }
}