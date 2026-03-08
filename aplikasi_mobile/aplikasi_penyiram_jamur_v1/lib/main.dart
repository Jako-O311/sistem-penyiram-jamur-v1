import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // TODO: replace with your real device id and backend base URL
  final String deviceId = 'device-001';
  final String baseUrl = 'http://192.168.1.100:3000';

  // Removed unused counter and increment function

  Future<void> sendCommand(String command, [Map<String, dynamic>? params]) async {
    final uri = Uri.parse('$baseUrl/api/devices/$deviceId/command');
    final body = jsonEncode({'command': command, if (params != null) 'params': params});
    try {
      final resp = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: body).timeout(const Duration(seconds: 5));
      if (!mounted) return;
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perintah terkirim')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: ${resp.statusCode}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _toggleManual() => sendCommand('toggle_manual');
  void _toggleAuto() => sendCommand('toggle_auto');
  void _toggleScheduleCount() => sendCommand('toggle_schedule_count');

  void _openScheduleEditor() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SchedulePage(deviceId: deviceId, baseUrl: baseUrl)));
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              ElevatedButton(
                onPressed: _toggleManual,
                child: const Text('Siram Manual'),
              ),
              ElevatedButton(
                onPressed: _toggleAuto,
                child: const Text('Penyiram Otomatis'),
              ),
              ElevatedButton(
                onPressed: _toggleScheduleCount,
                child: const Text('1x / 2x per Jadwal'),
              ),
              ElevatedButton(
                onPressed: _openScheduleEditor,
                child: const Text('Ubah Jadwal'),
              ),
            ],
          ),
        ),
      ),
      
    );
  }
}

class SchedulePage extends StatefulWidget {
  final String deviceId;
  final String baseUrl;
  const SchedulePage({super.key, required this.deviceId, required this.baseUrl});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  TimeOfDay? _time;
  int _runs = 1;

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) setState(() => _time = t);
  }

  Future<void> _saveSchedule() async {
    if (_time == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih waktu dulu')));
      return;
    }
    final timeStr = _time!.format(context);
    final uri = Uri.parse('${widget.baseUrl}/api/devices/${widget.deviceId}/schedule');
    final body = jsonEncode({'schedules': [{'time': timeStr, 'runs': _runs}]});
    try {
      final resp = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: body).timeout(const Duration(seconds: 5));
      if (!mounted) return;
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jadwal disimpan')));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: ${resp.statusCode}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ubah Jadwal')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: Text(_time == null ? 'Pilih waktu' : 'Waktu: ${_time!.format(context)}'),
              trailing: ElevatedButton(onPressed: _pickTime, child: const Text('Pilih')),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Jumlah siraman per jadwal: '),
                const SizedBox(width: 8),
                DropdownButton<int>(value: _runs, items: const [DropdownMenuItem(value:1,child:Text('1')), DropdownMenuItem(value:2,child:Text('2'))], onChanged: (v){ if(v!=null) setState(()=>_runs=v); }),
              ],
            ),
            const Spacer(),
            ElevatedButton(onPressed: _saveSchedule, child: const Text('Simpan'))
          ],
        ),
      ),
    );
  }
}
