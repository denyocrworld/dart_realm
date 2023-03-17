import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:uuid/uuid.dart';

void main() {
  final data = <String, List<Map<String, dynamic>>>{};

  Map<String, StreamSubscription?> subscriptions = {};
  Map<String, int> subscriptionsPointerId = {};
  List<Map<String, dynamic>> updateHistories = [];

  final dataController =
      StreamController<Map<String, List<Map<String, dynamic>>>>.broadcast();
  final updateHistoriesController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  var handler = webSocketHandler((webSocket) {
    webSocket.stream.listen((message) async {
      final decodedMessage = jsonDecode(message);
      final action = decodedMessage['action'];
      final collection = decodedMessage['collection'];
      final payload = decodedMessage['payload'];
      final sessionId = decodedMessage['session_id'];
      final int pointerId = decodedMessage['pointer_id'] ?? -1;
      final actionId = decodedMessage['action_id'] ?? -1;
      final id = decodedMessage['id'];

      if (collection != null && !data.containsKey(collection)) {
        data[collection] = [];
      }
      switch (action) {
        case 'create':
          if (payload is Map<String, dynamic>) {
            final id = Uuid().v4();
            final newPayload = {...payload, 'id': id};
            data[collection]!.add(newPayload);
            dataController.add({});

            var obj = {
              "action_id": DateTime.now().microsecondsSinceEpoch,
              "action": action,
              "collection": collection,
              "session_id": sessionId,
              "id": id,
              "payload": payload,
            };
            updateHistories.add(obj);
            updateHistoriesController.add(updateHistories);

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
        case 'snapshot':
          {
            List updates = [];
            print("A. pointerId: $pointerId");
            updates = updateHistories
                .where((i) =>
                    i["collection"] == collection && i['action_id'] > pointerId)
                .toList();

            webSocket.sink.add(jsonEncode({
              'data_count': updates.length,
              'data': updates.isNotEmpty ? [updates.first] : [],
              'first_time': false,
            }));
          }

          // subscriptions[sessionId]?.cancel();
          // subscriptions[sessionId] =
          //     updateHistoriesController.stream.listen((event) {
          //   var updates = [];

          //   var pointerId = subscriptionsPointerId[sessionId] ?? -1;

          //   print("B. pointerId: $pointerId");
          //   updates = updateHistories
          //       .where((i) =>
          //           i["collection"] == collection && i['action_id'] > pointerId)
          //       .toList();

          //   print("SEND UPDATE: ${updates.first}");

          //   webSocket.sink.add(jsonEncode({
          //     'data': updates.isNotEmpty ? [updates.first] : [],
          //     'first_time': false,
          //   }));
          // });
          break;
        case 'pointer_update':
          print("update pointer_id to $actionId");
          subscriptionsPointerId[sessionId] = actionId;
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
