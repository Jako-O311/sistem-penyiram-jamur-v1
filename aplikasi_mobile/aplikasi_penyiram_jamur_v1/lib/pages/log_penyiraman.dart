import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Model data untuk log penyiraman
class PenyiramanLog {
  final String id;
  final DateTime tanggal;
  final String waktu;
  final double volume;
  final String status;
  final String durasi;

  PenyiramanLog({
    required this.id,
    required this.tanggal,
    required this.waktu,
    required this.volume,
    required this.status,
    required this.durasi,
  });
}

enum SortOrder { ascending, descending }

class log_penyiraman extends StatefulWidget {
  const log_penyiraman({super.key});

  @override
  State<log_penyiraman> createState() => _log_penyiramanState();
}

class _log_penyiramanState extends State<log_penyiraman> {
  late List<PenyiramanLog> allLogs;
  late List<PenyiramanLog> filteredLogs;
  SortOrder sortOrder = SortOrder.descending;
  DateTimeRange? selectedDateRange;

  @override
  void initState() {
    super.initState();
    allLogs = _generateSampleData();
    _sortAndFilterLogs();
  }

  // Generate sample data untuk demo
  List<PenyiramanLog> _generateSampleData() {
    final now = DateTime.now();
    return [
      PenyiramanLog(
        id: '1',
        tanggal: now,
        waktu: '08:30',
        volume: 5.5,
        status: 'Berhasil',
        durasi: '2m 15s',
      ),
      PenyiramanLog(
        id: '2',
        tanggal: now.subtract(const Duration(days: 1)),
        waktu: '09:15',
        volume: 5.0,
        status: 'Berhasil',
        durasi: '2m 10s',
      ),
      PenyiramanLog(
        id: '3',
        tanggal: now.subtract(const Duration(days: 2)),
        waktu: '10:00',
        volume: 6.0,
        status: 'Gagal',
        durasi: '1m 45s',
      ),
      PenyiramanLog(
        id: '4',
        tanggal: now.subtract(const Duration(days: 3)),
        waktu: '07:45',
        volume: 5.2,
        status: 'Berhasil',
        durasi: '2m 08s',
      ),
      PenyiramanLog(
        id: '5',
        tanggal: now.subtract(const Duration(days: 4)),
        waktu: '08:30',
        volume: 5.8,
        status: 'Berhasil',
        durasi: '2m 20s',
      ),
      PenyiramanLog(
        id: '6',
        tanggal: now.subtract(const Duration(days: 5)),
        waktu: '09:00',
        volume: 5.3,
        status: 'Berhasil',
        durasi: '2m 12s',
      ),
      PenyiramanLog(
        id: '7',
        tanggal: now.subtract(const Duration(days: 6)),
        waktu: '08:45',
        volume: 5.5,
        status: 'Berhasil',
        durasi: '2m 18s',
      ),
      PenyiramanLog(
        id: '8',
        tanggal: now.subtract(const Duration(days: 7)),
        waktu: '10:30',
        volume: 6.2,
        status: 'Gagal',
        durasi: '1m 50s',
      ),
    ];
  }

  void _sortAndFilterLogs() {
    filteredLogs = List.from(allLogs);

    // Filter berdasarkan range tanggal jika dipilih
    if (selectedDateRange != null) {
      filteredLogs = filteredLogs.where((log) {
        return log.tanggal.isAfter(selectedDateRange!.start.subtract(const Duration(days: 1))) &&
            log.tanggal.isBefore(selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Sort berdasarkan urutan yang dipilih
    if (sortOrder == SortOrder.ascending) {
      filteredLogs.sort((a, b) => a.tanggal.compareTo(b.tanggal));
    } else {
      filteredLogs.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    }

    setState(() {});
  }

  void _toggleSortOrder() {
    sortOrder =
        sortOrder == SortOrder.ascending ? SortOrder.descending : SortOrder.ascending;
    _sortAndFilterLogs();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: selectedDateRange ?? DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 7)),
        end: DateTime.now(),
      ),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      selectedDateRange = picked;
      _sortAndFilterLogs();
    }
  }

  void _clearDateFilter() {
    selectedDateRange = null;
    _sortAndFilterLogs();
  }

  Color _getStatusColor(String status) {
    return status == 'Berhasil' ? Colors.green : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header dengan filtering dan sorting
          Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Log Penyiraman',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.sort),
                      onPressed: _toggleSortOrder,
                      tooltip:
                          'Sort: ${sortOrder == SortOrder.ascending ? 'Lama ke Baru' : 'Baru ke Lama'}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Filter dan button
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDateRange(context),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 18, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedDateRange != null
                                      ? '${DateFormat('dd MMM yyyy').format(selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(selectedDateRange!.end)}'
                                      : 'Pilih Rentang Tanggal',
                                  style: TextStyle(
                                    color: selectedDateRange != null
                                        ? Colors.black
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (selectedDateRange != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearDateFilter,
                        tooltip: 'Hapus Filter',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // List dengan scrolling
          Expanded(
            child: filteredLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada data',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      return _buildLogCard(log);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(PenyiramanLog log) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tanggal dan waktu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Text(
                //   "test",
                //   style: const TextStyle(
                //     fontWeight: FontWeight.bold,
                //     fontSize: 14,
                //   ),
                // ),
                Text(
                  // DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(log.tanggal),
                  log.tanggal.toLocal().toString().split(' ')[0],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  log.waktu,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Status, Volume, Durasi
            Row(
              children: [
                // Status
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(log.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    log.status,
                    style: TextStyle(
                      color: _getStatusColor(log.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Volume
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.water_drop, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        '${log.volume} L',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Durasi
                Row(
                  children: [
                    Icon(Icons.timer, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      log.durasi,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}