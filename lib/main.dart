import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:stayawake/firebase_options.dart';
import 'package:stayawake/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MaterialApp(
    home: Login(),
    debugShowCheckedModeBanner: false,
  ));
}
