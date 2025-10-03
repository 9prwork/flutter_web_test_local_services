import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

const String API_KEY = "local_services_key";
const String apiUrl = "http://127.0.0.1:8765/read";

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
  Map<String, dynamic>? _data;
  Uint8List? _photo;

  // controllers
  final cidController = TextEditingController();
  final thNameController = TextEditingController();
  final enNameController = TextEditingController();
  final birthController = TextEditingController();
  final genderController = TextEditingController();
  final issuerController = TextEditingController();
  final issueController = TextEditingController();
  final expireController = TextEditingController();
  final addressController = TextEditingController();

  final houseNoController = TextEditingController();
  final mooController = TextEditingController();
  final tambonController = TextEditingController();
  final amphoeController = TextEditingController();
  final provinceController = TextEditingController();
  final zipcodeController = TextEditingController();

  @override
  void dispose() {
    cidController.dispose();
    thNameController.dispose();
    enNameController.dispose();
    birthController.dispose();
    genderController.dispose();
    issuerController.dispose();
    issueController.dispose();
    expireController.dispose();
    addressController.dispose();

    houseNoController.dispose();
    mooController.dispose();
    tambonController.dispose();
    amphoeController.dispose();
    provinceController.dispose();
    zipcodeController.dispose();
    super.dispose();
  }

  Future<void> _readCard() async {
    setState(() {
      _loading = true;
      _error = null;
      _data = null;
      _photo = null;
    });

    try {
      final resp = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json', 'x-api-key': API_KEY},
      );

      if (resp.statusCode == 200) {
        final j = json.decode(resp.body);
        if (j is Map && j['ok'] == true) {
          setState(() {
            _data = Map<String, dynamic>.from(j);
            // Photo
            if (j['photo_b64'] != null &&
                (j['photo_b64'] as String).isNotEmpty) {
              _photo = base64Decode(j['photo_b64']);
            }

            // set controllers
            cidController.text = j['cid'] ?? '';
            thNameController.text = j['th_fullname'] ?? '';
            enNameController.text = j['en_fullname'] ?? '';
            birthController.text = j['birth'] ?? '';
            genderController.text = j['gender'] ?? '';
            issuerController.text = j['issuer'] ?? '';
            issueController.text = j['issue_date'] ?? '';
            expireController.text = j['expire_date'] ?? '';
            addressController.text = j['address'] ?? '';

            // address
            addressController.text = j['address'] ?? '';
            if (j['address_parsed'] != null) {
              houseNoController.text = j['address_parsed']['house_no'] ?? '';
              mooController.text = j['address_parsed']['moo'] ?? '';
              tambonController.text = j['address_parsed']['tambon'] ?? '';
              amphoeController.text = j['address_parsed']['amphoe'] ?? '';
              provinceController.text = j['address_parsed']['province'] ?? '';
              zipcodeController.text = j['address_parsed']['zipcode'] ?? '';
            }
          });
        } else {
          setState(() {
            _error = j['error']?.toString() ?? 'API returned not-ok';
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
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null)
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );

    if (_data == null) {
      return const Center(
        child: Text('กดปุ่ม "อ่านบัตร" เพื่อดึงข้อมูลจากเครื่องอ่านบัตร'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_photo != null)
            CircleAvatar(radius: 64, backgroundImage: MemoryImage(_photo!))
          else
            const CircleAvatar(radius: 64, child: Icon(Icons.person, size: 64)),
          const SizedBox(height: 16),
          InfoRow(label: 'CID', controller: cidController),
          InfoRow(label: 'ชื่อ (ไทย)', controller: thNameController),
          InfoRow(label: 'Name (EN)', controller: enNameController),
          InfoRow(label: 'วันเกิด', controller: birthController),
          InfoRow(label: 'เพศ', controller: genderController),
          InfoRow(label: 'ออกโดย', controller: issuerController),
          InfoRow(label: 'วันออก', controller: issueController),
          InfoRow(label: 'วันหมดอายุ', controller: expireController),
          // const SizedBox(height: 8),
          // Align(
          //   alignment: Alignment.centerLeft,
          //   child: Text(
          //     'ที่อยู่:',
          //     style: Theme.of(context).textTheme.titleMedium,
          //   ),
          // ),
          // const SizedBox(height: 4),
          // TextField(
          //   controller: addressController,
          //   maxLines: null,
          //   decoration: const InputDecoration(
          //     isDense: true,
          //     contentPadding: EdgeInsets.all(8),
          //     border: OutlineInputBorder(),
          //   ),
          // ),
          InfoRow(label: 'บ้านเลขที่', controller: houseNoController),
          InfoRow(label: 'หมู่', controller: mooController),
          InfoRow(label: 'ตำบล/แขวง', controller: tambonController),
          InfoRow(label: 'อำเภอ/เขต', controller: amphoeController),
          InfoRow(label: 'จังหวัด', controller: provinceController),
          InfoRow(label: 'รหัสไปรษณีย์', controller: zipcodeController),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thai ID Reader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
  final TextEditingController controller;

  const InfoRow({super.key, required this.label, required this.controller});

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
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 8,
                ),
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
