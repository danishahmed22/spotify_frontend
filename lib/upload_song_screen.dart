import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'nav_screen.dart';

class UploadSongScreen extends StatefulWidget {
  const UploadSongScreen({super.key});

  @override
  State<UploadSongScreen> createState() => _UploadSongScreenState();
}

class _UploadSongScreenState extends State<UploadSongScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _artist = TextEditingController();
  final _duration = TextEditingController();
  final _category = TextEditingController();
  final _album = TextEditingController();

  File? _pickedFile;
  Uint8List? _pickedBytes;
  String? _pickedFilename;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio, withData: true);
    if (result != null && result.files.single.name != null) {
      if (kIsWeb) {
        _pickedBytes = result.files.single.bytes;
        _pickedFilename = result.files.single.name;
      } else {
        final file = File(result.files.single.path!);
        final appDir = await getApplicationDocumentsDirectory();
        final newPath = "${appDir.path}/${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}";
        _pickedFile = await file.copy(newPath);
      }
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Picked: ${result.files.single.name}")));
    }
  }

  Future<void> _uploadSong() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    if ((!kIsWeb && _pickedFile == null) || (kIsWeb && _pickedBytes == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select an audio file")));
      return;
    }

    setState(() => _isUploading = true);

    final token = (await SharedPreferences.getInstance()).getString('token');
    final uri = Uri.parse("http://127.0.0.1:8000/songs/upload");

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['title'] = _title.text
      ..fields['artist'] = _artist.text
      ..fields['duration'] = _duration.text
      ..fields['category'] = _category.text
      ..fields['album'] = _album.text;

    if (kIsWeb) {
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        _pickedBytes!,
        filename: _pickedFilename,
      ));
    } else {
      request.files.add(await http.MultipartFile.fromPath('file', _pickedFile!.path));
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Upload successful")));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NavScreen()),
        );
      } else {
        print("❌ Upload failed: $responseBody");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['detail'] ?? "Upload failed")));
      }
    } catch (e) {
      print("❌ Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Widget _buildTextField(TextEditingController ctrl, String label, {bool isNumber = false, bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (value) => (value == null || value.isEmpty) ? "Required" : null
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Song")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.folder),
                label: const Text("Pick Audio File"),
              ),
              const SizedBox(height: 10),
              if (_pickedFilename != null || _pickedFile != null)
                Text(
                  "Selected: ${_pickedFilename ?? _pickedFile!.path.split('/').last}",
                  style: const TextStyle(color: Colors.green),
                ),
              const SizedBox(height: 20),
              _buildTextField(_title, "Title"),
              _buildTextField(_artist, "Artist"),
              _buildTextField(_duration, "Duration (seconds)", isNumber: true),
              _buildTextField(_category, "Category", required: false),
              _buildTextField(_album, "Album", required: false),
              const SizedBox(height: 30),
              _isUploading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _uploadSong,
                child: const Text("Upload"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
