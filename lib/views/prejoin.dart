import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_livekit/config.dart';
import 'package:flutter_livekit/live.dart';
import 'package:flutter_livekit/views/room.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:webrtc_interface/webrtc_interface.dart' as webrtc;

class PreJoinView extends StatefulWidget {
  const PreJoinView({super.key});

  @override
  State<PreJoinView> createState() => _PreJoinViewState();
}

class _PreJoinViewState extends State<PreJoinView> {
  final String url = Config.websocketLivekitServerUrl;

  final _tokenCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  bool simulcast = true;
  bool adaptiveStream = true;
  bool dynacast = true;
  String preferredCodec = 'VP8';
  bool enableBackupVideoCodec = true;

  List<MediaDevice> _audioInputs = [];
  List<MediaDevice> _videoInputs = [];
  StreamSubscription? _subscription;

  bool _busy = false;
  bool _enableVideo = true;
  bool _enableAudio = true;
  LocalAudioTrack? _audioTrack;
  LocalVideoTrack? _videoTrack;

  MediaDevice? _selectedVideoDevice;
  MediaDevice? _selectedAudioDevice;
  final VideoParameters _selectedVideoParameters =
      VideoParametersPresets.h720_169;

  @override
  void initState() {
    super.initState();
    _subscription =
        Hardware.instance.onDeviceChange.stream.listen(_loadDevices);
    Hardware.instance.enumerateDevices().then(_loadDevices);
  }

  void _loadDevices(List<MediaDevice> devices) async {
    _audioInputs = devices.where((d) => d.kind == 'audioinput').toList();
    _videoInputs = devices.where((d) => d.kind == 'videoinput').toList();

    if (_audioInputs.isNotEmpty && _selectedAudioDevice == null) {
      _selectedAudioDevice = _audioInputs.first;
      Future.delayed(const Duration(microseconds: 100), () async {
        await _changeLocalAudioTrack();
        setState(() {});
      });
    }

    if (_videoInputs.isNotEmpty && _selectedVideoDevice == null) {
      _selectedVideoDevice = _videoInputs.first;
      Future.delayed(const Duration(microseconds: 100), () async {
        await _changeLocalVideoTrack();
        setState(() {});
      });
    }
  }

  Future<void> _setEnableVideo(value) async {
    _enableVideo = value;
    if (!_enableVideo) {
      await _videoTrack?.stop();
    } else {
      await _changeLocalVideoTrack();
    }
    setState(() {});
  }

  Future<void> _setEnableAudio(value) async {
    _enableAudio = value;
    if (!_enableAudio) {
      await _audioTrack?.stop();
    } else {
      await _changeLocalAudioTrack();
    }
    setState(() {});
  }

  Future<void> _changeLocalAudioTrack() async {
    if (_audioTrack != null) {
      await _audioTrack!.stop();
      _audioTrack = null;
    }

    if (_selectedAudioDevice != null) {
      _audioTrack = await LocalAudioTrack.create(
        AudioCaptureOptions(
          deviceId: _selectedAudioDevice!.deviceId,
        ),
      );
      await _audioTrack!.start();
    }
  }

  Future<void> _changeLocalVideoTrack() async {
    if (_videoTrack != null) {
      await _videoTrack!.stop();
      _videoTrack = null;
    }

    if (_selectedVideoDevice != null) {
      _videoTrack = await LocalVideoTrack.createCameraTrack(
        CameraCaptureOptions(
          deviceId: _selectedVideoDevice!.deviceId,
          params: _selectedVideoParameters,
        ),
      );
      await _videoTrack!.start();
    }
  }

  _generateToken() async {
    if (_usernameCtrl.text.isNotEmpty) {
      final token = await generateToken(username: _usernameCtrl.text);
      if (token != null) {
        _tokenCtrl.text = token;
      }
    } else {
      print('empty field');
    }
  }

  _join(BuildContext context) async {
    try {
      if (_tokenCtrl.text.isEmpty) {
        return;
      }
      setState(() {
        _busy = true;
      });

      final room = Room();
      final listener = room.createListener();
      var token = _tokenCtrl.text;

      await room.connect(
        url,
        token,
        roomOptions: RoomOptions(
          adaptiveStream: adaptiveStream,
          dynacast: dynacast,
          defaultVideoPublishOptions: VideoPublishOptions(
            stream: 'custom_sync_stream_id',
            simulcast: simulcast,
            videoCodec: preferredCodec,
            backupVideoCodec: BackupVideoCodec(
              enabled: enableBackupVideoCodec,
            ),
          ),
          defaultCameraCaptureOptions: CameraCaptureOptions(
            maxFrameRate: 30,
            params: _selectedVideoParameters,
          ),
        ),
        fastConnectOptions: FastConnectOptions(
          microphone: TrackOption(track: _audioTrack),
          camera: TrackOption(track: _videoTrack),
        ),
      );

      if (context.mounted) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => RoomView(room, listener),
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
  void dispose() {
    _subscription?.cancel();
    _tokenCtrl.dispose();
    super.dispose();
  }

  void actionBack(BuildContext context) async {
    await _setEnableVideo(false);
    await _setEnableAudio(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre join'),
      ),
      body: Container(
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 25),
                  child: TextField(
                    decoration: const InputDecoration(hintText: 'username'),
                    controller: _usernameCtrl,
                  ),
                ),
                ElevatedButton(
                  onPressed: _generateToken,
                  child: const Text('Generate token'),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 25),
                  child: TextField(
                    enabled: false,
                    decoration: const InputDecoration(hintText: 'token'),
                    controller: _tokenCtrl,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: 320,
                    height: 240,
                    child: Container(
                      alignment: Alignment.center,
                      color: Colors.black54,
                      child: _videoTrack != null
                          ? VideoTrackRenderer(
                              _videoTrack!,
                              fit: webrtc.RTCVideoViewObjectFit
                                  .RTCVideoViewObjectFitContain,
                                  mirrorMode: VideoViewMirrorMode.off,
                            )
                          : Container(
                              alignment: Alignment.center,
                              child: LayoutBuilder(
                                builder: (ctx, constrains) => Icon(
                                  Icons.videocam_off,
                                  color: Colors.blue,
                                  size: math.min(
                                        constrains.maxHeight,
                                        constrains.maxWidth,
                                      ) *
                                      0.3,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Row(
                    children: [
                      Icon(Icons.flip_camera_android),
                      SizedBox(width: 15),
                      Text('Flip camera'),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _busy ? null : () => _join(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_busy)
                        const Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: SizedBox(
                            height: 15,
                            width: 15,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      const Text('Join'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
