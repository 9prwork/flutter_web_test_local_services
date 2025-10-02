import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final String apiUrl = "http://localhost:8765";
  String message = '';
  final String apiKey = "local_services_key";

  Future<String> checkService() async {
    try {
      final resp = await http.get(Uri.parse("$apiUrl/status"));
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        if (body["ok"] == true) {
          print("Reader connected: ${body['reader']}");
          return " Reader connected: ${body['reader']}";
        } else {
          print("${body['message']}");
          return " ${body['message']}";
        }
      }
      print("Cannot connect to local service");
      return " Cannot connect to local service";
    } catch (e) {
      print("Error: $e");
      return " Error: $e";
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Card Reader Check")),
        body: Column(
          children: [
            Center(
              child: ElevatedButton(
                child: const Text("Check Reader"),
                onPressed: () async {
                  final msg = await checkService();
                  setState(() {
                    message = msg;
                  });
                  // showDialog(
                  //   context: context,
                  //   builder: (_) => AlertDialog(content: Text(msg)),
                  // );
                },
              ),
            ),
            Text('Message API ${message}'),
          ],
        ),
      ),
    );
  }
}
