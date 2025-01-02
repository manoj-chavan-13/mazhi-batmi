import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Display the PNG Image
            Image.asset(
              'assets/logo.png', // Replace with your PNG file's path
              width: 100,
              height: 100,
            ),

            // Main Welcome Text
          ],
        ),
      ),
    );
  }
}
