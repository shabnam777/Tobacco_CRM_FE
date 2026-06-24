const bool isProduction = bool.fromEnvironment('dart.vm.product');

class AppConfig {
  static String get backendUrl {
    if (isProduction) {
      return 'https://tobacco-crm-be.onrender.com';
    }

    return 'http://localhost:8000';
  }
}
