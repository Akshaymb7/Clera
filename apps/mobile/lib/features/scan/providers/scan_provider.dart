import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

class PendingScan {
  const PendingScan({
    required this.imageBytes,
    required this.mimeType,
    required this.category,
  });
  final List<int> imageBytes;
  final String mimeType;
  final String category;
}

class QuotaExceededException implements Exception {
  const QuotaExceededException(this.message);
  final String message;
  @override
  String toString() => message;
}

// Holds image + category selected on scan screen
final pendingScanProvider = StateProvider<PendingScan?>((ref) => null);

// Holds the latest scan result after analysis
final scanResultProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

// Notifier that orchestrates the scan + upload flow
final scanNotifierProvider =
    AsyncNotifierProvider<ScanNotifier, Map<String, dynamic>?>(ScanNotifier.new);

class ScanNotifier extends AsyncNotifier<Map<String, dynamic>?> {
  @override
  Future<Map<String, dynamic>?> build() async => null;

  Future<String?> analyze({
    required List<int> imageBytes,
    required String mimeType,
    required String category,
  }) async {
    state = const AsyncLoading();
    final api = ref.read(apiClientProvider);
    try {
      final result = await api.createScan(
        imageBytes: imageBytes,
        mimeType: mimeType,
        category: category,
      );
      state = AsyncData(result);
      ref.read(scanResultProvider.notifier).state = result;
      return result['id'] as String?;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        final msg = (e.response?.data as Map?)?['message'] as String? ?? 'Scan limit reached';
        state = AsyncError(QuotaExceededException(msg), StackTrace.current);
      } else {
        state = AsyncError(e, StackTrace.current);
      }
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}
