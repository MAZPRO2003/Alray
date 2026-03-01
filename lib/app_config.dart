/// App environment configuration.
///
/// Set via the flavor-specific entry points (`main_dev.dart` / `main_prod.dart`).
enum Flavor { dev, prod }

class AppConfig {
  AppConfig._();

  static Flavor _flavor = Flavor.prod; // safe default

  /// Call this once from the flavor-specific entry point before [runApp].
  static void setFlavor(Flavor flavor) {
    _flavor = flavor;
  }

  static Flavor get flavor => _flavor;

  static bool get isDev => _flavor == Flavor.dev;
  static bool get isProd => _flavor == Flavor.prod;

  /// Human-readable app name shown in the title bar / task switcher.
  static String get appName =>
      _flavor == Flavor.dev ? 'Alray Tracker (Dev)' : 'Alray Tracker';
}
