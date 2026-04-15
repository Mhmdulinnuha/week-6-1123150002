import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../contstans/api_constants.dart';
import '../services/secure_storage.dart';

class DioClient {
  DioClient._();

  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: Duration(
          milliseconds: ApiConstants.connectTimeout,
        ),
        receiveTimeout: Duration(
          milliseconds: ApiConstants.receiveTimeout,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptor: Token + Logging + Error Handler
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorageService.getToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] =
                'Bearer $token';
          }

          debugPrint(
            '[REQUEST] ${options.method} ${options.uri}',
          );

          handler.next(options);
        },

        onResponse: (response, handler) {
          debugPrint(
            '[RESPONSE] ${response.statusCode} ${response.requestOptions.path}',
          );

          handler.next(response);
        },

        onError: (error, handler) async {
          debugPrint(
            '[ERROR] ${error.response?.statusCode} ${error.requestOptions.path}',
          );

          if (error.response?.statusCode == 401) {
            await SecureStorageService.clearAll();
          }

          handler.next(error);
        },
      ),
    );

    return dio;
  }
}