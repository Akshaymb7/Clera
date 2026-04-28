class AppConfig {
  static const supabaseUrl = 'https://cjfetpevxdtszlalcqgc.supabase.co';
  static const supabaseAnonKey =
      'sb_publishable_8c8KzqOTn1nlv6B9H18okg_bzS7mWJ7';

  // Change to your machine's LAN IP when testing on a real device
  // For emulator use 10.0.2.2 (maps to host localhost)
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://safescanapi-production.up.railway.app/v1',
  );

  // Set via --dart-define=SENTRY_DSN=https://... at build time
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');

  static const environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );
}
