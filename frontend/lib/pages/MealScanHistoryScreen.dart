import 'package:flutter/material.dart';
import '../services/meal_scanner_service.dart'; // Make sure this path is correct

class MealScanHistoryScreen extends StatelessWidget {
  final String userId;
  final MealScannerService _mealScannerService = MealScannerService();

  MealScanHistoryScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meal Scan History')),
      body: FutureBuilder<List<MealScanHistory>>(
        future: _mealScannerService.getMealHistory(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No history found.'));
          }

          final history = snapshot.data!;
          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final scan = history[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.fastfood),
                  title: Text(scan.foodName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${scan.calories} kcal'),
                      Text('Date: ${scan.timestamp.toLocal().toString().split('.')[0]}'),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
