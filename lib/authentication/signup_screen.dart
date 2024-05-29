import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:passenger/authentication/login_screen.dart';
import 'package:passenger/global/trip_var.dart';
import 'package:passenger/methods/common_methods.dart';
import 'package:passenger/methods/reusable_widgets.dart';
import 'package:passenger/pages/home_page.dart';
import 'package:passenger/widgets/loading_dialog.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController userNameTextEditingController = TextEditingController();
  TextEditingController userPhoneTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  CommonMethods cMethods = CommonMethods();
  bool _isPasswordVisible = false; // Flag to track whether the password is visible or not

  checkIfNetworkIsAvailable() {
    cMethods.checkConnectivity(context);

    signUpFormValidation();
  }

  signUpFormValidation() {
    if (userNameTextEditingController.text.trim().length < 3) {
      cMethods.displaySnackBar("Your name must be at least 4 or more characters.", context);
    } else if (userPhoneTextEditingController.text.trim().length < 7) {
      cMethods.displaySnackBar("Your phone number must be at least 8 or more characters.", context);
    } else if (!emailTextEditingController.text.contains("@")) {
      cMethods.displaySnackBar("Please write a valid email.", context);
    } else if (passwordTextEditingController.text.trim().length < 5) {
      cMethods.displaySnackBar("Your password must be at least 6 or more characters.", context);
    } else {
      registerNewUser();
    }
  }

  registerNewUser() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => LoadingDialog(messageText: "Registering your account..."),
    );

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailTextEditingController.text.trim(),
        password: passwordTextEditingController.text.trim(),
      );

      User? userFirebase = userCredential.user;

      if (userFirebase != null) {
        DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("users").child(userFirebase.uid);

        Map userDataMap = {
          "name": userNameTextEditingController.text.trim(),
          "email": emailTextEditingController.text.trim(),
          "phone": userPhoneTextEditingController.text.trim(),
          "id": userFirebase.uid,
          "blockStatus": "no",
        };

        await usersRef.set(userDataMap);

        // Save user details to global variable
        UserData.name = userNameTextEditingController.text.trim();
        UserData.phone = userPhoneTextEditingController.text.trim();
        UserData.email = emailTextEditingController.text.trim();

        Navigator.pop(context); // Close loading dialog

        // Show success dialog
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text("Successfully Sign Up"),
            content: Text("You have successfully signed up."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
      } else {
        Navigator.pop(context); // Close loading dialog
        cMethods.displaySnackBar("User registration failed. Please try again.", context);
      }
    } catch (error) {
      Navigator.pop(context); // Close loading dialog
      cMethods.displaySnackBar(error.toString(), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          CustomColumnWithLogo(), // Logo on the left side
          Positioned(
            left: 0,
            bottom: -10,
            child: logowidget("assets/images/LOGO.png"),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  SizedBox(height: 50),
                  Positioned(
                    top: 100,
                    left: 30,
                    right: 30,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 0, left: 20), // Adjust the left padding here
                          child: Text(
                            "Sign up with email or phone number.",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            children: [
                              customTextField("Name", Icons.person, false, userNameTextEditingController),
                              const SizedBox(height: 22),
                              customTextField("User Phone", Icons.phone, false, userPhoneTextEditingController),
                              const SizedBox(height: 22),
                              customTextField("User Email", Icons.email, false, emailTextEditingController),
                              const SizedBox(height: 22),
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
                                        _isPasswordVisible = !_isPasswordVisible; // Toggle password visibility state
                                      });
                                    },
                                  ),
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.visiblePassword,
                              ),
                              const SizedBox(height: 32),
                              signInSignUpButton(context, false, () {
                                checkIfNetworkIsAvailable();
                              }),
                              const SizedBox(height: 12),
                              signUpOption(),
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
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
          "Already have an account?",
          style: TextStyle(color: Color.fromARGB(179, 11, 11, 11)),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
          },
          child: const Text(
            " Log In",
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
