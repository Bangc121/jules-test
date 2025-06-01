import 'package:flutter/material.dart';
import 'package:flutter_journal_app/calendar_screen.dart'; // Import CalendarScreen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Journal App',
      home: CalendarScreen(), // Set CalendarScreen as home
    );
  }
}
