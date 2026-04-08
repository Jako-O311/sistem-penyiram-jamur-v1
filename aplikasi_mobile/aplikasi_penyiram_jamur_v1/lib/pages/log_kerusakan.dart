import 'package:flutter/material.dart';

class log_kerusakan extends StatefulWidget {
  const log_kerusakan({super.key});

  @override
  State<log_kerusakan> createState() => _log_kerusakanState();
}

class _log_kerusakanState extends State<log_kerusakan> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning, size: 64, color: Colors.orange),
          const SizedBox(height: 16),
          const Text(
            'Halaman Log Kerusakan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Ini adalah halaman log kerusakan'),
        ],
      ),
    );
  }
}