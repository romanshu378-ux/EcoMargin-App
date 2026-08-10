/// Environment-aware API configuration for EcoMargin.
///
/// HOW TO SWITCH ENVIRONMENTS:
///
/// 1. Default (physical device / production cloud):
///    flutter run
///    Connects to: https://eco-margin.onrender.com/api/v1
///
/// 2. Android Emulator (local backend):
///    flutter run --dart-define=TARGET_ENV=emulator
///    Connects to: http://10.0.2.2:8080/api/v1
///
/// 3. Physical device + local LAN backend:
///    flutter run --dart-define=TARGET_ENV=physical --dart-define=DEV_HOST=192.168.x.x
///    Connects to: http://192.168.x.x:8080/api/v1
///
/// 4. Explicit production:
///    flutter run --dart-define=TARGET_ENV=production
///    Connects to: https://eco-margin.onrender.com/api/v1

class AppConfig {
  /// The cloud/production backend URL.
  static const String _productionUrl = 'https://eco-margin.onrender.com/api/v1';

  /// LAN IP of development machine (override via --dart-define=DEV_HOST=x.x.x.x)
  static const String _devPhysicalIp = String.fromEnvironment(
    'DEV_HOST',
    defaultValue: '10.249.36.120',
  );

  /// Target environment – override at build time with:
  /// flutter run --dart-define=TARGET_ENV=emulator
  static const String _targetEnv = String.fromEnvironment(
    'TARGET_ENV',
    defaultValue: 'production', // Default: connect to cloud backend
  );

  static String get baseUrl {
    switch (_targetEnv) {
      case 'emulator':
        return 'http://10.0.2.2:8080/api/v1';
      case 'physical':
        return 'http://$_devPhysicalIp:8080/api/v1';
      case 'production':
      default:
        return _productionUrl;
    }
  }

  static bool get isLocalDev =>
      _targetEnv == 'emulator' || _targetEnv == 'physical';
  static bool get isProduction => _targetEnv == 'production';
}
