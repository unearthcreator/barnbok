import 'package:logger/logger.dart';

class LoggerService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(),
  );

  static void logInfo(String message) => _logger.i(message);
  static void logWarning(String message) => _logger.w(message);
  static void logError(Object error, [StackTrace? stackTrace]) {
    _logger.e('Error occurred', error: error, stackTrace: stackTrace);
  }
}