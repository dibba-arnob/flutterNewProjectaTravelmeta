abstract class AppConstants {
  // ─── Identity ────────────────────────────────────────────
  static const String appName    = 'TravelMeta';
  static const String appTagline = 'Your World, Your Journey';
  static const String appVersion = '1.0.0';

  // ─── Locale & formatting ─────────────────────────────────
  static const String defaultLocale       = 'en';
  static const String defaultCurrency     = 'BDT';
  static const String currencySymbol      = '৳';
  static const String defaultCountryCode  = '+880';
  static const String dateFormat          = 'dd/MM/yyyy';

  static const List<String> supportedLocales = ['en', 'bn', 'ar', 'zh', 'hi'];

  // ─── Network ─────────────────────────────────────────────
  static const String apiBaseUrl       = 'https://api.travelmeta.app/v1';
  static const int    apiTimeoutSecs   = 30;
  static const int    apiMaxRetries    = 3;

  // ─── Storage keys ────────────────────────────────────────
  static const String boxAuth    = 'auth_box';
  static const String boxPrefs   = 'prefs_box';
  static const String boxCache   = 'cache_box';

  static const String keyAuthToken     = 'auth_token';
  static const String keyRefreshToken  = 'refresh_token';
  static const String keyUserId        = 'user_id';
  static const String keyThemeMode     = 'theme_mode';
  static const String keyLocale        = 'locale';
  static const String keyCurrency      = 'currency';
  static const String keyHasOnboarded  = 'has_onboarded';
  static const String keyBiometric     = 'biometric_enabled';

  // ─── Pagination ──────────────────────────────────────────
  static const int pageSize            = 20;
  static const int prefetchThreshold  = 3;   // items from end before next fetch

  // ─── Cache TTLs (seconds) ────────────────────────────────
  static const int cacheTtlFlight = 300;   // 5 min
  static const int cacheTtlHotel  = 600;   // 10 min
  static const int cacheTtlGuide  = 1800;  // 30 min

  // ─── Animation durations (ms) ────────────────────────────
  static const int animFast   = 150;
  static const int animNormal = 300;
  static const int animSlow   = 500;
  static const int animXSlow  = 800;

  // ─── Booking status tokens ───────────────────────────────
  static const String statusUpcoming   = 'upcoming';
  static const String statusCompleted  = 'completed';
  static const String statusCancelled  = 'cancelled';
  static const String statusPending    = 'pending';
  static const String statusRefund     = 'refund';

  // ─── Destinations ────────────────────────────────────────
  static const List<String> destinations = [
    "Cox's Bazar", 'Sundarbans', 'Sylhet',
    'Saint Martin', 'Sajek Valley', 'Bandarban', 'Kuakata',
  ];

  // ─── Airlines ────────────────────────────────────────────
  static const Map<String, String> airlines = {
    'BG': 'Biman Bangladesh',
    'BS': 'US-Bangla Airlines',
    'VQ': 'NovoAir',
  };

  // ─── Airports ────────────────────────────────────────────
  static const Map<String, String> airports = {
    'DAC': 'Dhaka — Hazrat Shahjalal',
    'CGP': 'Chittagong — Shah Amanat',
    'ZYL': 'Sylhet — Osmani',
    'JSR': 'Jashore',
  };

  // ─── Trains ──────────────────────────────────────────────
  static const List<String> trains = [
    'Sundarban Express', 'Sonar Bangla Express',
    'Parabat Express',   'Mohanagar Provati',
  ];

  // ─── Stations ────────────────────────────────────────────
  static const List<String> stations = [
    'Kamalapur', 'Chittagong', 'Sylhet', 'Rajshahi', 'Khulna',
  ];

  // ─── Payment methods ─────────────────────────────────────
  static const List<String> paymentMethods = [
    'bKash', 'Nagad', 'Rocket', 'DBBL Nexus',
    'Visa', 'Mastercard', 'Google Pay', 'Apple Pay', 'PayPal',
  ];

  // ─── Loyalty tiers (min points) ──────────────────────────
  static const Map<String, int> loyaltyTiers = {
    'Bronze':   0,
    'Silver':   500,
    'Gold':     2000,
    'Platinum': 5000,
  };
}