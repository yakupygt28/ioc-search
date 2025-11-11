// lib/screens/result_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ioc_service.dart';
import 'dart:math';

class ResultsScreen extends StatefulWidget {
  final String domain;
  const ResultsScreen({super.key, required this.domain});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  Map<String, dynamic>? data;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      loading = true;
      error = null;
      data = null;
    });

    final res = await IocService.fetchIoc(widget.domain);
    setState(() {
      loading = res.loading;
      error = res.error;
      data = res.data;
    });
  }

  int _int(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  List _list(dynamic v) {
    if (v == null) return [];
    if (v is List) return v;
    if (v is Map) return v.entries.map((e) => e.value).toList();
    return [];
  }

  /// Güncellenmiş overall risk hesaplama (hassasiyet artırıldı)
  String calculateRisk() {
    if (data == null) return 'N/A';

    if (data!['risk'] != null) return data!['risk'].toString();
    if (data!['overall_risk'] != null) return data!['overall_risk'].toString();

    int malicious = 0;
    int harmless = 0;
    int undetected = 0;

    if (data!['security_vendor_analysis_stats'] is Map) {
      final stats = Map<String, dynamic>.from(data!['security_vendor_analysis_stats']);
      malicious += _int(stats['malicious']);
      harmless += _int(stats['harmless']);
      undetected += _int(stats['undetected']);
    }

    if (data!['votes_result'] is Map) {
      final votes = Map<String, dynamic>.from(data!['votes_result']);
      malicious += _int(votes['malicious']);
      harmless += _int(votes['harmless']);
    }

    final listCandidates = <dynamic>[];
    if (data!['_raw_data'] is List) listCandidates.addAll(data!['_raw_data']);
    if (data!['domains'] is List) listCandidates.addAll(data!['domains']);
    if (data!['results'] is List) listCandidates.addAll(data!['results']);
    for (var item in listCandidates) {
      if (item is Map && item['security_vendor_analysis_stats'] is Map) {
        final s = Map<String, dynamic>.from(item['security_vendor_analysis_stats']);
        malicious += _int(s['malicious']);
        harmless += _int(s['harmless']);
        undetected += _int(s['undetected']);
      } else if (item is Map && item['votes_result'] is Map) {
        final v = Map<String, dynamic>.from(item['votes_result']);
        malicious += _int(v['malicious']);
        harmless += _int(v['harmless']);
      }
    }

    int total = malicious + harmless + undetected;

    if (total == 0) {
      final extraIndicators =
          max(1, _list(data?['communicating_files']).length + _list(data?['resolved_ips']).length);
      if (extraIndicators >= 5) return 'MEDIUM';
      if (extraIndicators >= 1) return 'LOW';
      return 'LOW';
    }

    final ratio = malicious / total;
    if (ratio >= 0.5) return 'HIGH';
    if (ratio >= 0.1) return 'MEDIUM';
    return 'LOW';
  }

  Color riskColor(String r) {
    switch (r.toUpperCase()) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _openVirusTotal() async {
    final uri = Uri.parse('https://www.virustotal.com/gui/domain/${widget.domain}');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Map<String, int> prepareDetectionCounts() {
    if (data == null) return {'malicious': 0, 'clean': 0, 'undetected': 0};

    int malicious = 0, clean = 0, undetected = 0;

    if (data!['security_vendor_analysis_stats'] is Map) {
      final stats = Map<String, dynamic>.from(data!['security_vendor_analysis_stats']);
      malicious += _int(stats['malicious']);
      clean += _int(stats['harmless']);
      undetected += _int(stats['undetected']);
    }

    if (data!['votes_result'] is Map) {
      final votes = Map<String, dynamic>.from(data!['votes_result']);
      malicious += _int(votes['malicious']);
      clean += _int(votes['harmless']);
    }

    final listCandidates = <dynamic>[];
    if (data!['_raw_data'] is List) listCandidates.addAll(data!['_raw_data']);
    if (data!['domains'] is List) listCandidates.addAll(data!['domains']);
    if (data!['results'] is List) listCandidates.addAll(data!['results']);
    for (var it in listCandidates) {
      if (it is Map) {
        if (it['security_vendor_analysis_stats'] is Map) {
          final s = Map<String, dynamic>.from(it['security_vendor_analysis_stats']);
          malicious += _int(s['malicious']);
          clean += _int(s['harmless']);
          undetected += _int(s['undetected']);
        } else if (it['votes_result'] is Map) {
          final v = Map<String, dynamic>.from(it['votes_result']);
          malicious += _int(v['malicious']);
          clean += _int(v['harmless']);
        }
      }
    }

    if (malicious == 0 && clean == 0 && undetected == 0) {
      if (_list(data?['resolved_ips']).isNotEmpty) undetected = _list(data?['resolved_ips']).length;
      if (_list(data?['communicating_files']).isNotEmpty) clean = _list(data?['communicating_files']).length;
    }

    return {'malicious': malicious, 'clean': clean, 'undetected': undetected};
  }

  @override
  Widget build(BuildContext context) {
    final risk = calculateRisk();
    final detectionCounts = prepareDetectionCounts();

    final maliciousCount = detectionCounts['malicious'] ?? 0;
    final cleanCount = detectionCounts['clean'] ?? 0;
    final undetectedCount = detectionCounts['undetected'] ?? 0;
    final totalDetections = maliciousCount + cleanCount + undetectedCount;

    return Scaffold(
      appBar: AppBar(
        title: Text('Results — ${widget.domain}'),
        actions: [IconButton(onPressed: _fetch, icon: const Icon(Icons.refresh))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                          color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Threat Intelligence Dashboard',
                            style: TextStyle(
                                color: Color(0xFF96A0FF),
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Card(
                          color: riskColor(risk),
                          child: ListTile(
                            title: const Text('Overall Risk', style: TextStyle(color: Colors.white)),
                            subtitle: Text(risk,
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            trailing: const Icon(Icons.shield, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: const Color(0xFF0F1B22),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white10)),
                          child: Text(
                            data?['overview_text']?.toString() ??
                                data?['summary']?.toString() ??
                                (data != null
                                    ? 'This domain has been associated with suspicious activity. Multiple security vendors have flagged it as potentially malicious.'
                                    : ''),
                            style: const TextStyle(color: Color(0xFFFFD8A6)),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('SECURITY VENDORS', style: TextStyle(color: Colors.white54)),
                          const SizedBox(height: 8),
                          Text('$maliciousCount/$totalDetections',
                              style: const TextStyle(
                                  fontSize: 28, color: Color(0xFFFA5B5B), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('Malicious detections (aggregated)',
                              style: TextStyle(color: Colors.white60)),
                        ]),
                      ),
                    ),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('RESOLVED IPS', style: TextStyle(color: Colors.white54)),
                          const SizedBox(height: 8),
                          Text('${max(1, _list(data?['resolved_ips']).length)}',
                              style: const TextStyle(
                                  fontSize: 28, color: Color(0xFF3FA0FF), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('Historical resolutions', style: TextStyle(color: Colors.white60)),
                        ]),
                      ),
                    ),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('SUBDOMAINS', style: TextStyle(color: Colors.white54)),
                          const SizedBox(height: 8),
                          Text('${_list(data?['subdomains']).length + _list(data?['domains']).length}',
                              style: const TextStyle(
                                  fontSize: 28, color: Color(0xFF9B6BFF), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('Associated subdomains', style: TextStyle(color: Colors.white60)),
                        ]),
                      ),
                    ),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('COMMUNICATING FILES', style: TextStyle(color: Colors.white54)),
                          const SizedBox(height: 8),
                          Text('${max(1, _list(data?['communicating_files']).length)}',
                              style: const TextStyle(
                                  fontSize: 28, color: Color(0xFFF6A200), fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('Related file detected', style: TextStyle(color: Colors.white60)),
                        ]),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(children: [
                          const Align(
                              alignment: Alignment.centerLeft,
                              child:
                                  Text('Detection Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 180,
                            child: Row(
                              children: [
                                Expanded(
                                  child: PieChart(PieChartData(
                                    sections: [
                                      PieChartSectionData(
                                          value: (maliciousCount).toDouble(),
                                          color: const Color(0xFFFA5B5B),
                                          radius: 40,
                                          showTitle: false),
                                      PieChartSectionData(
                                          value: (cleanCount).toDouble(),
                                          color: const Color(0xFF36C172),
                                          radius: 50,
                                          showTitle: false),
                                      PieChartSectionData(
                                          value: (undetectedCount).toDouble(),
                                          color: Colors.grey.shade700,
                                          radius: 35,
                                          showTitle: false),
                                    ],
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 30,
                                  )),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    legendRow(Colors.red, 'Malicious'),
                                    const SizedBox(height: 8),
                                    legendRow(const Color(0xFF36C172), 'Clean'),
                                    const SizedBox(height: 8),
                                    legendRow(Colors.grey, 'Undetected'),
                                  ],
                                )
                              ],
                            ),
                          )
                        ]),
                      ),
                    ),

                    const SizedBox(height: 18),
                    // **Key Findings güncel**
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Key Findings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Text(
                            data?['key_findings']?.toString() ??
                            data?['summary']?.toString() ??
                            (() {
                              if (data == null) return 'N/A';
                              int malicious = 0;
                              int harmless = 0;

                              if (data!['security_vendor_analysis_stats'] is Map) {
                                final s = Map<String, dynamic>.from(data!['security_vendor_analysis_stats']);
                                malicious += int.tryParse(s['malicious']?.toString() ?? '0') ?? 0;
                                harmless += int.tryParse(s['harmless']?.toString() ?? '0') ?? 0;
                              }
                              if (data!['votes_result'] is Map) {
                                final v = Map<String, dynamic>.from(data!['votes_result']);
                                malicious += int.tryParse(v['malicious']?.toString() ?? '0') ?? 0;
                                harmless += int.tryParse(v['harmless']?.toString() ?? '0') ?? 0;
                              }

                              final parts = <String>[];
                              if (malicious > 0) parts.add('$malicious vendor(s) flagged this domain as malicious');
                              if (harmless > 0) parts.add('$harmless vendor(s) flagged this domain as harmless');

                              final subdomains = _list(data?['subdomains']).length + _list(data?['domains']).length;
                              if (subdomains > 0) parts.add('$subdomains associated subdomain(s) found');

                              final resolvedIps = _list(data?['resolved_ips']).length;
                              if (resolvedIps > 0) parts.add('$resolvedIps resolved IP(s)');

                              final files = _list(data?['communicating_files']).length;
                              if (files > 0) parts.add('$files communicating file(s)');

                              if (parts.isEmpty) return 'No significant findings';
                              return parts.join('\n');
                            })()
                          ),
                        ]),
                      ),
                    ),

                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                        onPressed: _openVirusTotal,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open in VirusTotal')),

                    const SizedBox(height: 18),
                    Card(
                      child: ExpansionTile(
                        title: const Text('Raw JSON (debug)', style: TextStyle(fontWeight: FontWeight.bold)),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            color: const Color(0xFF081018),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                JsonEncoder.withIndent('  ').convert(data ?? {}),
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ]),
                ),
    );
  }

  Widget legendRow(Color c, String label) {
    return Row(
      children: [
        Container(width: 18, height: 12, color: c),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
