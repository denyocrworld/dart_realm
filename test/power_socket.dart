import 'dart:convert';

import 'package:web_socket_channel/io.dart';

extension IOWebSocketChannelCollectionExtension on Cilukba {
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
    var channel = IOWebSocketChannel.connect('ws://localhost:3000');
    final inputData = {
      'action': 'read',
      'collection': collectionName,
    };
    channel.sink.add(jsonEncode(inputData));
    return channel.stream.map((response) {
      final responseData = jsonDecode(response);
      final List<dynamic>? data = responseData['data'];
      if (data != null) {
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    });
  }

  Future get() async {
    var channel = IOWebSocketChannel.connect('ws://localhost:3000');
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
    var channel = IOWebSocketChannel.connect('ws://localhost:3000');
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
    var channel = IOWebSocketChannel.connect('ws://localhost:3000');
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
    var channel = IOWebSocketChannel.connect('ws://localhost:3000');
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
    var channel = IOWebSocketChannel.connect('ws://localhost:3000');
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

class Cilukba {
  static Cilukba? _instance;
  static IOWebSocketChannel channel =
      IOWebSocketChannel.connect('ws://localhost:3000');

  static Cilukba get instance {
    _instance ??= Cilukba();
    return _instance!;
  }
}
