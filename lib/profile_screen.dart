import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  String email = '';
  String? selectedAvatar;
  List<String> avatars = [];
  bool isLoading = true;
  bool isSaving = false;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _fetchProfile() async {
    final token = await _getToken();
    final headers = {'Authorization': 'Bearer $token'};

    final response = await http.get(Uri.parse("http://127.0.0.1:8000/profile"), headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        email = data['email'];
        _nameController.text = data['name'] ?? '';
        _bioController.text = data['bio'] ?? '';
        selectedAvatar = data['avatar'];
      });
    }

    final avatarRes = await http.get(Uri.parse("http://127.0.0.1:8000/avatars/list"));
    if (avatarRes.statusCode == 200) {
      final data = json.decode(avatarRes.body);
      setState(() {
        avatars = List<String>.from(data['avatars']);
      });
    }

    setState(() => isLoading = false);
  }

  Future<void> _saveProfile() async {
    final token = await _getToken();
    final headers = {'Authorization': 'Bearer $token'};
    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();

    setState(() => isSaving = true);

    // Update name and bio
    await http.put(
      Uri.parse("http://127.0.0.1:8000/profile/update"),
      headers: {
        ...headers,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'name': name, 'bio': bio},
    );

    // Update avatar
    if (selectedAvatar != null) {
      await http.post(
        Uri.parse("http://127.0.0.1:8000/profile/update-avatar"),
        headers: {
          ...headers,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'avatar': selectedAvatar!},
      );
    }

    setState(() => isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (selectedAvatar != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage("http://127.0.0.1:8000/static/avatars/$selectedAvatar"),
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedAvatar,
              items: avatars.map((avatar) {
                return DropdownMenuItem(
                  value: avatar,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage("http://127.0.0.1:8000/static/avatars/$avatar"),
                        radius: 14,
                      ),
                      const SizedBox(width: 10),
                      Text(avatar),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedAvatar = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Choose Avatar'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: 'Bio'),
              maxLines: 2,
            ),
            const SizedBox(height: 30),
            isSaving
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(Icons.save),
              label: const Text("Save"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
