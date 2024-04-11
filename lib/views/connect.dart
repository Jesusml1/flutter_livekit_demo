import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_livekit/views/prejoin.dart';
import 'package:livekit_client/livekit_client.dart';

class ConnectView extends StatefulWidget {
  const ConnectView({super.key});

  @override
  State<ConnectView> createState() => _ConnectViewState();
}

class _ConnectViewState extends State<ConnectView> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (lkPlatformIs(PlatformType.android)) {
      if (kDebugMode) {
        print('cool');
      }
    }
  }

  Future<void> _connect(BuildContext context) async {
    try {
      setState(() {
        _busy = true;
      });
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => const PreJoinView(),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('could not connect $e');
      }
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _busy ? null : () => _connect(context),
          child: const Text('Start live'),
        )
      ],
    );
  }
}
