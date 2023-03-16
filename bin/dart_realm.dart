import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:uuid/uuid.dart';

void main() {
  final data = <String, List<Map<String, dynamic>>>{};

  var handler = webSocketHandler((webSocket) {
    webSocket.stream.listen((message) {
      final decodedMessage = jsonDecode(message);
      final action = decodedMessage['action'];
      final collection = decodedMessage['collection'];
      final payload = decodedMessage['payload'];
      final id = decodedMessage['id'];

      print("action: $action");
      print("collection: $collection");
      print("payload: $payload");
      print("id: $id");

      if (!data.containsKey(collection)) {
        data[collection] = [];
      }

      switch (action) {
        case 'create':
          if (payload is Map<String, dynamic>) {
            final id = Uuid().v4();
            final newPayload = {...payload, 'id': id};
            data[collection]!.add(newPayload);
            webSocket.sink.add(jsonEncode({
              'message': 'Data added to $collection',
              'id': id,
            }));
          } else {
            webSocket.sink.add(jsonEncode({'error': 'Invalid request'}));
          }
          break;
        case 'read':
          var collectionData = data[collection] ?? [];
          webSocket.sink.add(jsonEncode({'data': collectionData}));
          break;
        case 'update':
          if (payload is Map<String, dynamic>) {
            final index =
                data[collection]!.indexWhere((element) => element['id'] == id);
            if (index != -1) {
              data[collection]![index] = {...payload, 'id': id};
              webSocket.sink.add(jsonEncode({
                'message': 'Data updated in $collection',
                'id': data[collection]![index]["id"],
              }));
            } else {
              webSocket.sink
                  .add(jsonEncode({'error': 'Data with ID $id not found'}));
            }
          } else {
            webSocket.sink.add(jsonEncode({'error': 'Invalid request'}));
          }
          break;
        case 'delete':
          final index =
              data[collection]!.indexWhere((element) => element['id'] == id);
          if (index != -1) {
            data[collection]!.removeAt(index);
            webSocket.sink
                .add(jsonEncode({'message': 'Data deleted from $collection'}));
          } else {
            webSocket.sink
                .add(jsonEncode({'error': 'Data with ID $id not found'}));
          }
          break;
        case 'delete_all':
          data[collection]!.clear();
          webSocket.sink.add(
              jsonEncode({'message': 'All data deleted from $collection'}));
          break;

        default:
          webSocket.sink.add(jsonEncode({'error': 'Invalid action'}));
      }
    });
  });

  var cascade = Cascade().add(handler).add(_echoRequest);

  shelf_io.serve(cascade.handler, 'localhost', 3000).then((server) {
    print('Serving at ws://${server.address.host}:${server.port}');
  });
}

Response _echoRequest(Request request) {
  return Response.ok('Request received');
}
