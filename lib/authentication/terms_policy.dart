import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:passenger/authentication/privacy_policytext.dart';
import 'package:passenger/authentication/signup_screen.dart';
import 'package:passenger/authentication/terms_privacy_details.dart';

// Location Page Widget
class TermsPolicy extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              children: [
                const Text(
                  'Tri.Co Terms and Policies',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 36.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E3192),
                  ),
                ),
                SizedBox(height: 18.0),
                RichText(
                  textAlign: TextAlign.start,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 20.0,
                      color: Colors.black54,
                    ),
                    children: [
                      TextSpan(
                        text:
                            'By tapping "Agree and Continue", you agree to our ',
                      ),
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E3192),
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Navigate to the Terms/Privacy Details Page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TermsOfServicePage(),
                              ),
                            );
                          },
                      ),
                      TextSpan(
                        text: ' and acknowledge that you have read our ',
                      ),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E3192),
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Navigate to the Terms/Privacy Details Page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PrivacyPolicyPage(),
                              ),
                            );
                          },
                      ),
                      TextSpan(
                        text:
                            ' to learn how we collect, use, and share your data.',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.0),
                Image.asset(
                  'assets/images/trisikol.png',
                  height: 150.0, // Set your desired height here
                  width: 150.0, // Set your desired width here
                ),
              ],
            ),
          ),
        ],
      ),
     bottomNavigationBar: Container(
  height: 200.0,
  child: Center(
    child: ElevatedButton(
      onPressed: () {
        // Correctly navigate to SignUpScreen when button is pressed
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SignUpScreen()),
        );
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Color.fromARGB(255, 32, 2, 87),
        side: BorderSide(color: Color.fromARGB(255, 32, 2, 87), width: 2.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
        minimumSize: Size(280.0, 50.0),
      ),
      child: Text(
        'Agree and Continue',
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),
)

    );
  }
}
