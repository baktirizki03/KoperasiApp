import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // --- Link API ---
  // Gunakan localhost untuk Desktop/Web, atau 10.0.2.2 untuk Emulator Android
  // final String _baseUrl = "http://10.0.2.2:8000/api";
  final String _baseUrl = "http://localhost:8000/api";

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
        throw Exception(
          'Sesi berakhir atau tidak valid (Unauthorized). Silakan login ulang.',
        );
      }
      if (response.statusCode == 403) {
        throw Exception(
          'Anda tidak memiliki akses untuk fitur ini (Forbidden).',
        );
      }
      if (body is Map<String, dynamic> && body.containsKey('message')) {
        throw Exception(body['message']);
      }

      throw Exception(
        'Gagal memproses permintaan. Status code: ${response.statusCode}',
      );
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(<String, String>{'email': email, 'password': password}),
    );
    return _handleResponse(response) as Map<String, dynamic>;
  }

  Future<dynamic> get(String endpoint) async {
    String token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
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
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
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
  }

  Future<dynamic> delete(String endpoint) async {
    String token = await _getToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    return _handleResponse(response);
  }

  // --- Karyawan ---

  Future<List<dynamic>> getAnggota() async {
    final responseData = await get('anggota');
    if (responseData is List) {
      return responseData;
    } else if (responseData is Map && responseData.containsKey('data')) {
      return responseData['data'] as List<dynamic>;
    }
    throw Exception('Format data anggota tidak valid');
  }

  Future<dynamic> createAnggota(Map<String, String> data) async {
    return await post('anggota', data);
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

  Future<List<dynamic>> getPinjamanList(String status) async {
    final responseData = await get('pinjaman?status=$status');
    if (responseData is List) return responseData;
    if (responseData is Map && responseData.containsKey('data'))
      return responseData['data'] as List<dynamic>;
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

  Future<List<dynamic>> getSimpananPending() async {
    final responseData = await get('simpanan');
    if (responseData is List) return responseData;
    if (responseData is Map && responseData.containsKey('data'))
      return responseData['data'] as List<dynamic>;
    return [];
  }

  Future<dynamic> approveSimpanan(int id) async {
    return await post('simpanan/$id/approve', {});
  }

  Future<dynamic> payAngsuran(int angsuranId) async {
    return await post('angsuran/$angsuranId/pay', {});
  }

  Future<List<dynamic>> getAllSimpanan() async {
    final responseData = await get(
      'simpanan',
    ); // Usually Karyawan can see all or use status query
    if (responseData is List) return responseData;
    if (responseData is Map && responseData.containsKey('data'))
      return responseData['data'] as List<dynamic>;
    return [];
  }

  Future<List<dynamic>> getAllAngsuran() async {
    // Assuming api/angsuran exists for Karyawan to list all.
    // If not, this might need fallback to iterating loans or api/laporan-ketua/angsuran
    final responseData = await get('angsuran'); // Attempting standard endpoint
    if (responseData is List) return responseData;
    if (responseData is Map && responseData.containsKey('data'))
      return responseData['data'] as List<dynamic>;
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

  Future<dynamic> updateMyProfile(Map<String, String> data) async {
    return await put('profile', data);
  }

  Future<List<dynamic>> getMySimpanan() async {
    final responseData = await get('my-simpanan');
    if (responseData is List) return responseData;
    if (responseData is Map && responseData.containsKey('data'))
      return responseData['data'] as List<dynamic>;
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
    if (responseData is Map && responseData.containsKey('data'))
      return responseData['data'] as List<dynamic>;
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

  // --- Ketua ---

  Future<Map<String, dynamic>> getKetuaReports() async {
    final responseData = await get('laporan-ketua');
    return responseData as Map<String, dynamic>;
  }

  Future<List<dynamic>> getPinjamanKetua() async {
    final responseData = await get('laporan-ketua/pinjaman');
    if (responseData is List) return responseData;
    if (responseData is Map && responseData.containsKey('data'))
      return responseData['data'] as List<dynamic>;
    return [];
  }

  Future<List<dynamic>> getSimpananKetua() async {
    final responseData = await get('laporan-ketua/simpanan');
    if (responseData is List) return responseData;
    if (responseData is Map && responseData.containsKey('data'))
      return responseData['data'] as List<dynamic>;
    return [];
  }

  Future<List<dynamic>> getAngsuranKetua() async {
    final responseData = await get('laporan-ketua/angsuran');
    if (responseData is List) return responseData;
    if (responseData is Map && responseData.containsKey('data'))
      return responseData['data'] as List<dynamic>;
    return [];
  }
}
