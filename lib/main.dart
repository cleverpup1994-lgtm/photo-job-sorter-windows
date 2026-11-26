import 'package:flutter/material.dart';

import 'logic/sorter_controller.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() {
  runApp(PhotoJobSorterApp(controller: SorterController()));
}

class PhotoJobSorterApp extends StatelessWidget {
  const PhotoJobSorterApp({super.key, required this.controller});

  final SorterController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Job Sorter',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: HomeScreen(controller: controller),
    );
  }
}
