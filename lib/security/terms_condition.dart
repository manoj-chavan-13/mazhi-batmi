import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Terms and Conditions",
          style: TextStyle(
            color: const Color.fromARGB(255, 0, 0, 0),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        surfaceTintColor: Colors.white,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome to Mazh Gav Mazhi Batmi! These terms and conditions outline the rules and regulations for the use of our app, which provides news-sharing services. By accessing or using the app, you agree to comply with these terms. Please read them carefully before using the app.",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                Text(
                  "1. Account Creation",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "To use the app, users must create an account by providing personal details such as name, email, mobile number, and profile information. You are responsible for maintaining the confidentiality of your account.",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                Text(
                  "2. User-Generated Content",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Users are allowed to create, share, and comment on news articles. You agree not to post any content that is illegal, offensive, or violates the rights of others.",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                Text(
                  "3. Privacy and Data Usage",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "We collect and use personal information to provide and improve the services of the app. Please read our Privacy Policy for more details on how we handle your data.",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                Text(
                  "4. Limitation of Liability",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "We are not responsible for any direct or indirect damages caused by the use of our app, including but not limited to loss of data, content, or revenue.",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                Text(
                  "5. Changes to the Terms",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "We may update these terms from time to time. All changes will be posted on this page with a revision date. By continuing to use the app after such changes, you accept the updated terms.",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                Text(
                  "If you have any questions or concerns about these terms, please contact us at support@mazhgavmazhibatmi.com.",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
