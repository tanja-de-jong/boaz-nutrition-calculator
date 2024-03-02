import 'package:boaz_nutrition_calculator/diary/diary_overview.dart';
import 'package:boaz_nutrition_calculator/food/day_overview.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  DashboardState createState() => DashboardState();
}

class DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashboard',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Center(
        // Center the body horizontally
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          padding: const EdgeInsets.all(32.0), // Add padding around the body
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              // Add a tile for DayOverview
              SizedBox(
                width: 200,
                height: 200,
                child: Card(
                  child: InkWell(
                    onTap: () {
                      // Navigate to DayOverview in lib/food/day_overview.dart
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const DayOverview(),
                        ),
                      );
                    },
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_menu,
                              size: 48), // Increase icon size
                          SizedBox(height: 16), // Increase spacing
                          Text('Eten',
                              style: TextStyle(
                                  fontSize: 24)), // Increase text size
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Add a tile for DiaryOverview
              SizedBox(
                width: 200,
                height: 200,
                child: Card(
                  child: InkWell(
                    onTap: () {
                      // Navigate to DiaryOverview in lib/diary/diary_overview.dart
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const DiaryOverview(),
                        ),
                      );
                    },
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.book, size: 48), // Increase icon size
                          SizedBox(height: 16), // Increase spacing
                          Text('Dagboek',
                              style: TextStyle(
                                  fontSize: 24)), // Increase text size
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
