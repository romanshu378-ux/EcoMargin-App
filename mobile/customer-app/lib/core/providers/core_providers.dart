import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/storage_service.dart';
import '../network/api_client.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(); // Needs to be initialized in main()
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return ApiClient(storageService);
});

// A simple auth state provider based on JWT token presence
final authStateProvider = StateProvider<bool>((ref) => false);
