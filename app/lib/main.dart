import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

const socketUrl = 'ws://api-server-qwkymxmtyq-no.a.run.app/ws';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late WebSocketChannel channel;
  int? counter;

  @override
  void initState() {
    super.initState();
    channel = WebSocketChannel.connect(
      Uri.parse(socketUrl),
    );

    channel.stream
        .listen((value) => setState(() => counter = int.tryParse(value)));
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  void _sendIncrementCommand() {
    channel.sink.add('increment');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              socketUrl,
            ),
            Text(
              counter?.toString() ?? '?',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendIncrementCommand,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
