import 'package:flutter/material.dart';
import '../services/meal_scanner_service.dart'; // Make sure this path is correct

class MealScanHistoryScreen extends StatelessWidget {
  final String userId;
  final MealScannerService _mealScannerService = MealScannerService();

  MealScanHistoryScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Scan History'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: FutureBuilder<List<MealScanHistory>>(
        future: _mealScannerService.getMealHistory(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No scan history yet.',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                ],
              ),
            );
          }

          final history = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final scan = history[index];
              final formattedDate =
                  "${scan.timestamp.year}-${scan.timestamp.month.toString().padLeft(2, '0')}-${scan.timestamp.day.toString().padLeft(2, '0')} "
                  "${scan.timestamp.hour.toString().padLeft(2, '0')}:${scan.timestamp.minute.toString().padLeft(2, '0')}";
              return Card(
                color: Colors.white,
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[50],
                    child: Icon(Icons.fastfood, color: Colors.blue[700]),
                  ),
                  title: Text(
                    scan.foodName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              '${scan.calories} kcal',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: const TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                  // onTap: () {
                  //   // Optionally, show details or actions here
                  // },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
