enum AppEnvironment { development, staging, production }

class AppConfig {
  static AppEnvironment _env = AppEnvironment.production;

  static void init(AppEnvironment env) => _env = env;

  static String get apiBaseUrl => switch (_env) {
    AppEnvironment.development => 'http://10.0.2.2:8080/api/v1',
    AppEnvironment.staging     => 'https://api-staging.physioconnect.in/api/v1',
    AppEnvironment.production  => 'https://api.physioconnect.in/api/v1',
  };

  static bool get isDebug => _env == AppEnvironment.development;
  static AppEnvironment get env => _env;
}
