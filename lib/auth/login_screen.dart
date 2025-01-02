import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mazhi_batmi/security/privacy_policy.dart';
import 'package:mazhi_batmi/security/terms_condition.dart';

import 'signup_screen.dart';
// Import flutter_svg

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive layout
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 10,
                ),
                // Add smaller SVG for illustration with responsive sizing
                SvgPicture.asset(
                  'assets/login.svg', // Your SVG asset
                  height: height * 0.2, // Adjust height to make it smaller
                  width: width * 0.4, // Adjust width to make it smaller
                ),
                SizedBox(height: 30), // Reduced spacing

                // Logo or welcome text with smaller font size
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: height * 0.04, // Adjust font size to be smaller
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Sign in to continue exploring the app',
                  style: TextStyle(
                    fontSize: height * 0.015, // Smaller font size
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 30), // Reduced spacing

                // Email input field with reduced size
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    prefixIcon: Icon(Icons.email, color: Colors.black),
                  ),
                ),
                SizedBox(height: 15), // Reduced spacing

                // Password input field with reduced size
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    prefixIcon: Icon(Icons.lock, color: Colors.black),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 15), // Reduced spacing

                // Forgot password link with smaller font size
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Handle forgot password action
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14, // Smaller font size
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 15), // Reduced spacing

                // Login Button with adjusted height and font size
                ElevatedButton(
                  onPressed: () {
                    // Handle login action
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize:
                        Size(double.infinity, height * 0.06), // Reduced height
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    textStyle: TextStyle(
                        fontSize: height * 0.018,
                        color: Colors.white), // Smaller font size
                  ),
                  child: Text(
                    'Log In',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(height: 20), // Reduced spacing

                // OR Divider with smaller spacing
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('OR',
                          style: TextStyle(
                              color: Colors.grey, fontSize: height * 0.015)),
                    ),
                    Expanded(child: Divider(color: Colors.grey)),
                  ],
                ),
                SizedBox(height: 20), // Reduced spacing

                // Google OAuth Button with Font Awesome Google Icon and adjusted size
                ElevatedButton.icon(
                  onPressed: () {
                    // Handle Google OAuth login
                  },
                  icon: FaIcon(
                    FontAwesomeIcons.google,
                    color: const Color.fromARGB(255, 0, 0, 0),
                    size: 18, // Smaller icon size
                  ),
                  label: Text('Log in with Google',
                      style:
                          TextStyle(color: const Color.fromARGB(255, 0, 0, 0))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize:
                        Size(double.infinity, height * 0.06), // Reduced height
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    textStyle: TextStyle(
                        fontSize: height * 0.018,
                        color: Colors.black), // Smaller font size
                  ),
                ),
                // Reduced spacing

                // Sign up text with smaller font size
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Don\'t have an account? ',
                        style: TextStyle(fontSize: height * 0.015)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AccountCreationPage()),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: height * 0.015, // Smaller font size
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TermsConditionsPage(),
                          ),
                        ); // Navigate to Terms and Conditions page
                      },
                      child: Text(
                        "Terms and Conditions",
                        style: TextStyle(fontSize: 10, color: Colors.black),
                      ),
                    ),
                    Text("|",
                        style: TextStyle(fontSize: 8, color: Colors.black)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PrivacyPolicyPage(),
                          ),
                        ); // Navigate to Privacy Policy page
                      },
                      child: Text(
                        "Privacy Policy",
                        style: TextStyle(fontSize: 10, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
