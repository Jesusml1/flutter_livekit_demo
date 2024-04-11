import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_livekit/config.dart';
import 'package:flutter_livekit/live.dart';
import 'package:flutter_livekit/models/available_room.dart';
import 'package:flutter_livekit/views/watch_stream_view.dart';
import 'package:livekit_client/livekit_client.dart' as lkclient;

class AvailableRoomsView extends StatefulWidget {
  const AvailableRoomsView({super.key});

  @override
  State<AvailableRoomsView> createState() => _AvailableRoomsViewState();
}

class _AvailableRoomsViewState extends State<AvailableRoomsView> {
  Future<List<AvailableRoom>> getAvailableRoomsFuture = getAvailableRooms();
  bool _busy = false;
  final String url = Config.websocketLivekitServerUrl;

  @override
  void initState() {
    super.initState();
  }

  _join(BuildContext context, String roomName) async {
    if (_busy) {
      return;
    }

    try {
      setState(() {
        _busy = true;
      });

      final token = await generateTokenToJoin(roomName: roomName);
      if (token == null) {
        return;
      }

      final room = lkclient.Room();
      final listener = room.createListener();

      await room.connect(
        url,
        token,
        roomOptions: lkclient.RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultVideoPublishOptions: const lkclient.VideoPublishOptions(
            stream: 'custom_sync_stream_id',
            simulcast: true,
            videoCodec: 'VP8',
            backupVideoCodec: lkclient.BackupVideoCodec(
              enabled: true,
            ),
          ),
          defaultCameraCaptureOptions: lkclient.CameraCaptureOptions(
            maxFrameRate: 30,
            params: lkclient.VideoParametersPresets.h720_169,
          ),
        ),
      );

      if (context.mounted) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => WatchStreamView(room, listener),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('could not join $e');
      }
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shadowColor: Colors.transparent,
      margin: const EdgeInsets.all(8.0),
      child: SizedBox.expand(
        child: FutureBuilder(
          future: getAvailableRoomsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasData) {
              final rooms = snapshot.data;
              if (rooms != null) {
                if (rooms.isEmpty) {
                  return const Center(
                    child: Text('No rooms available'),
                  );
                }
                return ListView.builder(
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return ListTile(
                      title: Text(room.name),
                      subtitle: Text(
                        'connected: ${room.numParticipants.toString()}',
                      ),
                      onTap: _busy ? null : () => _join(context, room.name),
                    );
                  },
                );
              }
            }
            return const Center(
              child: Text('Rooms could not be fetched...'),
            );
          },
        ),
      ),
    );
  }
}
