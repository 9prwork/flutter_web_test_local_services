import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

const String API_KEY = "local_services_key";
const String apiUrl =
    "http://127.0.0.1:8765/read"; // change to '/read' for same-origin web hosting

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thai ID Reader',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const CardReaderPage(),
    );
  }
}

class CardReaderPage extends StatefulWidget {
  const CardReaderPage({super.key});

  @override
  State<CardReaderPage> createState() => _CardReaderPageState();
}

class _CardReaderPageState extends State<CardReaderPage> {
  bool _loading = false;
  String? _error;
  CardData? _data;

  Future<void> _readCard() async {
    setState(() {
      _loading = true;
      _error = null;
      _data = null;
    });

    try {
      final resp = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json', 'x-api-key': API_KEY},
      );

      if (resp.statusCode == 200) {
        final j = json.decode(resp.body);
        print("response body ${resp.body}");
        if (j is Map && j['ok'] == true) {
          setState(() {
            _data = CardData.fromJson(Map<String, dynamic>.from(j));
          });
        } else {
          setState(() {
            _error = j is Map && j['error'] != null
                ? j['error'].toString()
                : 'API returned not-ok';
          });
        }
      } else if (resp.statusCode == 401) {
        setState(() {
          _error = 'Unauthorized (check x-api-key)';
        });
      } else {
        setState(() {
          _error =
              'HTTP ${resp.statusCode}: ${resp.reasonPhrase ?? "Unknown error"}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Request failed: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_data == null) {
      return Center(
        child: Text(
          'กดปุ่ม "อ่านบัตร" เพื่อดึงข้อมูลจากเครื่องอ่านบัตร',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    // Show card data
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_data!.photo != null)
            CircleAvatar(
              radius: 64,
              backgroundImage: MemoryImage(_data!.photo!),
              backgroundColor: Colors.grey[200],
            )
          else
            CircleAvatar(radius: 64, child: const Icon(Icons.person, size: 64)),
          const SizedBox(height: 16),
          InfoRow(label: 'CID', value: _data!.cid ?? '-'),
          InfoRow(label: 'ชื่อ (ไทย)', value: _data!.thFullname ?? '-'),
          InfoRow(label: 'Name (EN)', value: _data!.enFullname ?? '-'),
          InfoRow(label: 'วันเกิด', value: _data!.birth ?? '-'),
          InfoRow(label: 'เพศ', value: _data!.gender ?? '-'),
          InfoRow(label: 'ออกโดย', value: _data!.issuer ?? '-'),
          InfoRow(label: 'วันออก', value: _data!.issueDate ?? '-'),
          InfoRow(label: 'วันหมดอายุ', value: _data!.expireDate ?? '-'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'ที่อยู่:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 4),
          Text(_data!.address ?? '-', textAlign: TextAlign.left),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold with a floating action button to trigger read
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thai ID Reader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Read card',
            onPressed: _loading ? null : _readCard,
          ),
        ],
      ),
      body: _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _readCard,
        label: const Text('อ่านบัตร'),
        icon: const Icon(Icons.credit_card),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class CardData {
  final String? cid;
  final String? thFullname;
  final String? enFullname;
  final String? birth;
  final String? gender;
  final String? issuer;
  final String? issueDate;
  final String? expireDate;
  final String? address;
  final Uint8List? photo;

  CardData({
    this.cid,
    this.thFullname,
    this.enFullname,
    this.birth,
    this.gender,
    this.issuer,
    this.issueDate,
    this.expireDate,
    this.address,
    this.photo,
  });

  factory CardData.fromJson(Map<String, dynamic> j) {
    Uint8List? photoBytes;
    try {
      if (j['photo_b64'] != null && (j['photo_b64'] as String).isNotEmpty) {
        photoBytes = base64Decode(j['photo_b64'] as String);
      }
    } catch (_) {
      photoBytes = null;
    }

    return CardData(
      cid: j['cid']?.toString(),
      thFullname: j['th_fullname']?.toString(),
      enFullname: j['en_fullname']?.toString(),
      birth: j['birth']?.toString(),
      gender: j['gender']?.toString(),
      issuer: j['issuer']?.toString(),
      issueDate: j['issue_date']?.toString(),
      expireDate: j['expire_date']?.toString(),
      address: j['address']?.toString(),
      photo: photoBytes,
    );
  }
}
