// lib/services/ioc_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class IocResult {
  final Map<String, dynamic>? data;
  final String? error;
  final bool loading;

  IocResult({this.data, this.error, this.loading = false});
}

class IocService {
  // API Key (gizli tut)
  static const String apiKey = 'rw7xly8ph67bp8uhh62l8umce0akxs0hcwrn3ypzhzzpjz5hry';

  static Future<IocResult> fetchIoc(String domain) async {
    final url = Uri.parse(
      'https://api.crawlsnap.com/v1/ioc/search/domain?key=$apiKey&query=$domain&force=true',
    );

    try {
      final resp = await http.get(url, headers: {
        'Accept': 'application/json',
        'User-Agent': 'Mozilla/5.0 (compatible; IOC-Search-App/1.0)'
      }).timeout(const Duration(seconds: 20));

      // Debug prints
      print('HTTP status: ${resp.statusCode}');
      debugPrint('HTTP body: ${resp.body}', wrapWidth: 1024);

      if (resp.statusCode != 200) {
        return IocResult(
          error: 'HTTP ${resp.statusCode}: ${resp.reasonPhrase}\n${resp.body}',
          loading: false,
        );
      }

      final decoded = json.decode(resp.body);
      if (decoded is Map<String, dynamic>) {
        // Eğer API data altında gerçek içeriği saklıyorsa onu döndür
        if (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>) {
          return IocResult(data: Map<String, dynamic>.from(decoded['data']), loading: false);
        } else if (decoded.containsKey('data')) {
          // data list gibi bir yapıysa map'e sarıp dönebiliriz
          return IocResult(data: {'_raw_data': decoded['data']}, loading: false);
        } else {
          return IocResult(data: Map<String, dynamic>.from(decoded), loading: false);
        }
      } else {
        return IocResult(data: {'_raw': decoded}, loading: false);
      }
    } catch (e) {
      return IocResult(error: e.toString(), loading: false);
    }
  }
}
