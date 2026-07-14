import 'package:flutter/material.dart';

void main() {
  runApp(const ProjectNorthApp());
}

class ProjectNorthApp extends StatelessWidget {
  const ProjectNorthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Project North',
      home: Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: Text(
            'Project North',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}