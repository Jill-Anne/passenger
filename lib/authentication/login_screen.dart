import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lottie/lottie.dart';
import 'package:passenger/authentication/forgot_password.dart';
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
  bool _isPasswordVisible = false;

  void checkIfNetworkIsAvailable() {
    cMethods.checkConnectivity(context);
    signInFormValidation();
  }

  void signInFormValidation() {
    if (!emailTextEditingController.text.contains("@")) {
      cMethods.displaySnackBar("Please write a valid email.", context);
    } else if (passwordTextEditingController.text.trim().length < 6) {
      cMethods.displaySnackBar("Your password must be at least 6 characters.", context);
    } else {
      signInUser();
    }
  }

  Future<void> signInUser() async {
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
        if (!userFirebase.emailVerified) {
          FirebaseAuth.instance.signOut();
          cMethods.displaySnackBar("Please verify your email before logging in.", context);
          return;
        }

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
        print('Error during sign-in: $error');
        cMethods.displaySnackBar(
          "An error occurred. Please check your credentials and try again.",
          context,
        );
      }
    }
  }

  void forgotPassword() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      TextEditingController resetEmailController = TextEditingController();
      return AlertDialog(
        title: Text("Reset Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: resetEmailController,
              decoration: InputDecoration(
                labelText: "Enter your email",
                prefixIcon: Icon(Icons.email),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              String email = resetEmailController.text.trim();
              if (email.isNotEmpty) {
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  Navigator.pop(context); // Close the dialog
                  cMethods.displaySnackBar("Password reset email sent!", context);
                } catch (e) {
                  cMethods.displaySnackBar("Error: ${e.toString()}", context);
                }
              } else {
                cMethods.displaySnackBar("Please enter your email.", context);
              }
            },
            child: Text("Send Reset Link"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: Text("Cancel"),
          ),
        ],
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          CustomColumnWithLogo(),
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
                  "Sign in with email and Password.",
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
                  emailTextEditingController, maxLength: 30,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordTextEditingController,
                  obscureText: !_isPasswordVisible,
                  enableSuggestions: false,
                  autocorrect: false,
                  cursorColor: const Color.fromARGB(255, 19, 19, 19),
                  style: const TextStyle(color: Color.fromARGB(255, 14, 13, 13)),
                  decoration: InputDecoration(
                    labelText: "User Password",
                    prefixIcon: Icon(Icons.lock, color: const Color.fromARGB(179, 40, 39, 39)),
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
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.visiblePassword,
                ),
                const SizedBox(height: 30),
                signInSignUpButton(context, true, () {
                  checkIfNetworkIsAvailable();
                }),
                signUpOption(),
                const SizedBox(height: 10), // Spacer for readability
                forgotPasswordOption(), // Added forgot password option
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

  Row forgotPasswordOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
          );
          },
          child: const Text(
            "Forgot Password?",
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