import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class ApiService {
  // --- Link API ---
  // Gunakan localhost untuk Desktop/Web, atau 10.0.2.2 untuk Emulator Android
  final String _baseUrl = "http://10.0.2.2:8000/api";
  // final String _baseUrl = "http://localhost:8000/api";

  String get storageUrl => _baseUrl.replaceAll('/api', '/storage');

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      throw Exception('Token tidak ditemukan. Silakan login kembali.');
    }
    return token;
  }

  dynamic _handleResponse(http.Response response) {
    dynamic body;
    try {
      body = json.decode(response.body);
    } catch (e) {
      body = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      if (response.statusCode == 401) {
        if (body is Map && body.containsKey('message')) {
          final serverMessage = body['message'];
          // Jika pesan bukan generic "Unauthenticated", tampilkan pesan dari server
          // (misal: "Email atau Password salah")
          if (serverMessage != 'Unauthenticated.') {
            throw Exception(serverMessage);
          }
        }
        throw Exception(
          'Sesi berakhir atau tidak valid (Unauthorized). Silakan login ulang.',
        );
      }
      if (response.statusCode == 403) {
        if (body is Map && body.containsKey('message')) {
          throw Exception(body['message']);
        }
        throw Exception(
          'Anda tidak memiliki akses untuk fitur ini (Forbidden).',
        );
      }

      // Handle 422 Validation Errors
      if (response.statusCode == 422 && body is Map<String, dynamic>) {
        Map<String, dynamic> errors = {};
        if (body.containsKey('errors')) {
          errors = body['errors'];
        } else {
          // Asumsi body langsung berisi map error (Laravel default validator response)
          errors = body;
        }

        if (errors.isNotEmpty) {
          String errorMessage = body['message'] ?? 'Validasi gagal';
          // Jika tidak ada pesan spesifik di root, reset default message agar tidak redundan
          if (!body.containsKey('message')) {
            errorMessage = 'Validasi gagal';
          }

          final errorList = errors.values
              .map((e) {
                if (e is List) return e.join(', ');
                return e.toString();
              })
              .where((s) => s.isNotEmpty) // Filter string kosong
              .join('\n');

          if (errorList.isNotEmpty) {
            errorMessage += ':\n$errorList';
          }
          throw Exception(errorMessage);
        }
      }

      if (body is Map<String, dynamic> && body.containsKey('message')) {
        throw Exception(body['message']);
      }

      throw Exception(
        'Gagal memproses permintaan. Status code: ${response.statusCode}',
      );
    }
  }

  Future<dynamic> _safeCall(Future<dynamic> Function() call) async {
    try {
      return await call();
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        throw Exception('Tidak ada koneksi internet. Periksa jaringan Anda.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _safeCall(() async {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      );
      return _handleResponse(response);
    });
    return response as Map<String, dynamic>;
  }

  Future<dynamic> register(
    Map<String, String> data,
    List<int> ktpBytes,
    String ktpFilename,
  ) async {
    return _safeCall(() async {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/register'),
      );
      request.headers['Accept'] = 'application/json';
      request.fields.addAll(data);

      if (ktpBytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'ktp_path',
            ktpBytes,
            filename: ktpFilename,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    });
  }

  Future<dynamic> get(String endpoint) async {
    return _safeCall(() async {
      String token = await _getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return _handleResponse(response);
    });
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    return _safeCall(() async {
      String token = await _getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    });
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    return _safeCall(() async {
      String token = await _getToken();
      final response = await http.put(
        Uri.parse('$_baseUrl/$endpoint'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    });
  }

  Future<dynamic> delete(String endpoint) async {
    String token = await _getToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    return _handleResponse(response);
  }

  Future<dynamic> ajukanPenarikan(Map<String, dynamic> data) async {
    return await post('my-simpanan/tarik', data);
  }

  // --- Karyawan ---

  Future<Map<String, dynamic>> getKaryawanDashboard() async {
    final responseData = await get('karyawan/dashboard');
    return responseData as Map<String, dynamic>;
  }

  Future<List<dynamic>> getAnggota() async {
    final responseData = await get('anggota');
    if (responseData is List) {
      return responseData;
    } else if (responseData is Map && responseData.containsKey('data')) {
      return responseData['data'] as List<dynamic>;
    }
    throw Exception('Format data anggota tidak valid');
  }

  Future<List<dynamic>> getAnggotaSampah() async {
    final responseData = await get('anggota/sampah');
    if (responseData is List) {
      return responseData;
    } else if (responseData is Map && responseData.containsKey('data')) {
      return responseData['data'] as List<dynamic>;
    }
    throw Exception('Format data sampah tidak valid');
  }

  Future<dynamic> restoreAnggota(int id) async {
    return await post('anggota/$id/restore', {});
  }

  Future<dynamic> createAnggota(
    Map<String, String> data,
    List<int> ktpBytes,
    String ktpFilename,
  ) async {
    return _safeCall(() async {
      String token = await _getToken();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/anggota'),
      );
      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';

      request.fields.addAll(data);

      if (ktpBytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'ktp_path',
            ktpBytes,
            filename: ktpFilename,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    });
  }

  Future<dynamic> deleteAnggota(int id) async {
    return await delete('anggota/$id');
  }

  Future<dynamic> updateAnggota(int id, Map<String, String> data) async {
    return await put('anggota/$id', data);
  }

  Future<dynamic> verifyKtp(int id) async {
    return await post('anggota/$id/verify-ktp', {});
  }

  Future<dynamic> rejectKtp(int id, String reason) async {
    return await post('anggota/$id/reject-ktp', {'alasan_penolakan': reason});
  }

  Future<List<dynamic>> getPinjamanList(String status) async {
    final responseData = await get('pinjaman?status=$status');
    if (responseData is List) return responseData;
    if (responseData is Map && responseData.containsKey('data')) {
      return responseData['data'] as List<dynamic>;
    }
    return [];
  }

  Future<Map<String, dynamic>> getPinjamanDetail(int id) async {
    final responseData = await get('pinjaman/$id');
    return responseData as Map<String, dynamic>;
  }

  Future<dynamic> approvePinjaman(int id) async {
    return await post('pinjaman/$id/approve', {});
  }

  Future<dynamic> rejectPinjaman(int id, String alasan) async {
    return await post('pinjaman/$id/reject', {'alasan_penolakan': alasan});
  }

  Future<dynamic> requestRevision(int id, String reason) async {
    return await post('pinjaman/$id/revision', {'alasan_perbaikan': reason});
  }

  Future<List<dynamic>> getSimpananPending() async {
    final responseData = await get('simpanan');
    if (responseData is List) return responseData;
    if (responseData is Map && responseData.containsKey('data')) {
      return responseData['data'] as List<dynamic>;
    }
    return [];
  }

  Future<dynamic> approveSimpanan(int id) async {
    return await post('simpanan/$id/approve', {});
  }

  Future<dynamic> payAngsuran(int angsuranId) async {
    return await post('angsuran/$angsuranId/pay', {});
  }

  Future<dynamic> rejectAngsuran(int angsuranId, String alasan) async {
    return await post('angsuran/$angsuranId/reject', {'alasan_penolakan': alasan});
  }

  Future<List<dynamic>> getAllSimpanan() async {
    final responseData = await get(
      'simpanan',
    ); // Usually Karyawan can see all or use status query
    if (responseData is List) return responseData;
    if (responseData is Map && responseData.containsKey('data')) {
      return responseData['data'] as List<dynamic>;
    }
    return [];
  }

  Future<List<dynamic>> getAllAngsuran() async {
    // Assuming api/angsuran exists for Karyawan to list all.
    // If not, this might need fallback to iterating loans or api/laporan-ketua/angsuran
    final responseData = await get('angsuran'); // Attempting standard endpoint
    if (responseData is List) return responseData;
    if (responseData is Map && responseData.containsKey('data')) {
      return responseData['data'] as List<dynamic>;
    }
    return [];
  }

  // --- Nasabah ---

  Future<Map<String, dynamic>> getDashboardData() async {
    final responseData = await get('dashboard');
    return responseData as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    final responseData = await get('profile');
    return responseData as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadKtp(
    List<int> bytes,
    String filename,
  ) async {
    String token = await _getToken();
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/profile/upload-ktp'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.files.add(
      http.MultipartFile.fromBytes('ktp', bytes, filename: filename),
    );

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadProfilePhoto(
    List<int> bytes,
    String filename,
  ) async {
    String token = await _getToken();
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/profile/upload-photo'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response) as Map<String, dynamic>;
  }

  Future<dynamic> updateMyProfile(Map<String, String> data) async {
    return await put('profile', data);
  }

  Future<List<dynamic>> getMySimpanan() async {
    final responseData = await get('my-simpanan');
    if (responseData is List) return responseData;
    if (responseData is Map && responseData.containsKey('data')) {
      return responseData['data'] as List<dynamic>;
    }
    return [];
  }

  Future<dynamic> ajukanSimpanan(
    Map<String, String> data,
    List<int> bytes,
    String filename,
  ) async {
    String token = await _getToken();
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/my-simpanan'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.fields.addAll(data);
    request.files.add(
      http.MultipartFile.fromBytes('bukti_transfer', bytes, filename: filename),
    );

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  Future<dynamic> confirmAngsuran(
    int angsuranId,
    List<int> bytes,
    String filename,
  ) async {
    String token = await _getToken();
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/my-angsuran/$angsuranId/confirm'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.files.add(
      http.MultipartFile.fromBytes('bukti_bayar', bytes, filename: filename),
    );

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  Future<List<dynamic>> getMyPinjaman() async {
    final responseData = await get('my-pinjaman');
    if (responseData is List) return responseData;
    if (responseData is Map && responseData.containsKey('data')) {
      return responseData['data'] as List<dynamic>;
    }
    return [];
  }

  Future<Map<String, dynamic>> getMyPinjamanDetail(int id) async {
    final responseData = await get('my-pinjaman/$id');
    return responseData as Map<String, dynamic>;
  }

  Future<dynamic> ajukanPinjaman(
    Map<String, String> data,
    Map<String, List<int>> fileBytes,
    Map<String, String> fileNames,
  ) async {
    String token = await _getToken();
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/my-pinjaman'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.fields.addAll(data);

    fileBytes.forEach((key, bytes) {
      if (fileNames.containsKey(key)) {
        request.files.add(
          http.MultipartFile.fromBytes(key, bytes, filename: fileNames[key]),
        );
      }
    });

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  Future<dynamic> updatePinjaman(
    int id,
    Map<String, String> data,
    Map<String, List<int>> fileBytes,
    Map<String, String> fileNames,
  ) async {
    String token = await _getToken();
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/my-pinjaman/$id/update'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.fields.addAll(data);

    fileBytes.forEach((key, bytes) {
      if (fileNames.containsKey(key)) {
        request.files.add(
          http.MultipartFile.fromBytes(key, bytes, filename: fileNames[key]),
        );
      }
    });

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  // --- Ketua ---

  Future<Map<String, dynamic>> getKetuaReports() async {
    final responseData = await get('laporan-ketua');
    return responseData as Map<String, dynamic>;
  }

  Future<List<dynamic>> getPinjamanKetua() async {
    final responseData = await get('laporan/pinjaman');
    if (responseData is List) return responseData;
    if (responseData is Map && responseData.containsKey('data')) {
      return responseData['data'] as List<dynamic>;
    }
    return [];
  }

  Future<List<dynamic>> getSimpananKetua() async {
    final responseData = await get('laporan/simpanan');
    if (responseData is List) return responseData;
    if (responseData is Map && responseData.containsKey('data')) {
      return responseData['data'] as List<dynamic>;
    }
    return [];
  }

  Future<List<dynamic>> getAngsuranKetua() async {
    final responseData = await get('laporan/angsuran');
    if (responseData is List) return responseData;
    if (responseData is Map && responseData.containsKey('data')) {
      return responseData['data'] as List<dynamic>;
    }
    return [];
  }

  // --- Pengaturan Bunga (Ketua) ---

  Future<List<dynamic>> getBungaSettings() async {
    final responseData = await get('bunga-settings');
    if (responseData is List) return responseData;
    // Handle pagination or wrapped data if necessary
    return [];
  }

  Future<dynamic> createBungaSetting(Map<String, dynamic> data) async {
    return await post('bunga-settings', data);
  }

  Future<dynamic> updateBungaSetting(int id, Map<String, dynamic> data) async {
    return await put('bunga-settings/$id', data);
  }

  Future<dynamic> deleteBungaSetting(int id) async {
    return await delete('bunga-settings/$id');
  }

  // --- Password Management ---

  Future<dynamic> updatePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    return await put('update-password', {
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirmation': confirmPassword,
    });
  }

  Future<dynamic> resetPasswordMember(int id) async {
    return await post('anggota/$id/reset-password', {});
  }

  // --- PDF DOWNLOADER ---
  Future<String> downloadPdf(String endpoint, String filename, {int? bulan, int? tahun}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    // Bangun URL dengan query params
    String url = '$_baseUrl/$endpoint?';
    if (bulan != null) url += 'bulan=$bulan&';
    if (tahun != null) url += 'tahun=$tahun&';
    
    if (url.endsWith('&') || url.endsWith('?')) {
      url = url.substring(0, url.length - 1);
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(response.bodyBytes);
      
      // Buka file pdf-nya
      await OpenFile.open(file.path);
      return file.path;
    } else {
      throw Exception('Gagal mengunduh PDF: ${response.statusCode}');
    }
  }
}
