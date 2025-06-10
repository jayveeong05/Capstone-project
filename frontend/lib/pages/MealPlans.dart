import 'package:flutter/material.dart';

class MealPlansPage extends StatelessWidget {
  const MealPlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plans'),
        backgroundColor: Colors.blueAccent,
      ),
      body: const Center(
        child: Text(
          'Your personalized meal plans will appear here!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}