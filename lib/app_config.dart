import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://cenou-backend.onrender.com';

  static Duration get connectionTimeout => const Duration(seconds: 30);
}