import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';

import 'power_socket_test.dart';

extension IOWebSocketChannelCollectionExtension on HyperBase {
  ChannelCollection collection(collectionName) {
    return ChannelCollection(
      collectionName: collectionName,
    );
  }
}

class ChannelCollection {
  final String collectionName;
  final String? id;
  ChannelCollection({
    required this.collectionName,
    this.id,
  });

  Stream<List<Map<String, dynamic>>> snapshot() {
    var channel = IOWebSocketChannel.connect(HyperBase.websocketAddress);
    var sessionId = Uuid().v4();
    var pointerId = -1;
    pointerId = mainStorage.get("pointer_id") ?? -1;
    print("pointerId: $pointerId");

    final inputData = {
      'action': 'snapshot',
      'collection': collectionName,
      'session_id': sessionId,
      'pointer_id': pointerId,
    };

    channel.sink.add(jsonEncode(inputData));
    return channel.stream.map((response) {
      final responseData = jsonDecode(response);
      final List<dynamic> data = responseData['data'] ?? [];
      var newPointerId = -1;
      if (data.isNotEmpty) {
        newPointerId = data.last['action_id'] ?? -1;
      }

      if (newPointerId != -1) {
        mainStorage.put("pointer_id", newPointerId);
        channel.sink.add(jsonEncode({
          'action': 'pointer_update',
          'collection': collectionName,
          'session_id': sessionId,
          'action_id': newPointerId,
        }));
      }

      if (data != null) {
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    });
  }

  clean() async {
    await mainStorage.put("pointer_id", -1);
  }

  Future get() async {
    var channel = IOWebSocketChannel.connect(HyperBase.websocketAddress);
    final inputData = {
      'action': 'read',
      'collection': collectionName,
    };
    channel.sink.add(jsonEncode(inputData));
    final response = await channel.stream.first;
    await channel.sink.close();
    final responseData = jsonDecode(response);
    return responseData;
  }

  Future add(Map<String, dynamic> data) async {
    var channel = IOWebSocketChannel.connect(HyperBase.websocketAddress);
    final inputData = {
      'action': 'create',
      'collection': collectionName,
      'payload': data,
    };
    channel.sink.add(jsonEncode(inputData));
    final response = await channel.stream.first;
    final responseData = jsonDecode(response);
    return responseData;
  }

  Future update(Map<String, dynamic> data) async {
    var channel = IOWebSocketChannel.connect(HyperBase.websocketAddress);
    final inputData = {
      'action': 'update',
      'collection': collectionName,
      'id': id,
      'payload': data,
    };
    channel.sink.add(jsonEncode(inputData));
    final response = await channel.stream.first;
    await channel.sink.close();
    final responseData = jsonDecode(response);
    return responseData;
  }

  Future delete() async {
    var channel = IOWebSocketChannel.connect(HyperBase.websocketAddress);
    final inputData = {
      'action': 'delete',
      'collection': collectionName,
      'id': id,
    };
    channel.sink.add(jsonEncode(inputData));
    final response = await channel.stream.first;
    final responseData = jsonDecode(response);
    return responseData;
  }

  Future deleteAll() async {
    var channel = IOWebSocketChannel.connect(HyperBase.websocketAddress);
    final inputData = {
      'action': 'delete_all',
      'collection': collectionName,
    };
    channel.sink.add(jsonEncode(inputData));
    final response = await channel.stream.first;
    await channel.sink.close();
    final responseData = jsonDecode(response);
    return responseData;
  }

  ChannelCollection doc(String id) {
    return ChannelCollection(
      collectionName: collectionName,
      id: id,
    );
  }
}

class HyperBase {
  static HyperBase? _instance;
  static String websocketAddress = 'ws://localhost:3000';

  static HyperBase get instance {
    _instance ??= HyperBase();
    return _instance!;
  }
}
