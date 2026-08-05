/// Central app configuration.
///
/// IMPORTANT: set [apiBaseUrl] to where the Flask backend is reachable.
///  * Android emulator  -> http://10.0.2.2:5000
///  * iOS simulator     -> http://127.0.0.1:5000
///  * Physical device   -> http://<your-computer-LAN-IP>:5000
class AppConfig {
  static const String apiBaseUrl = 'http://127.0.0.1:5000';
  static const String apiPrefix = '$apiBaseUrl/api';
}
