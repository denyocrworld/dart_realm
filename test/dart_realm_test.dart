import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:web_socket_channel/io.dart';

void main() async {
  String lastestCreatedId = "";

  test('Delete all products from collection', () async {
    // Start WebSocket server
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 3000);
    final channel = IOWebSocketChannel.connect('ws://localhost:3000');

    // Send delete all message
    final deleteAllMessage = {
      'action': 'delete_all',
      'collection': 'products',
    };
    channel.sink.add(jsonEncode(deleteAllMessage));

    // Wait for server response
    final response = await channel.stream.first;
    final responseData = jsonDecode(response);
    expect(responseData['message'], equals('All data deleted from products'));

    // Close WebSocket connection and server
    channel.sink.close();
    await server.close();
  });

  test('Add product to collection', () async {
    // Start WebSocket server
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 3000);
    final channel = IOWebSocketChannel.connect('ws://localhost:3000');

    // Send create message to add product to collection
    final inputData = {
      'action': 'create',
      'collection': 'products',
      'payload': {
        'product_name': 'GG FILTER 12',
        'price': 25,
      },
    };
    channel.sink.add(jsonEncode(inputData));

    // Wait for server response
    final response = await channel.stream.first;
    final responseData = jsonDecode(response);
    expect(responseData['message'], equals('Data added to products'));

    print(responseData["id"]);
    lastestCreatedId = responseData["id"];
    // Close WebSocket connection and server
    channel.sink.close();
    await server.close();
  });

  test('Update product in collection', () async {
    // Start WebSocket server
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 3000);
    final channel = IOWebSocketChannel.connect('ws://localhost:3000');

    // Add product to collection
    final inputData = {
      'action': 'update',
      'collection': 'products',
      'id': lastestCreatedId,
      'payload': {
        'product_name': 'SK KRETEK UPDATED 12',
        'price': 25,
      },
    };
    channel.sink.add(jsonEncode(inputData));

    // Wait for server response
    final response = await channel.stream.first;
    final responseData = jsonDecode(response);
    expect(responseData['message'], equals('Data updated in products'));

    // Close WebSocket connection and server
    channel.sink.close();
    await server.close();
  });

  test('Delete product from collection', () async {
    // Start WebSocket server
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 3000);
    final channel = IOWebSocketChannel.connect('ws://localhost:3000');

    // Send delete message to remove product from collection
    final deleteMessage = {
      'action': 'delete',
      'collection': 'products',
      'id': lastestCreatedId,
    };
    channel.sink.add(jsonEncode(deleteMessage));

    // Wait for server response
    final response = await channel.stream.first;
    final responseData = jsonDecode(response);
    expect(responseData['message'], equals('Data deleted from products'));

    // Close WebSocket connection and server
    channel.sink.close();
    await server.close();
  });

  test('Test fetching data from products collection', () async {
    // Start WebSocket server
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 3000);
    final channel = IOWebSocketChannel.connect('ws://localhost:3000');

    final message = jsonEncode({
      'action': 'read',
      'collection': 'products',
    });

    channel.sink.add(message);

    await channel.stream.firstWhere((event) {
      final response = jsonDecode(event);
      return response['data'] != null;
    }).then((event) {
      final response = jsonDecode(event);
      expect(response['data'], isNotNull);
    }, onError: (error) {
      fail('Error occured: $error');
    });

    channel.sink.close();
    await server.close();
  });
}
