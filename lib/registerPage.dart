import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stayawake/header.dart';
import 'package:stayawake/home.dart';
import 'package:stayawake/services/firebase_auth_services.dart';
import 'package:stayawake/services/firestore.dart';

class Registerpage extends StatefulWidget {
  const Registerpage({super.key});

  @override
  State<Registerpage> createState() => _RegisterpageState();
}

class _RegisterpageState extends State<Registerpage> {
  final FirebaseAuthService _auth = FirebaseAuthService();

  final FirestoreService firestoreService = FirestoreService();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomRoundedAppBar(
        pagename: 'Register',
      ),
      body: Padding(
        padding:
            EdgeInsets.only(left: 15.0, right: 15.0, top: 30, bottom: 15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(20),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(20),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(20),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            CupertinoButton(
                child: Text('Register'),
                color: Color(0xff6B94C5),
                onPressed: _signUp),
          ],
        ),
      ),
    );
  }

  Future<void> _signUp() async {
    String username = usernameController.text;
    String password = passwordController.text;
    String email = emailController.text;
    firestoreService.addUser(username, password, email);

    User? user = await _auth.signUpWithEmailAndPassword(
      email,
      password,
      (errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $errorMessage")),
        );
      },
    );
    if (user != null) {
      print("User is Sucessfully created");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Home(),
        ),
      );
    } else {
      print("error");
    }
  }
}
