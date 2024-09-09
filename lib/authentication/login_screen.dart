import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lottie/lottie.dart';
import 'package:passenger/authentication/signup_screen.dart';
import 'package:passenger/global/global_var.dart';
import 'package:passenger/methods/common_methods.dart';
import 'package:passenger/methods/reusable_widgets.dart';
import 'package:passenger/pages/home_page.dart';
import 'package:passenger/widgets/loading_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  CommonMethods cMethods = CommonMethods();
  bool _isPasswordVisible =
      false; // Flag to track whether the password is visible or not

  void checkIfNetworkIsAvailable() {
    cMethods.checkConnectivity(context);
    signInFormValidation();
  }

  void signInFormValidation() {
    if (!emailTextEditingController.text.contains("@")) {
      cMethods.displaySnackBar("Please write a valid email.", context);
    } else if (passwordTextEditingController.text.trim().length < 5) {
      cMethods.displaySnackBar(
          "Your password must be at least 6 or more characters.", context);
    } else {
      signInUser();
    }
  }

Future<void> signInUser() async {
  // Show a full-screen dialog with a Lottie animation while logging in
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        insetPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie animation for "Logging in"
              Lottie.asset(
                'assets/images/loading.json',
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.width * 0.9,
                fit: BoxFit.cover,
                repeat: true,
              ),
              const SizedBox(height: 50),
              const Text(
                "Authenticating",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 1, 42, 123),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  try {
    final UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(
      email: emailTextEditingController.text.trim(),
      password: passwordTextEditingController.text.trim(),
    );

    final User? userFirebase = userCredential.user;

    if (!context.mounted) return;
    Navigator.pop(context); // Close the dialog

    if (userFirebase != null) {
      DatabaseReference usersRef = FirebaseDatabase.instance
          .ref()
          .child("users")
          .child(userFirebase.uid);

      final snapshot = await usersRef.once();
      if (snapshot.snapshot.value != null) {
        final userData = snapshot.snapshot.value as Map;
        if (userData["blockStatus"] == "no") {
          userName = userData["name"];
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (c) => HomePage()),
          );
        } else {
          FirebaseAuth.instance.signOut();
          cMethods.displaySnackBar(
            "Your account has been blocked. Please contact support.",
            context,
          );
        }
      } else {
        FirebaseAuth.instance.signOut();
        cMethods.displaySnackBar(
          "User record not found. Please check your credentials.",
          context,
        );
      }
    }
  } catch (error) {
    if (context.mounted) {
      Navigator.pop(context); // Close the dialog in case of an error

      // Print detailed error for debugging
      print('Error during sign-in: $error');

      // Display user-friendly error message
      cMethods.displaySnackBar(
        "An error occurred. Please check your credentials and try again.",
        context,
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Stack(
        children: [
          CustomColumnWithLogo(), // Logo on the left side
          Positioned(
            left: 0,
            bottom: 0,
            child: logowidget("assets/images/LOGO.png"),
          ),
          Positioned(
            top: 100,
            left: 30,
            right: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Sign in with email or phone number.",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20),
                customTextField(
                  "User Email",
                  Icons.email,
                  false,
                  emailTextEditingController,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordTextEditingController,
                  obscureText: !_isPasswordVisible,
                  enableSuggestions: false,
                  autocorrect: false,
                  cursorColor: const Color.fromARGB(255, 19, 19, 19),
                  style:
                      const TextStyle(color: Color.fromARGB(255, 14, 13, 13)),
                  decoration: InputDecoration(
                    labelText: "User Password",
                    prefixIcon: Icon(Icons.lock,
                        color: const Color.fromARGB(179, 40, 39, 39)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible =
                              !_isPasswordVisible; // Toggle password visibility state
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.visiblePassword,
                ),
                const SizedBox(height: 30),
                signInSignUpButton(context, true, () {
                  checkIfNetworkIsAvailable();
                }),
                signUpOption()
              ],
            ),
          ),
        ],
      ),
    );
  }

  Row signUpOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account?",
          style: TextStyle(color: Color.fromARGB(179, 11, 11, 11)),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => SignUpScreen()));
          },
          child: const Text(
            " Sign Up",
            style: TextStyle(
              color: Color(0xFF2E3192),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
