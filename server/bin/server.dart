import 'dart:io';

import 'package:redis/redis.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final _clients = <WebSocketChannel>[];
late final RedisConnection conn;
late final Command command;

late final RedisConnection pubSubConn;
late final Command pubSubCommand;
late final PubSub pubSub;

// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/echo/<message>', _echoHandler)
  ..get('/ws', webSocketHandler(_handler));

Response _rootHandler(Request req) {
  return Response.ok('Hello, Boring Show!\n');
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

void _handler(WebSocketChannel webSocket) {
  _clients.add(webSocket);
  command.send_object(['GET', 'counter']).then((value) {
    webSocket.sink.add(value.toString());
  });
  stdout.writeln('[CONNCETED] $webSocket');
  webSocket.stream.listen(
    (dynamic message) async {
      stdout.writeln('[RECEIVED] $message');
      if (message == 'increment') {
        final newValue = await command.send_object(['INCR', 'counter']);
        command.send_object(['PUBLISH', 'counterUpdate', 'counter']);
        for (final client in _clients) {
          client.sink.add(newValue.toString());
        }
      }
    },
    onDone: () {
      _clients.remove(webSocket);
    },
  );
}

void main(List<String> args) async {
  conn = RedisConnection();
  command = await conn.connect('10.174.77.35', 6379);

  pubSubConn = RedisConnection();
  pubSubCommand = await pubSubConn.connect('10.174.77.35', 6379);
  pubSub = PubSub(pubSubCommand);
  pubSub.subscribe(['counterUpdate']);

  pubSub.getStream().handleError((e) => print('error $e')) //
      .listen((message) async {
    print(message);
    final newValue = await command.send_object(['GET', 'counter']);
    for (final client in _clients) {
      client.sink.add(newValue.toString());
    }
  });

  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final _handler = Pipeline() //
      .addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(_handler, ip, port);
  print('Server listening on port ${server.port}');
}
