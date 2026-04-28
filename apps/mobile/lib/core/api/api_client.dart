import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;
import '../config/app_config.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = Supabase.instance.client.auth.currentSession?.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // Attach status code to error message so callers can check it
        handler.next(error);
      },
    ));
  }

  // ── Users ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> upsertMe(Map<String, dynamic> body) async {
    final res = await _dio.put('/users/me', data: body);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/users/me');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getQuota() async {
    final res = await _dio.get('/users/me/quota');
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteMe() async {
    await _dio.delete('/users/me');
  }

  /// Returns the URL for the HTML export — open in browser or share
  String scanExportUrl(String scanId) => '${AppConfig.apiBaseUrl}/scans/$scanId/pdf';

  Future<Map<String, dynamic>> verifySubscription({
    required String platform,
    required String productId,
    required String receipt,
  }) async {
    final res = await _dio.post('/subscriptions/verify', data: {
      'platform': platform,
      'productId': productId,
      'receipt': receipt,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    final res = await _dio.get('/subscriptions/status');
    return res.data as Map<String, dynamic>;
  }

  Future<void> sendFeedback({
    required String comment,
    String? type,
    int? rating,
    String? scanId,
  }) async {
    await _dio.post('/feedback', data: {
      'comment': comment,
      if (type != null) 'type': type,
      if (rating != null) 'rating': rating,
      if (scanId != null) 'scanId': scanId,
    });
  }

  // ── Scans ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> createScan({
    required List<int> imageBytes,
    required String mimeType,
    required String category,
    String lang = 'en',
  }) async {
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        imageBytes,
        filename: 'label.jpg',
        contentType: DioMediaType.parse(mimeType),
      ),
      'category': category,
      'lang': lang,
    });
    final res = await _dio.post(
      '/scans',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getScan(String id) async {
    final res = await _dio.get('/scans/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> listScans({int page = 1, int limit = 20}) async {
    final res = await _dio.get('/scans', queryParameters: {'page': page, 'limit': limit});
    return res.data as Map<String, dynamic>;
  }

  Future<void> savePurchaseIntent(String scanId, String decision, {String? reason}) async {
    await _dio.put('/scans/$scanId/intent', data: {
      'decision': decision,
      if (reason != null) 'reason': reason,
    });
  }
}
