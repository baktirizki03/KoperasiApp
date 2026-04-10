import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class SecureImageWidget extends StatefulWidget {
  final String imageUrl; // Format: /api/dokumen/folder/filename.enc
  final double? width;
  final double? height;
  final BoxFit fit;

  const SecureImageWidget({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  _SecureImageWidgetState createState() => _SecureImageWidgetState();
}

class _SecureImageWidgetState extends State<SecureImageWidget> {
  Uint8List? _imageData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchImage();
  }

  Future<void> _fetchImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Get base URL from ApiService
      // Since ApiService has a private _baseUrl, we can construct the base domain
      // by taking the storageUrl and replacing '/storage' with ''
      final apiService = ApiService();
      final baseDomain = apiService.storageUrl.replaceAll('/storage', '');

      final url = widget.imageUrl.startsWith('http')
          ? widget.imageUrl
          : '$baseDomain/api/dokumen/${widget.imageUrl.startsWith('/') ? widget.imageUrl.substring(1) : widget.imageUrl}';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json, image/*',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _imageData = response.bodyBytes;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat gambar (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat gambar';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _imageData == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }

    return Image.memory(
      _imageData!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }
}
