import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mazhi_batmi/auth/login_screen.dart';
import 'package:mazhi_batmi/security/terms_condition.dart';
import 'package:mazhi_batmi/security/privacy_policy.dart';
import '../main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountCreationPage extends StatefulWidget {
  const AccountCreationPage({super.key});

  @override
  _AccountCreationPageState createState() => _AccountCreationPageState();
}

class _AccountCreationPageState extends State<AccountCreationPage> {
  int _currentStep = 0;
  String? _mobileNumber, _email, _name, _bio, _profilePicUrl;
  XFile? _profilePic;
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _passController = TextEditingController();
  final PageController _pageController = PageController();
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _createAccount() async {
    try {
      if (_emailController.text.isEmpty || _passController.text.isEmpty) {
        _showErrorDialog("Email or Password cannot be empty");
        return;
      }

      final response = await _supabase.auth
          .signUp(email: _emailController.text, password: _passController.text);

      if (response.user != null) _nextStep();
    } catch (e) {
      // Handle any exceptions that occur during the try block execution
      _showErrorDialog("Error creating account: $e");
    }
  }

  Future<void> _saveUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      print(user);
      String profilePicUrl = '';

      if (user != null) {
        if (_profilePic != null) {
          final file = File(_profilePic!.path);
          final storageResponse = await _supabase.storage
              .from('profile-pictures')
              .upload('profile-pictures/${user.id}.jpg', file);

          final downloadUrl = _supabase.storage
              .from('profile-pictures')
              .getPublicUrl('profile-pictures/${user.id}.jpg');
          _profilePicUrl = downloadUrl;
        }

        final userResponse = await _supabase.from('users').insert({
          'uid': user.id,
          'name': _nameController.text,
          'email': _emailController.text,
          'mobile': _mobileController.text,
          'bio': _bioController.text,
          'profile_pic': _profilePicUrl ?? '',
        });

        // Check for error in the user insert response

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Profile Setup Done!"),
            content: Text("Your profile has been successfully set up."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => MainScreen()),
                  );
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Catch any errors in the try block and handle them appropriately
      _showErrorDialog("Error saving user data: $e");
    }
  }

  void _nextStep() {
    if (_currentStep < 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _pickProfilePicture() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _profilePic = pickedFile;
        });
      }
    } catch (e) {
      _showErrorDialog("Error picking profile picture: $e");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    height: 10,
                    width: _currentStep == index ? 20 : 10,
                    decoration: BoxDecoration(
                      color: _currentStep == index ? Colors.black : Colors.grey,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  _buildEmailStep(height),
                  _buildProfileStep(height),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                child: Text(
                  "Already have an account?",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TermsConditionsPage(),
                        ),
                      );
                    },
                    child: Text(
                      "Terms and Conditions",
                      style: TextStyle(fontSize: 10, color: Colors.black),
                    ),
                  ),
                  Text("|",
                      style: TextStyle(fontSize: 10, color: Colors.black)),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PrivacyPolicyPage(),
                        ),
                      );
                    },
                    child: Text(
                      "Privacy Policy",
                      style: TextStyle(fontSize: 10, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailStep(double height) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 50),
            SvgPicture.asset(
              'assets/login.svg',
              height: height * 0.2,
            ),
            SizedBox(height: 20),
            Text(
              "Welcome to ",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Mazh Gav Mazhi Batmi",
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Stay updated, anytime, anywhere!",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w300,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 30),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.password),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
              keyboardType: TextInputType.visiblePassword,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createAccount,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, height * 0.06),
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text("Next"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStep(double height) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 50),
            GestureDetector(
              onTap: _pickProfilePicture,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: _profilePic != null
                    ? FileImage(File(_profilePic!.path))
                    : null,
                child: _profilePic == null
                    ? Icon(Icons.add_a_photo, size: 30, color: Colors.black)
                    : null,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _mobileController,
              decoration: InputDecoration(
                labelText: 'Mobile Number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _bioController,
              decoration: InputDecoration(
                labelText: 'Bio',
                prefixIcon: Icon(Icons.info_outline),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveUserData,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, height * 0.06),
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text("Finish"),
            ),
          ],
        ),
      ),
    );
  }
}
