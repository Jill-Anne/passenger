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
  bool _isPasswordVisible = false;
  String? _profileImageUrl;
  File? _profileImage;
  bool _isEditing = false;

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
        
        _profileImageUrl = userData['profileImageUrl'];
        setState(() {});
      }
    }
  }
  Future<void> _updateField(String fieldName, String newValue) async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    DatabaseReference userRef = FirebaseDatabase.instance.ref().child("users").child(user.uid);

    // Create a map with only the field to be updated
    Map<String, String> updateData = { fieldName: newValue };

    // Update the specific field in Firebase
    userRef.update(updateData).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Information updated successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating field: $error')),
      );
    });
  }
}


  Future<void> _updateUserProfile() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    // Check each field and update if it's not empty
    if (_nameController.text.trim().isNotEmpty) {
      await _updateField('name', _nameController.text.trim());
    }

    if (_phoneController.text.trim().isNotEmpty) {
      await _updateField('phone', _phoneController.text.trim());
    }

    if (_emailController.text.trim().isNotEmpty) {
      await _updateField('email', _emailController.text.trim());
    }

    if (_passwordController.text.trim().isNotEmpty) {
      await user.updatePassword(_passwordController.text.trim()).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating password: $error')),
        );
      });
    }

    if (_profileImage != null) {
      String profileImageUrl = await _uploadImageToFirebase(_profileImage!);
      await _updateField('profileImageUrl', profileImageUrl);
    }
    
    setState(() {
      _isEditing = false;
    });
  }
}

  Future<String> _uploadImageToFirebase(File image) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String fileName = user.uid;
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
      body: Column(
        children: [
          Container(
            color: Colors.white,
            height: 72,
            padding: const EdgeInsets.only(
              left: 8.0,
              right: 8.0,
              top: 35.0,
              bottom: 0.0,
            ),
            child: Row(
              
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () {
                      // Close the current screen and go back to the previous one
                      Navigator.pop(context);
                    },
                  ),
                if (!_isEditing)
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black54),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
              // Save button with extra padding below (only when editing)
              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.only(bottom: 0.0), // Add space below the Save button
                  child: TextButton(
                    onPressed: () {
                      _updateUserProfile();
                      setState(() {
                        _isEditing = false;
                      });
                    },
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
          //const SizedBox(height: 10),
          Expanded(
            child: Stack(
              children: [
                Container(
                  color: Color.fromARGB(255, 1, 42, 123),
                  height: 150,
                ),
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 50),
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 120, // Adjust the size if necessary
                                height: 120, // Adjust the size if necessary
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Color.fromARGB(255, 32, 2, 87),
                                    width: 4,
                                  ),
                                ),
                                child: ClipOval(
                                  child: _profileImage != null
                                      ? Image.file(
                                          _profileImage!,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          _profileImageUrl == null || _profileImageUrl!.isEmpty
                                              ? "https://firebasestorage.googleapis.com/v0/b/passenger-signuplogin.appspot.com/o/avatarman.png?alt=media&token=11c39289-3c10-4355-9537-9003913dbeef"
                                              : _profileImageUrl!,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 0, // Align to the bottom of the profile image
                                right: 0, // Align to the right edge of the profile image
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (_isEditing) {
                                        _pickImage();
                                      }
                                      _isEditing = !_isEditing; // Toggle edit mode
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: Color.fromARGB(255, 1, 42, 123),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isEditing ? Icons.camera_alt : Icons.edit,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
TextField(
  controller: _nameController,
  decoration: InputDecoration(
    labelText: 'Name',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(3.0), // Rounded corners
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0), // Padding
  ),
  style: const TextStyle(fontSize: 16.0),
),
const SizedBox(height: 15),
TextField(
  controller: _phoneController,
  decoration: InputDecoration(
    labelText: 'Phone',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(3.0), // Rounded corners
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0), // Padding
  ),
  style: const TextStyle(fontSize: 16.0),
),
const SizedBox(height: 15),
TextField(
  controller: _emailController,
  decoration: InputDecoration(
    labelText: 'Email',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(3.0), // Rounded corners
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0), // Padding
  ),
  style: const TextStyle(fontSize: 16.0),
),
const SizedBox(height: 15),
TextField(
  controller: _passwordController,
  obscureText: !_isPasswordVisible,
  decoration: InputDecoration(
    labelText: 'New Password',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(3.0), // Rounded corners
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0), // Padding
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
  style: const TextStyle(fontSize: 16.0),
),

                        const SizedBox(height: 50),
                        // Center(
                        //   child: ElevatedButton(
                        //     onPressed: _updateUserProfile,
                        //     style: ElevatedButton.styleFrom(
                        //       padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 10),
                        //       backgroundColor: const Color(0xFF2C3E50),
                        //     ),
                        //     child: const Text('Update Profile'),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
