import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/providers/core_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'driver@ecomargin.com');
  final _passwordController = TextEditingController(text: 'driver123');
  bool _isLoading = false;

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _login() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar('Please enter your email and password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final storageService = ref.read(storageServiceProvider);

      if (kDebugMode) {
        debugPrint('[Login Attempt] Connecting to ${apiClient.dio.options.baseUrl}/auth/login');
      }

      final response = await apiClient.dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (kDebugMode) {
        debugPrint('[Login Response] HTTP Status: ${response.statusCode}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        String? token;

        if (data is Map<String, dynamic>) {
          token = data['accessToken'] as String? ??
              data['token'] as String? ??
              data['jwt'] as String?;
        }

        if (token != null && token.isNotEmpty) {
          await storageService.saveToken(token);
          ref.read(authStateProvider.notifier).state = true;

          if (mounted) {
            context.go('/');
          }
        } else {
          if (kDebugMode) {
            debugPrint('[Login Parsing Error] Unexpected response schema: $data');
          }
          _showErrorSnackBar('Invalid response structure received from server.');
        }
      } else {
        _showErrorSnackBar('Server returned unexpected status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[Login DioException] Type: ${e.type}, Code: ${e.response?.statusCode}, Message: ${e.message}');
      }

      final statusCode = e.response?.statusCode;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.error is SocketException) {
        _showErrorSnackBar('Unable to connect to server. Please check your internet connection.');
      } else if (statusCode == 401 || statusCode == 403) {
        _showErrorSnackBar('Invalid email or password');
      } else if (statusCode == 500 || statusCode == 502 || statusCode == 503) {
        _showErrorSnackBar('Server is temporarily unavailable. Please try again.');
      } else {
        final serverMsg = e.response?.data is Map ? e.response?.data['message'] : null;
        _showErrorSnackBar(serverMsg?.toString() ?? 'Unable to connect to server. Please check your internet connection.');
      }
    } on FormatException catch (e) {
      if (kDebugMode) {
        debugPrint('[Login FormatException] $e');
      }
      _showErrorSnackBar('Invalid format received from server.');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Login Error] $e');
      }
      _showErrorSnackBar('An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.electric_car, size: 64, color: Color(0xFF10B981)),
              const SizedBox(height: 16),
              const Text(
                'EcoMargin EV',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Smart Charging • Green Energy',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

