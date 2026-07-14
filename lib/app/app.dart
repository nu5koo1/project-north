import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class ProjectNorthApp extends StatelessWidget {
  const ProjectNorthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Project North',
      theme: AppTheme.lightTheme,
      home: const Scaffold(
        body: Center(
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