import 'package:flutter/material.dart';

class log_penyiraman extends StatefulWidget {
  const log_penyiraman({super.key});

  @override
  State<log_penyiraman> createState() => _log_penyiramanState();
}

class _log_penyiramanState extends State<log_penyiraman> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.water_drop, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            'Halaman Log Penyiraman',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Ini adalah halaman log penyiraman'),
        ],
      ),
    );
  }
}