import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Management'),
        backgroundColor: Colors.deepOrange,
      ),
      body: const Center(
        child: Text('User Profile Screen (Placeholder)'),
      ),
    );
  }
}
