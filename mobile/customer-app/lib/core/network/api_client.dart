import 'package:dio/dio.dart';
import '../storage/storage_service.dart';

class ApiClient {
  static const String _defaultBaseUrl = 'https://ecomargin-app.onrender.com/api/v1';
  final Dio _dio;
  final StorageService _storageService;

  ApiClient(this._storageService) : _dio = Dio() {
    _dio.options.baseUrl = const String.fromEnvironment('API_URL', defaultValue: _defaultBaseUrl);
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Content-Type'] = 'application/json';
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Handle token refresh logic here in a real production scenario
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
