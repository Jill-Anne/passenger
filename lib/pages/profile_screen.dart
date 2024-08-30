import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false; // Flag to track whether the password is visible or not
  String? _profileImageUrl;
  File? _profileImage; // Local profile image file

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users").child(user.uid);
      DatabaseEvent event = await userRef.once();
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> userData = event.snapshot.value as Map<dynamic, dynamic>;
        _nameController.text = userData['name'] ?? '';
        _phoneController.text = userData['phone'] ?? '';
        _emailController.text = userData['email'] ?? '';
        
        // Load existing profile image URL if available
        _profileImageUrl = userData['profileImageUrl'];
        setState(() {}); // Update the UI
      }
    }
  }

  Future<void> _updateUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users").child(user.uid);

      Map<String, String> updatedData = {
        "name": _nameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "email": _emailController.text.trim(),
      };

      if (_passwordController.text.trim().isNotEmpty) {
        await user.updatePassword(_passwordController.text.trim());
      }

      if (_profileImage != null) {
        String profileImageUrl = await _uploadImageToFirebase(_profileImage!);
        updatedData['profileImageUrl'] = profileImageUrl;
      }

      userRef.update(updatedData).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $error')),
        );
      });
    }
  }

  Future<String> _uploadImageToFirebase(File image) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String fileName = user.uid; // Use user UID as the file name
      Reference storageRef = FirebaseStorage.instance.ref().child('profileImages/$fileName');
      UploadTask uploadTask = storageRef.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    }
    return '';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color.fromARGB(255, 15, 27, 90),
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Color.fromARGB(255, 15, 27, 90),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             Center(
  child: Stack(
    children: [
      Container(
        width: 105,  // Slightly larger to accommodate the border
        height: 105, // Slightly larger to accommodate the border
        decoration: BoxDecoration(
          color: Colors.white, // Background color for the container
          shape: BoxShape.circle, // Ensures the border is circular
          border: Border.all(
            color: Color.fromARGB(255, 32, 2, 87), // Border color
            width: 4, // Border width
          ),
        ),
        child: ClipOval(
          child: _profileImage != null
              ? Image.file(
                  _profileImage!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                )
              : Image.network(
                  _profileImageUrl == null || _profileImageUrl!.isEmpty
                      ? "https://firebasestorage.googleapis.com/v0/b/passenger-signuplogin.appspot.com/o/avatarman.png?alt=media&token=11c39289-3c10-4355-9537-9003913dbeef"
                      : _profileImageUrl!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: InkWell(
          onTap: _pickImage,
          child: const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.camera_alt, color: Colors.grey),
          ),
        ),
      ),
    ],
  ),
),

              const SizedBox(height: 40),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 50),
              Center(
  child: ElevatedButton(
    onPressed: _updateUserProfile,
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 10),
      backgroundColor: const Color(0xFF2E3192),
      foregroundColor: Colors.white, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
    child: const Text('Save'),
  ),
),

            ],
          ),
        ),
      ),
    );
  }
}
