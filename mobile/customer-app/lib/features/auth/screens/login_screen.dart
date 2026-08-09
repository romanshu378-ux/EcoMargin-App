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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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
        debugPrint('[LOGIN] API URL: ${apiClient.dio.options.baseUrl}/auth/login');
        debugPrint('[LOGIN] Request started');
      }

      final response = await apiClient.dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (kDebugMode) {
        debugPrint('[LOGIN] Status: ${response.statusCode}');
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
            debugPrint('[LOGIN] Parsing Error: Unexpected response schema: $data');
          }
          _showErrorSnackBar('Invalid response structure received from server.');
        }
      } else {
        _showErrorSnackBar('Server returned unexpected status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (kDebugMode) {
        debugPrint('[LOGIN] Error Type: ${e.type}');
        debugPrint('[LOGIN] Status Code: $statusCode');
        debugPrint('[LOGIN] Request URL: ${e.requestOptions.uri}');
        if (e.response?.data != null) {
          debugPrint('[LOGIN] Response Body: ${e.response?.data}');
        }
      }

      if (statusCode != null) {
        String? serverMsg;
        if (e.response?.data is Map) {
          serverMsg = (e.response?.data as Map)['message']?.toString();
        }

        if (statusCode == 401) {
          _showErrorSnackBar(serverMsg ?? 'Invalid email or password');
        } else if (statusCode == 403) {
          _showErrorSnackBar(serverMsg ?? 'Access denied');
        } else if (statusCode == 409) {
          _showErrorSnackBar(serverMsg ?? 'Account already exists');
        } else if (statusCode == 422) {
          _showErrorSnackBar(serverMsg ?? 'Invalid registration/login data');
        } else if (statusCode == 500) {
          _showErrorSnackBar(serverMsg ?? 'Server error. Please try again.');
        } else if (statusCode == 502 || statusCode == 503) {
          _showErrorSnackBar('Server temporarily unavailable.');
        } else {
          _showErrorSnackBar(serverMsg ?? 'Server returned error ($statusCode).');
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.error is SocketException) {
        _showErrorSnackBar('Unable to connect to server. Please check your internet connection.');
      } else {
        _showErrorSnackBar(e.message ?? 'An error occurred while connecting to server.');
      }
    } on FormatException catch (e) {
      if (kDebugMode) {
        debugPrint('[LOGIN] FormatException: $e');
      }
      _showErrorSnackBar('Invalid format received from server.');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LOGIN] Unexpected Error: $e');
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
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
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
                    hintText: 'name@example.com',
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
                    hintText: '••••••••',
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
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ", style: TextStyle(color: Colors.grey)),
                    GestureDetector(
                      onTap: _isLoading ? null : () => context.go('/register'),
                      child: const Text(
                        'Create New Account',
                        style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


