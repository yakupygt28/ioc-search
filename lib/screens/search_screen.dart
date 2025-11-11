import 'package:flutter/material.dart';
import 'package:ios_search/screens/result_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  void _go() {
    final domain = _controller.text.trim();
    if (domain.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen domain girin')));
      return;
    }
    final sanitized = domain.replaceAll(RegExp(r'https?://'), '').replaceAll(RegExp(r'/.*'), '');
    Navigator.push(context, MaterialPageRoute(builder: (_) => ResultsScreen(domain: sanitized)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IOC Search'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Threat Intelligence Dashboard',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF96A0FF)),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0B1620),
                hintText: 'örn: me-doc.com',
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _go),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _go(),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(onPressed: _go, icon: const Icon(Icons.arrow_forward), label: const Text('Ara')),
          ],
        ),
      ),
    );
  }
}
