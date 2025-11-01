import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'result_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  Future<void> _searchDomain() async {
    String domain = _controller.text.trim();
    if (domain.isEmpty) return;

    setState(() {
      _loading = true;
    });

    final url = Uri.parse(
      "http://api.crawlsnap.com/v1/ioc/search/domain?key=rw7xly8ph67bp8uhh62l8umce0akxs0hcwrn3ypzhzzpjz5hry&query=$domain&force=true",
    );

    final response = await http.get(url);
    final data = json.decode(response.body);

    setState(() {
      _loading = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(data: data, domain: domain),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("IOC Search"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: "Domain gir (ör: google.com)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _searchDomain,
                    child: const Text("Ara"),
                  )
          ],
        ),
      ),
    );
  }
}
