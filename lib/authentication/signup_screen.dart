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
  String userNameError = '';
  String phoneError = '';
  String emailError = '';
  String passwordError = '';

  @override
  void initState() {
    super.initState();

    userNameTextEditingController.addListener(() => validateUserName());
    userPhoneTextEditingController.addListener(() => validatePhone());
    emailTextEditingController.addListener(() => validateEmail());
    passwordTextEditingController.addListener(() => validatePassword());
  }

void validateUserName() {
  setState(() {
    if (userNameTextEditingController.text.isNotEmpty) {
      userNameError = (userNameTextEditingController.text.trim().length < 3 ||
              !RegExp(r'^[a-zA-Z\s]+$').hasMatch(userNameTextEditingController.text.trim()))
          ? "Your username must be at least 3 characters long and contain only letters and spaces."
          : ''; // Clear the error if validation is successful
    } else {
      userNameError = ''; // Clear the error if input is empty
    }
  });
}


void validatePhone() {
  setState(() {
    String phoneText = userPhoneTextEditingController.text.trim();
    
    if (phoneText.length > 11) {
      // Limit input to 11 characters
      userPhoneTextEditingController.text = phoneText.substring(0, 11);
      userPhoneTextEditingController.selection = TextSelection.fromPosition(
        TextPosition(offset: userPhoneTextEditingController.text.length),
      );
    }
    
    phoneError = (phoneText.length != 11 || !RegExp(r'^\d+$').hasMatch(phoneText))
        ? "Your phone number must be exactly 11 digits."
        : ''; // Clear the error if validation is successful
  });
}



void validateEmail() {
  setState(() {
    if (emailTextEditingController.text.isNotEmpty) {
      emailError = (!emailTextEditingController.text.contains("@"))
          ? "Please write a valid email."
          : ''; // Clear the error if validation is successful
    } else {
      emailError = ''; // Clear the error if input is empty
    }
  });
}

void validatePassword() {
  setState(() {
    if (passwordTextEditingController.text.isNotEmpty) {
      passwordError = (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\W).{8,}$')
              .hasMatch(passwordTextEditingController.text.trim()))
          ? "Your password must be at least 8 characters long, contain upper and lowercase letters, and include special characters."
          : ''; // Clear the error if validation is successful
    } else {
      passwordError = ''; // Clear the error if input is empty
    }
  });
}


  checkIfNetworkIsAvailable() {
    cMethods.checkConnectivity(context);

    signUpFormValidation();
  }

   // Update signUpFormValidation to avoid unnecessary dialog
signUpFormValidation() {
  validateUserName();
  validatePhone();
  validateEmail();
  validatePassword();

  if (userNameError.isEmpty && phoneError.isEmpty && emailError.isEmpty && passwordError.isEmpty) {
    checkEmailExists(emailTextEditingController.text.trim());
  } else {
    cMethods.displaySnackBar("Please correct the errors above before proceeding.", context);
  }
}


sendVerificationEmail(User user) async {
  try {
    print("Sending verification email to ${user.email}");
    await user.sendEmailVerification();
    print("Verification email sent successfully.");

    // Show dialog to inform user to check their email
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Center(child: Text("Check your email for verification.",
         style: TextStyle(color: Color.fromARGB(255, 1, 42, 123)),
         textAlign: TextAlign.center,
        )),
        content: const Text("A verification link has been sent to your email. Please verify to continue.",
         textAlign: TextAlign.center,),
  actions: [
      Center( // Center the button
        child: SizedBox(
          width: 200, // Set the width for the button
          height: 50, // Set the height for the button 
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white, 
              backgroundColor: const Color.fromARGB(255, 1, 42, 123), // Background color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
           checkEmailVerification(user); // Start checking for verification
            },
            child: const Text("OK"),
          ),
        ),
      )
        ],
      ),
    );
  } catch (e) {
    print("Failed to send verification email: $e");
    cMethods.displaySnackBar("Failed to send verification email. Please try again.", context);
  }
}

checkEmailVerification(User user) async {
  bool isVerified = false;

  while (!isVerified) {
    await Future.delayed(Duration(seconds: 1)); // Wait for 5 seconds before checking again

    // Reload user to check verification status
    User? updatedUser = FirebaseAuth.instance.currentUser;

    if (updatedUser != null) {
      await updatedUser.reload();
      isVerified = updatedUser.emailVerified;
      print("Checked verification status: ${updatedUser.emailVerified}");
    }

    // If verified, show success dialog
    if (isVerified) {
      showSuccessDialog();
    }
  }
}

showSuccessDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Center(
        child: Text(
          "Successfully Signed Up",
          style: TextStyle(color: Color.fromARGB(255, 1, 42, 123)), // Title text color
        ),
      ),
             content: const Text("You have successfully signed up.", 
         textAlign: TextAlign.center,),
      actions: [
        Center(
          child: SizedBox(
            width: 200, // Set the width for the button
            height: 40, // Set the height for the button
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color.fromARGB(255, 1, 42, 123), // Background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
              },
              child: const Text("OK"),
            ),
          ),
        ),
      ],
    ),
  );
}
  checkEmailExists(String email) async {
    try {
      List<String> signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (signInMethods.isNotEmpty) {
        cMethods.displaySnackBar("This email is already in use. Please use a different email.", context);
      } else {
        registerNewUser();
      }
    } catch (error) {
      cMethods.displaySnackBar("Error checking email: $error", context);
    }
  }

 registerNewUser() async {
  // Show the loading dialog immediately
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
      
 await sendVerificationEmail(userFirebase);
      } else {
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
        CustomColumnWithLogo(),
        Positioned(
          left: 0,
          bottom: 0,
          child: logowidget("assets/images/LOGO.png"),
        ),
        // Move the following section directly inside the Stack
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                SizedBox(height: 50),
                // Remove Positioned here
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 0, left: 20),
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
                          customTextField("Name", Icons.person, false, userNameTextEditingController, maxLength: 30),
                          if (userNameError.isNotEmpty) Text(userNameError, style: TextStyle(color: Colors.red)),
                          const SizedBox(height: 22),
                          customTextField("User Phone", Icons.phone, false, userPhoneTextEditingController, maxLength: 11),
                          if (phoneError.isNotEmpty) Text(phoneError, style: TextStyle(color: Colors.red)),
                          const SizedBox(height: 22),
                          customTextField("User Email", Icons.email, false, emailTextEditingController, maxLength: 30),
                          if (emailError.isNotEmpty) Text(emailError, style: TextStyle(color: Colors.red)),
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
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.visiblePassword,
                          ),
                          if (passwordError.isNotEmpty) Text(passwordError, style: TextStyle(color: Colors.red)),
                          const SizedBox(height: 32),
                          signInSignUpButton(context, false, () {
                            checkIfNetworkIsAvailable();
                          }),
                          const SizedBox(height: 12),
                          signUpOption(),
                        ],
                      ),
                    ),
                  ],
                ),
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