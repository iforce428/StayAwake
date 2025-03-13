import 'package:flutter/material.dart';


class CustomRoundedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String pagename;

  // Constructor to accept the username
  const CustomRoundedAppBar({Key? key, required this.pagename}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      decoration: BoxDecoration(
        color: Color(0xFF6B94C5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              pagename,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Implementing PreferredSizeWidget
  @override
  Size get preferredSize => const Size.fromHeight(100);
}
