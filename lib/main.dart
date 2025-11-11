import 'package:flutter/material.dart';
import 'package:ios_search/screens/search_screen.dart';

void main() {
  runApp(const IocSearchApp());
}

class IocSearchApp extends StatelessWidget {
  const IocSearchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IOC Search',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color.fromRGBO(15, 23, 36, 1),
        cardColor: const Color(0xFF14202B),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white),
        ),
      ),
      home: const SearchScreen(),
    );
  }
}
