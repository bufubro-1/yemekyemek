import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'token_storage.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}

class ApiResponse {
  const ApiResponse({required this.statusCode, required this.body});

  final int statusCode;
  final dynamic body;

  Map<String, dynamic> get object {
    if (body is Map<String, dynamic>) {
      return body as Map<String, dynamic>;
    }
    throw const ApiException('API yanıtı beklenen JSON nesnesi değil.');
  }

  /// Node API'nin `{ data: ... }` zarfını açar. Zarfsız yanıtları da kabul
  /// ederek 204 ve doğrudan nesne dönen endpoint'lerle uyumlu kalır.
  dynamic get data => body is Map<String, dynamic> && object.containsKey('data')
      ? object['data']
      : body;
}

class ApiClient {
  ApiClient({
    http.Client? httpClient,
    TokenStorage? tokenStorage,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _tokenStorage = tokenStorage ?? TokenStorage(),
        _baseUrl = (baseUrl ?? AppConfig.baseApiUrl).replaceAll(
          RegExp(r'/+$'),
          '',
        );

  final http.Client _httpClient;
  final TokenStorage _tokenStorage;
  final String _baseUrl;

  Future<ApiResponse> get(String path, {bool authenticated = true}) =>
      request('GET', path, authenticated: authenticated);

  Future<ApiResponse> post(
    String path, {
    Object? body,
    bool authenticated = true,
  }) =>
      request(
        'POST',
        path,
        body: body,
        authenticated: authenticated,
      );

  Future<ApiResponse> put(
    String path, {
    Object? body,
    bool authenticated = true,
  }) =>
      request(
        'PUT',
        path,
        body: body,
        authenticated: authenticated,
      );

  Future<ApiResponse> request(
    String method,
    String path, {
    Object? body,
    bool authenticated = true,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (authenticated) {
      final token = await _tokenStorage.readAccessToken();
      if (token == null || token.isEmpty) {
        throw const ApiException('Oturum bulunamadı.', statusCode: 401);
      }
      headers['Authorization'] = 'Bearer $token';
    }

    final request = http.Request(method, _uri(path))..headers.addAll(headers);
    if (body != null) {
      request.body = jsonEncode(body);
    }

    try {
      final streamedResponse =
          await _httpClient.send(request).timeout(AppConfig.networkTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      final decodedBody = _decodeBody(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          _errorMessage(decodedBody, response.statusCode),
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        statusCode: response.statusCode,
        body: decodedBody,
      );
    } on TimeoutException {
      throw const ApiException('Sunucu isteği zaman aşımına uğradı.');
    } on SocketException {
      throw const ApiException('Sunucuya bağlanılamadı.');
    } on http.ClientException catch (error) {
      throw ApiException('Ağ isteği tamamlanamadı: ${error.message}');
    }
  }

  Uri _uri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$normalizedPath');
  }

  dynamic _decodeBody(http.Response response) {
    if (response.body.trim().isEmpty) return null;

    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        throw const ApiException('Sunucu geçersiz bir JSON yanıtı döndürdü.');
      }
      return response.body;
    }
  }

  String _errorMessage(dynamic body, int statusCode) {
    if (body is Map<String, dynamic>) {
      final message = body['message'] ?? body['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
      if (message is Map<String, dynamic>) {
        final nestedMessage = message['message'];
        if (nestedMessage is String && nestedMessage.trim().isNotEmpty) {
          return nestedMessage;
        }
      }
    }
    if (body is String && body.trim().isNotEmpty) return body;
    return 'Sunucu isteği başarısız oldu (HTTP $statusCode).';
  }
}
