import 'dart:convert';
import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final String domain;

  const ResultScreen({super.key, required this.data, required this.domain});

  @override
  Widget build(BuildContext context) {
   
    String prettyJson = const JsonEncoder.withIndent('  ').convert(data);

    return Scaffold(
      appBar: AppBar(
        title: Text("$domain Sonuçları"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          prettyJson,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}
