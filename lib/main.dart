import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_livekit/views/available_rooms_view.dart';
import 'package:flutter_livekit/views/connect.dart';
import 'package:flutter_livekit/views/prejoin.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      title: 'Livekit demo',
      home: const LiveKitDemo(),
    ),
  );
}

class LiveKitDemo extends StatefulWidget {
  const LiveKitDemo({super.key});

  @override
  State<LiveKitDemo> createState() => _LiveKitDemoState();
}

class _LiveKitDemoState extends State<LiveKitDemo> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
            });
          },
          indicatorColor: Colors.blue.shade200,
          selectedIndex: currentPageIndex,
          destinations: const <Widget>[
            NavigationDestination(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.live_tv),
              label: 'Available',
            ),
            NavigationDestination(
              icon: Icon(Icons.cell_tower),
              label: 'Start live',
            ),
          ],
        ),
        appBar: AppBar(
          title: const Text('Livekit Demo'),
        ),
        body: <Widget>[
          Card(
            shadowColor: Colors.transparent,
            margin: const EdgeInsets.all(8.0),
            child: SizedBox.expand(
              child: Center(
                child: Text(
                  'Home page',
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ),
          ),
          const AvailableRoomsView(),
          const PreJoinView(),
        ][currentPageIndex]);
  }
}

class FirstRoute extends StatelessWidget {
  const FirstRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LiveKit demo'),
      ),
      body: const ConnectView(),
    );
  }
}
