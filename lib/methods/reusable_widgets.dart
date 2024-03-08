
// reusable_widgets.dart
import 'package:flutter/material.dart';

Image logowidget(String imageName) {
  return Image.asset(
    imageName,
    fit: BoxFit.fitWidth,
  );
}

TextField customTextField(String labelText, IconData prefixIcon, bool isPasswordType, TextEditingController controller, {bool obscureText = false}) {
  bool _isPasswordVisible = obscureText; // Track password visibility

  return TextField(
    controller: controller,
    obscureText: _isPasswordVisible, // Use the tracked variable for password visibility
    enableSuggestions: !isPasswordType,
    autocorrect: !isPasswordType,
    cursorColor: const Color.fromARGB(255, 19, 19, 19),
    style: const TextStyle(color: Color.fromARGB(255, 14, 13, 13)),
    decoration: InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(prefixIcon, color: const Color.fromARGB(179, 40, 39, 39)),
      suffixIcon: obscureText ? IconButton(
        icon: Icon(
          _isPasswordVisible ? Icons.visibility : Icons.visibility_off, // Toggle icon based on password visibility
        ),
        onPressed: () {
          _isPasswordVisible = !_isPasswordVisible; // Toggle password visibility state
        },
      ) : null,
      border: const OutlineInputBorder(),
    ),
    keyboardType: isPasswordType ? TextInputType.visiblePassword : TextInputType.emailAddress,
  );
}


Container signInSignUpButton(BuildContext context, bool isLogin, Function onTap) {
  return Container(
    width: MediaQuery.of(context).size.width,
    height: 50,
    margin: const EdgeInsets.fromLTRB(0, 10, 0, 20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(90),
    ),
    child: ElevatedButton(
      onPressed: () {
        onTap();
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 10), backgroundColor: const Color(0xFF2E3192),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Text(
        isLogin ? 'LOG IN' : 'SIGN UP',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
  );
}

class CustomColumnWithLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
