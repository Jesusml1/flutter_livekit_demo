import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_livekit/constansts/video_device.dart';
import 'package:flutter_livekit/exts.dart';
import 'package:flutter_livekit/widgets/participant_info.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:flutter_livekit/widgets/participant.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class RoomView extends StatefulWidget {
  final Room room;
  final EventsListener<RoomEvent> listener;

  const RoomView(
    this.room,
    this.listener, {
    super.key,
  });

  @override
  State<RoomView> createState() => _RoomViewState();
}

class _RoomViewState extends State<RoomView> {
  List<ParticipantTrack> participantTracks = [];
  EventsListener<RoomEvent> get _listener => widget.listener;
  bool get fastConnection => widget.room.engine.fastConnectOptions != null;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    widget.room.addListener(_onRoomDidUpdate);
    _setUpListeners();
    _sortParticipants();
    WidgetsBindingCompatible.instance?.addPostFrameCallback((timeStamp) {
      if (!fastConnection) {
        _askPublish();
      }
    });

    if (lkPlatformIsMobile()) {
      Hardware.instance.setSpeakerphoneOn(true);
    }

    if (lkPlatformIs(PlatformType.iOS)) {
      if (kDebugMode) {
        print('ios');
      }
    }
  }

  @override
  void dispose() {
    (() async {
      if (lkPlatformIs(PlatformType.iOS)) {
        if (kDebugMode) {
          print('ios');
        }
      }
      widget.room.removeListener(_onRoomDidUpdate);
      await _listener.dispose();
      await widget.room.dispose();
    })();
    WakelockPlus.disable();
    super.dispose();
  }

  void _setUpListeners() => _listener
    ..on<RoomDisconnectedEvent>((event) async {
      if (event.reason != null) {
        print('room disconnected: reason => ${event.reason}');
      }
      WidgetsBindingCompatible.instance?.addPostFrameCallback(
        (timeStamp) => Navigator.popUntil(
          context,
          (route) => route.isFirst,
        ),
      );
    })
    ..on<ParticipantEvent>((event) {
      print('participant event');
      _sortParticipants();
    })
    ..on<RoomRecordingStatusChanged>((event) {
      context.showRecordingStatusChangedDialog(event.activeRecording);
    })
    ..on<RoomAttemptReconnectEvent>((event) {
      print(
        'attemping to reconnect ${event.attempt}/${event.maxAttemptsRetry}'
        '(${event.nextRetryDelaysInMs}ms delay until next attempt)',
      );
    })
    ..on<LocalTrackPublishedEvent>((_) => _sortParticipants())
    ..on<LocalTrackUnpublishedEvent>((_) => _sortParticipants())
    ..on<TrackSubscribedEvent>((_) => _sortParticipants())
    ..on<TrackUnsubscribedEvent>((_) => _sortParticipants())
    ..on<LocalTrackPublishedEvent>((_) => _sortParticipants())
    ..on<ParticipantNameUpdatedEvent>((event) {
      print(
          'participant name updated: ${event.participant.identity}, name => ${event.name}');
      _sortParticipants();
    })
    ..on<ParticipantMetadataUpdatedEvent>((event) {
      print(
        'Participant metadata updated: ${event.participant.identity}'
        'Metadata: ${event.metadata}',
      );
    })
    ..on<RoomMetadataChangedEvent>((event) {
      print('Participant metadata updated: ${event.metadata}');
    })
    ..on<DataReceivedEvent>((event) {
      String decoded = 'Failed to decode';
      try {
        decoded = utf8.decode(event.data);
      } catch (_) {
        print('failed to decode $_');
      }
      context.showDataReceivedDialog(decoded);
    })
    ..on((event) async {
      if (!widget.room.canPlaybackAudio) {
        bool? yesno = await context.showPlayAudioManuallyDialog();
        if (yesno == true) {
          await widget.room.startAudio();
        }
      }
    });

  void _askPublish() async {
    final result = await context.showPublishDialog();
    if (result != true) return;
    try {
      await widget.room.localParticipant?.setCameraEnabled(true);
    } catch (error) {
      if (context.mounted) {
        await context.showErrorDialog(error);
      }
    }
    try {
      await widget.room.localParticipant?.setMicrophoneEnabled(true);
    } catch (e) {
      if (context.mounted) {
        await context.showErrorDialog(e);
      }
    }
  }

  void _onRoomDidUpdate() {
    _sortParticipants();
  }

  void _sortParticipants() {
    List<ParticipantTrack> userMediaTracks = [];
    List<ParticipantTrack> screenTracks = [];
    for (var participant in widget.room.remoteParticipants.values) {
      for (var t in participant.videoTrackPublications) {
        if (t.isScreenShare) {
          screenTracks.add(
            ParticipantTrack(
              participant: participant,
              videoTrack: t.track,
              isScreenShare: true,
            ),
          );
        } else {
          userMediaTracks.add(
            ParticipantTrack(
              participant: participant,
              videoTrack: t.track,
              isScreenShare: false,
            ),
          );
        }
      }
    }

    userMediaTracks.sort((a, b) {
      // loudest speaker first
      if (a.participant.isSpeaking && b.participant.isSpeaking) {
        if (a.participant.audioLevel > b.participant.audioLevel) {
          return -1;
        } else {
          return 1;
        }
      }

      // last spoken at
      final aSpokeAt = a.participant.lastSpokeAt?.microsecondsSinceEpoch ?? 0;
      final bSpokeAt = b.participant.lastSpokeAt?.microsecondsSinceEpoch ?? 0;
      if (aSpokeAt != bSpokeAt) {
        return aSpokeAt > bSpokeAt ? -1 : 1;
      }

      // video on
      if (a.participant.hasVideo != b.participant.hasVideo) {
        return a.participant.hasVideo ? -1 : 1;
      }

      // joinedAt
      return a.participant.joinedAt.microsecondsSinceEpoch -
          b.participant.joinedAt.millisecondsSinceEpoch;
    });

    final localParticipantTracks =
        widget.room.localParticipant?.videoTrackPublications;
    if (localParticipantTracks != null) {
      for (var t in localParticipantTracks) {
        if (t.isScreenShare) {
          if (lkPlatformIs(PlatformType.iOS)) {
            //
          }
        }

        userMediaTracks.add(
          ParticipantTrack(
            participant: widget.room.localParticipant!,
            videoTrack: t.track,
            isScreenShare: false,
          ),
        );
      }
    }

    setState(() {
      participantTracks = [...screenTracks, ...userMediaTracks];
    });
  }

  void changeCamera() async {
    final currentTrack = (participantTracks.first.participant
        .videoTrackPublications.first.track as LocalVideoTrack);
    if (currentTrack.currentOptions.deviceId == VideoDevicesId.backCamera) {
      await (participantTracks.first.participant.videoTrackPublications.first
              .track as LocalVideoTrack)
          .switchCamera(VideoDevicesId.frontCamera);
    } else if (currentTrack.currentOptions.deviceId ==
        VideoDevicesId.frontCamera) {
      await (participantTracks.first.participant.videoTrackPublications.first
              .track as LocalVideoTrack)
          .switchCamera(VideoDevicesId.backCamera);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Streaming now'),
        actions: [
          TextButton(
            onPressed: () async {
              await widget.room.disconnect();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Disconnect'),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: participantTracks.isNotEmpty
                    ? ParticipantWidget.widgetFor(
                        participantTracks.first,
                        showStatsLayer: true,
                      )
                    : Container(),
              )
            ],
          ),
          Positioned(
            right: 10,
            bottom: 50,
            child: ElevatedButton(
              onPressed: changeCamera,
              child: const Text('flip camera'),
            ),
          ),
          // Positioned(
          //   left: 0,
          //   right: 0,
          //   top: 0,
          //   child: SizedBox(
          //     height: 120,
          //     child: ListView.builder(
          //       scrollDirection: Axis.horizontal,
          //       itemCount: math.max(0, participantTracks.length - 1),
          //       itemBuilder: (BuildContext context, int index) => SizedBox(
          //         width: 180,
          //         height: 120,
          //         child: ParticipantWidget.widgetFor(
          //           participantTracks[index + 1],
          //         ),
          //       ),
          //     ),
          //   ),
          // )
        ],
      ),
    );
  }
}
