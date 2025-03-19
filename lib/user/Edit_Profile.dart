import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mazhi_batmi/auth/login_screen.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  String? _profileImagePath;
  String? _profileImageUpdater;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _supabase = Supabase.instance.client;

  // Focus nodes for dynamically updating border radius
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _aboutFocusNode = FocusNode();

  Future<void> _fetchUserData() async {
    final user = _supabase.auth.currentUser;

    if (user != null) {
      try {
        final response = await _supabase
            .from('users')
            .select('name, email, mobile, bio, profile_pic')
            .eq('uid', user.id) // Match the user ID
            .single(); // Assuming we expect a single result

        // Populate the fields with the fetched data
        setState(() {
          _nameController.text = response['name'] ?? '';
          _emailController.text = response['email'] ?? '';
          _phoneController.text = response['mobile']?.toString() ?? '';
          _aboutController.text = response['bio'] ?? '';
          _profileImagePath =
              response['profile_pic']; // Assuming URL or file path is stored
        });
      } catch (e) {
        print("Error fetching user data: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch user data')),
        );
      }
    }
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    var status = await Permission.photos.status;
    if (!status.isGranted) {
      await Permission.photos.request();
    }

    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _profileImageUpdater = pickedFile.path;
          _profileImagePath = null; // Reset the old profile image path
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch the data when the screen is initialized
  }

  Future<void> _saveProfile() async {
    final user = _supabase.auth.currentUser;
    String imageUrl;
    if (user != null) {
      try {
        // Prepare the updated data only with non-null fields
        final updatedData = {
          if (_nameController.text.isNotEmpty) 'name': _nameController.text,
          if (_emailController.text.isNotEmpty) 'email': _emailController.text,
          if (_phoneController.text.isNotEmpty) 'mobile': _phoneController.text,
          if (_aboutController.text.isNotEmpty) 'bio': _aboutController.text,
        };

        // If a new profile image is picked, upload it to Supabase Storage
        if (_profileImageUpdater != null) {
          // Define the file and file name
          final file = File(_profileImageUpdater!);
          final fileName = '${user.id}.jpg';

          // Check if a profile picture already exists
          final existingPicUrl = await _supabase
              .from('users')
              .select('profile_pic')
              .eq('uid', user.id)
              .single();
          print(existingPicUrl);
          if (existingPicUrl['profile_pic'] != null &&
              existingPicUrl['profile_pic'].isNotEmpty) {
            // Update the existing profile picture
            final storageResponse = await _supabase.storage
                .from('profile-pictures')
                .update(fileName, file);
            print("updated Done");
            print(storageResponse);
          } else {
            final storageResponse = await _supabase.storage
                .from('profile-pictures')
                .upload(fileName, file);
            print(storageResponse);
          }

          imageUrl =
              _supabase.storage.from('profile-pictures').getPublicUrl(fileName);

          updatedData['profile_pic'] = imageUrl;
        }

        final response = await _supabase
            .from('users')
            .update(updatedData)
            .eq('uid', user.id);

        if (response != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile')),
          );
        } else {
          _showSuccessDialog();
        }
      } catch (e) {
        print("Error updating user data: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update user data')),
        );
      }
    }
  }

  // Show success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 50,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Profile Updated!',
              style: TextStyle(
                fontSize: 20,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Your profile has been updated successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: Text(
              'OK',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Dispose the focus nodes
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _aboutFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 140, // Width of the avatar
                    height: 140, // Height of the avatar
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            const Color.fromARGB(255, 0, 0, 0), // Border color
                        width: 2, // Border width
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor:
                          Colors.white, // Avatar radius (half of width/height)
                      backgroundImage: _profileImagePath != null
                          ? NetworkImage(
                              _profileImagePath!) // Use network image if path exists
                          : (_profileImageUpdater != null
                              ? FileImage(File(_profileImageUpdater!))
                              : AssetImage('assets/user.png')
                                  as ImageProvider), // Fallback to placeholder if no image
                      child: _profileImagePath == null &&
                              _profileImageUpdater == null
                          ? Icon(Icons.edit,
                              size: 40,
                              color: const Color.fromARGB(255, 0, 0, 0))
                          : null,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: TextStyle(color: Colors.black),
                        border: OutlineInputBorder(), // Default border
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: const Color.fromARGB(255, 0, 0, 0),
                              width: 2), // Green outline
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                      cursorColor: const Color.fromARGB(
                          255, 0, 0, 0), // Green cursor color
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Colors.black),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: const Color.fromARGB(255, 0, 0, 0),
                              width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                      cursorColor: const Color.fromARGB(255, 0, 0, 0),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      focusNode: _phoneFocusNode,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: TextStyle(color: Colors.black),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: const Color.fromARGB(255, 0, 0, 0),
                              width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                      cursorColor: const Color.fromARGB(255, 0, 0, 0),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _aboutController,
                      focusNode: _aboutFocusNode,
                      decoration: InputDecoration(
                        labelText: 'About You',
                        labelStyle: TextStyle(color: Colors.black),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: const Color.fromARGB(255, 0, 0, 0),
                              width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                      cursorColor: const Color.fromARGB(255, 0, 0, 0),
                      maxLines: 5,
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _saveProfile();

                            _showSuccessDialog();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 50.0, vertical: 15.0),
                          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(20)), // Button color
                        ),
                        child: Text(
                          'Save Changes',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          await _supabase.auth.signOut();
                          Navigator.of(context).pop();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => LoginPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 50.0, vertical: 15.0),
                          backgroundColor: Colors.red,

                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(20)), // Button color
                        ),
                        child: Text(
                          'Logout',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Love from \nMazhi Batmi',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 30.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    Center(
                      child: Text(
                        'Thank you for being awesome!',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
