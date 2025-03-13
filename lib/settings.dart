import 'package:flutter/material.dart';
import 'package:stayawake/services/db_helper.dart';
import 'package:stayawake/viewHistory.dart';

import 'analysisPage.dart';
import 'home.dart';
import 'login.dart';

class settingsPage extends StatefulWidget {
  const settingsPage({super.key});

  @override
  State<settingsPage> createState() => _settingsPageState();
}

class _settingsPageState extends State<settingsPage> {
  Map<String, dynamic> parameter = {};

  @override
  void initState() {
    super.initState();
    getParameter();
  }

  Future<void> getParameter() async {
    var a = await dbHelper().getParameters();
    setState(() {
      parameter = a!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffc6d6f5),
      body: Column(
        children: [
          // Custom AppBar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            decoration: const BoxDecoration(
              color: Color(0xff6B94C5),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20), // Adjust as needed
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CircleAvatar(
                    radius: 55,
                    backgroundImage: AssetImage('assets/images/blankpf.png'),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '${parameter['username']}',
                    style: TextStyle(fontSize: 22),
                  ),
                  Text(
                    '${parameter['email']}',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 40),
                  ListTile(
                    leading: Icon(Icons.person, size: 30),
                    title: Text(
                      'Account Settings',
                      style: TextStyle(fontSize: 20),
                    ),
                    onTap: () {
                      // Navigate to account settings screen
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.volume_up, size: 30),
                    title: Text(
                      'Alert Preferences',
                      style: TextStyle(fontSize: 20),
                    ),
                    onTap: () {
                      // Navigate to alert preferences screen
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.camera_alt, size: 30),
                    title: Text(
                      'Camera Settings',
                      style: TextStyle(fontSize: 20),
                    ),
                    onTap: () {
                      // Navigate to camera settings screen
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.exit_to_app, size: 30),
                    title: Text(
                      'Logout',
                      style: TextStyle(fontSize: 20),
                    ),
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const Login()),
                        (Route<dynamic> route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xff6B94C5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.black, size: 40),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Home()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.show_chart, color: Colors.black, size: 40),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Analysispage()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
            IconButton(
              icon:
                  const Icon(Icons.access_time, color: Colors.black, size: 40),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const viewHistory()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.black, size: 40),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
