import 'dart:convert';
import 'package:http/http.dart' as http;

// Model data dari log penyiraman
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

  // konversi ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tanggal': tanggal.toIso8601String(),
      'waktu': waktu,
      'volume': volume,
      'status': status,
      'durasi': durasi,
    };
  }

  // Create dari JSON
  factory PenyiramanLog.fromJson(Map<String, dynamic> json) {
    return PenyiramanLog(
      id: json['id'] as String,
      tanggal: DateTime.parse(json['tanggal'] as String),
      waktu: json['waktu'] as String,
      volume: (json['volume'] as num).toDouble(),
      status: json['status'] as String,
      durasi: json['durasi'] as String,
    );
  }

  // copy denganmethod untuk update beberapa field
  PenyiramanLog copyWith({
    String? id,
    DateTime? tanggal,
    String? waktu,
    double? volume,
    String? status,
    String? durasi,
  }) {
    return PenyiramanLog(
      id: id ?? this.id,
      tanggal: tanggal ?? this.tanggal,
      waktu: waktu ?? this.waktu,
      volume: volume ?? this.volume,
      status: status ?? this.status,
      durasi: durasi ?? this.durasi,
    );
  }
}

// API Service untuk CRUD log penyiraman
class PenyiramanLogService {
  // Base URL API - sesuaikan dengan backend nanti
  static const String baseUrl = 'http://localhost:8000/api';
  static const String endpoint = '$baseUrl/log-penyiraman';

  // Custom exception untuk error handling
  static Future<void> _handleResponse(http.Response response) async {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Terjadi kesalahan: ${response.statusCode}');
    }
  }

  // CREATE - Tambah log penyiraman baru
  static Future<PenyiramanLog> createPenyiramanLog({
    required DateTime tanggal,
    required String waktu,
    required double volume,
    required String status,
    required String durasi,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'tanggal': tanggal.toIso8601String(),
          'waktu': waktu,
          'volume': volume,
          'status': status,
          'durasi': durasi,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      await _handleResponse(response);

      final jsonData = jsonDecode(response.body);
      return PenyiramanLog.fromJson(jsonData['data']);
    } catch (e) {
      throw Exception('Gagal membuat log penyiraman: $e');
    }
  }

  // READ - Ambil semua log penyiraman
  static Future<List<PenyiramanLog>> getAllPenyiramanLogs({
    int? page,
    int? limit,
    String? sortBy = 'tanggal',
    String? sortOrder = 'desc',
  }) async {
    try {
      final queryParams = <String, String>{
        if (page != null) 'page': page.toString(),
        if (limit != null) 'limit': limit.toString(),
        'sortBy': sortBy ?? 'tanggal',
        'sortOrder': sortOrder ?? 'desc',
      };

      final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      await _handleResponse(response);

      final jsonData = jsonDecode(response.body);
      final List<dynamic> data = jsonData['data'] ?? [];
      return data.map((item) => PenyiramanLog.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil log penyiraman: $e');
    }
  }

  // READ - Ambil log penyiraman berdasarkan ID
  static Future<PenyiramanLog> getPenyiramanLogById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$endpoint/$id'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      await _handleResponse(response);

      final jsonData = jsonDecode(response.body);
      return PenyiramanLog.fromJson(jsonData['data']);
    } catch (e) {
      throw Exception('Gagal mengambil log penyiraman: $e');
    }
  }

  // READ - Ambil log penyiraman dengan filter tanggal
  static Future<List<PenyiramanLog>> getPenyiramanLogsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final queryParams = {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };

      final uri = Uri.parse('$endpoint/filter/date').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      await _handleResponse(response);

      final jsonData = jsonDecode(response.body);
      final List<dynamic> data = jsonData['data'] ?? [];
      return data.map((item) => PenyiramanLog.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil log penyiraman: $e');
    }
  }

  // READ - Ambil log penyiraman dengan filter status
  static Future<List<PenyiramanLog>> getPenyiramanLogsByStatus(String status) async {
    try {
      final queryParams = {'status': status};

      final uri = Uri.parse('$endpoint/filter/status').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      await _handleResponse(response);

      final jsonData = jsonDecode(response.body);
      final List<dynamic> data = jsonData['data'] ?? [];
      return data.map((item) => PenyiramanLog.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil log penyiraman: $e');
    }
  }

  // UPDATE - Update log penyiraman
  static Future<PenyiramanLog> updatePenyiramanLog({
    required String id,
    DateTime? tanggal,
    String? waktu,
    double? volume,
    String? status,
    String? durasi,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (tanggal != null) body['tanggal'] = tanggal.toIso8601String();
      if (waktu != null) body['waktu'] = waktu;
      if (volume != null) body['volume'] = volume;
      if (status != null) body['status'] = status;
      if (durasi != null) body['durasi'] = durasi;

      final response = await http.put(
        Uri.parse('$endpoint/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      await _handleResponse(response);

      final jsonData = jsonDecode(response.body);
      return PenyiramanLog.fromJson(jsonData['data']);
    } catch (e) {
      throw Exception('Gagal mengupdate log penyiraman: $e');
    }
  }

  // UPDATE - Update status log penyiraman
  static Future<PenyiramanLog> updatePenyiramanLogStatus({
    required String id,
    required String status,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$endpoint/$id/status'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'status': status}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      await _handleResponse(response);

      final jsonData = jsonDecode(response.body);
      return PenyiramanLog.fromJson(jsonData['data']);
    } catch (e) {
      throw Exception('Gagal mengupdate status log penyiraman: $e');
    }
  }

  // DELETE - Hapus log penyiraman
  static Future<void> deletePenyiramanLog(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$endpoint/$id'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      await _handleResponse(response);
    } catch (e) {
      throw Exception('Gagal menghapus log penyiraman: $e');
    }
  }

  // DELETE - Hapus multiple log penyiraman
  static Future<void> deletePenyiramanLogsBatch(List<String> ids) async {
    try {
      final response = await http.post(
        Uri.parse('$endpoint/batch-delete'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'ids': ids}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      await _handleResponse(response);
    } catch (e) {
      throw Exception('Gagal menghapus log penyiraman: $e');
    }
  }

  // Utility - Dapatkan statistik log penyiraman
  static Future<Map<String, dynamic>> getPenyiramanStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      final uri = Uri.parse('$endpoint/statistics').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      await _handleResponse(response);

      final jsonData = jsonDecode(response.body);
      return jsonData['data'] ?? {};
    } catch (e) {
      throw Exception('Gagal mengambil statistik: $e');
    }
  }

  // Utility - Export log penyiraman ke CSV
  static Future<String> exportToCsv({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      final uri = Uri.parse('$endpoint/export/csv').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'text/csv',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      await _handleResponse(response);
      return response.body;
    } catch (e) {
      throw Exception('Gagal mengexport data: $e');
    }
  }
}
