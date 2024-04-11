import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static String apiUri = dotenv.get(
    'API_URL',
    fallback: "http://10.0.2.2:3030",
  );
  static String websocketLivekitServerUrl = dotenv.get(
    'WEBSOCKET_LIVEKIT_SERVER_URL',
    fallback: "ws://10.0.2.2:7880",
  );
}
