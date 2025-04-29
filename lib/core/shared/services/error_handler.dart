import 'dart:async';
import 'package:flutter/foundation.dart';
import 'logger_service.dart';

class ErrorHandler {
  static void initialize() {
    // Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      LoggerService.logError(details.exception, details.stack);
    };

    // Dart errors outside Flutter
    runZonedGuarded(
      () {},
      (error, stackTrace) => LoggerService.logError(error, stackTrace),
    );
  }
}