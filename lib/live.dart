import 'dart:convert';
import 'package:flutter_livekit/config.dart';
import 'package:flutter_livekit/models/available_room.dart';
import 'package:http/http.dart' as http;
// import 'package:livekit_client/livekit_client.dart';

// Future<Room?> connectToRoom() async {
//   const cameraCaptureOptions = CameraCaptureOptions(
//     cameraPosition: CameraPosition.front,
//     maxFrameRate: 30,
//     params: VideoParametersPresets.h360_169,
//   );

//   const roomOptions = RoomOptions(
//     adaptiveStream: true,
//     dynacast: true,
//     defaultCameraCaptureOptions: cameraCaptureOptions,
//     defaultVideoPublishOptions: VideoPublishOptions(
//       stream: 'custom_sync_stream_id',
//       simulcast: true,
//       videoCodec: 'VP8',
//       backupVideoCodec: BackupVideoCodec(enabled: true),
//     ),
//   );

//   final room = Room(roomOptions: roomOptions);

//   final tokenResponse = await http.get(
//     Uri.parse('http://10.0.2.2:3030/getPublisherToken'),
//   );

//   if (tokenResponse.statusCode == 200) {
//     final token = tokenResponse.body;

//     await room.connect(
//       url,
//       token,
//     );

//     try {
//       await room.localParticipant?.setCameraEnabled(
//         true,
//         cameraCaptureOptions: cameraCaptureOptions,
//       );

//       var localVideo = await LocalVideoTrack.createCameraTrack(
//         cameraCaptureOptions,
//       );
//       await room.localParticipant?.publishVideoTrack(localVideo);
//     } catch (error) {
//       print('Could not publish video, error: $error');
//       return null;
//     }

//     await room.localParticipant?.setMicrophoneEnabled(true);
//     return room;
//   }
//   return null;
// }

// Future<Room?> subscribeToRoom() async {
//   const roomOptions = RoomOptions(
//     adaptiveStream: true,
//     dynacast: true,
//   );

//   final room = Room(roomOptions: roomOptions);
//   final tokenResponse = await http.get(
//     Uri.parse('http://10.0.2.2:3030/getSubscriberToken'),
//   );

//   if (tokenResponse.statusCode == 200) {
//     final token = tokenResponse.body;

//     await room.connect(
//       url,
//       token,
//     );

//     return room;
//   }
//   return null;
// }

Future<String?> generateToken({required String username}) async {
  try {
    final tokenResponse = await http.get(
      Uri.parse('${Config.apiUri}/generate-token?username=$username'),
    );
    if (tokenResponse.statusCode == 200) {
      return tokenResponse.body;
    }
    return null;
  } catch (e) {
    return null;
  }
}

Future<List<AvailableRoom>> getAvailableRooms() async {
  try {
    final response = await http.get(
      Uri.parse('${Config.apiUri}/get-available-rooms'),
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['rooms'] != null) {
        final rooms = body['rooms'] as List<dynamic>;
        return rooms.map((item) => AvailableRoom.fromJson(item)).toList();
      }
    }
    return [];
  } catch (e) {
    return [];
  }
}

Future<String?> generateTokenToJoin({required String roomName}) async {
  try {
    final tokenResponse = await http.get(
      Uri.parse('${Config.apiUri}/generate-token-to-join?room=$roomName'),
    );
    if (tokenResponse.statusCode == 200) {
      return tokenResponse.body;
    }
    return null;
  } catch (e) {
    return null;
  }
}
