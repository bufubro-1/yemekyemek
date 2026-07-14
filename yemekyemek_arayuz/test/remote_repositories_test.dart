import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yemekyemek_arayuz/models/app_user.dart';
import 'package:yemekyemek_arayuz/repositories/remote_auth_repository.dart';
import 'package:yemekyemek_arayuz/repositories/remote_profile_repository.dart';
import 'package:yemekyemek_arayuz/repositories/remote_restaurant_repository.dart';
import 'package:yemekyemek_arayuz/services/api_client.dart';
import 'package:yemekyemek_arayuz/services/token_storage.dart';

class _MemoryTokenStorage extends TokenStorage {
  _MemoryTokenStorage([this.token]);

  String? token;

  @override
  Future<String?> readAccessToken() async => token;

  @override
  Future<void> writeAccessToken(String token) async {
    this.token = token;
  }

  @override
  Future<void> clearAccessToken() async {
    token = null;
  }
}

void main() {
  const baseUrl = 'http://localhost:3000/v1';

  test('register API rolünü eşler ve JWT tokenını saklar', () async {
    final tokenStorage = _MemoryTokenStorage();
    final httpClient = MockClient((request) async {
      expect(request.url.toString(), '$baseUrl/auth/register');
      expect(request.headers['authorization'], isNull);

      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['role'], 'restaurant_owner');
      expect(body.containsKey('passwordHash'), isFalse);

      return http.Response(
        jsonEncode({
          'data': {
            'token': 'jwt-token',
            'user': {
              'id': 'user-1',
              'nickname': 'lokanta',
              'username': 'Lokanta',
              'email': 'owner@example.com',
              'role': 'restaurant_owner',
              'createdAt': '2026-07-14T10:00:00.000Z',
            },
          },
        }),
        201,
        headers: {'content-type': 'application/json'},
      );
    });
    final apiClient = ApiClient(
      httpClient: httpClient,
      tokenStorage: tokenStorage,
      baseUrl: baseUrl,
    );
    final repository = RemoteAuthRepository(
      apiClient: apiClient,
      tokenStorage: tokenStorage,
    );

    final result = await repository.register(
      nickname: 'Lokanta',
      username: 'Lokanta',
      email: 'OWNER@EXAMPLE.COM',
      password: 'Secret123',
      role: UserRole.restaurantOwner,
    );

    expect(result.success, isTrue);
    expect(result.user?.role, UserRole.restaurantOwner);
    expect(result.user?.passwordHash, isEmpty);
    expect(tokenStorage.token, 'jwt-token');
  });

  test('hata durumunda API mesajını AuthResult ile döndürür', () async {
    final tokenStorage = _MemoryTokenStorage();
    final apiClient = ApiClient(
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'E-posta zaten kullanımda.'}),
          409,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
      tokenStorage: tokenStorage,
      baseUrl: baseUrl,
    );
    final repository = RemoteAuthRepository(
      apiClient: apiClient,
      tokenStorage: tokenStorage,
    );

    final result = await repository.login(
      email: 'user@example.com',
      password: 'Secret123',
    );

    expect(result.success, isFalse);
    expect(result.errorMessage, 'E-posta zaten kullanımda.');
  });

  test('profil isteğine Bearer token ekler ve snake_case alanları okur',
      () async {
    final tokenStorage = _MemoryTokenStorage('jwt-token');
    final apiClient = ApiClient(
      httpClient: MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer jwt-token');
        return http.Response(
          jsonEncode({
            'data': {
              'user_id': 'user-1',
              'bio': 'Merhaba',
              'followers_count': 4,
              'following_count': 2,
              'rating_badge': 'Gurme',
              'diet_preferences': ['Vegan'],
            },
          }),
          200,
        );
      }),
      tokenStorage: tokenStorage,
      baseUrl: baseUrl,
    );

    final profile = await RemoteProfileRepository(apiClient: apiClient)
        .getProfile('user-1');

    expect(profile?.userId, 'user-1');
    expect(profile?.followersCount, 4);
    expect(profile?.dietPreferences, ['Vegan']);
  });

  test('restoran bulunamadığında null döndürür', () async {
    final tokenStorage = _MemoryTokenStorage('jwt-token');
    final apiClient = ApiClient(
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({'message': 'Restoran bulunamadı.'}),
          404,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
      tokenStorage: tokenStorage,
      baseUrl: baseUrl,
    );

    final restaurant = await RemoteRestaurantRepository(apiClient: apiClient)
        .getRestaurant('user-1');

    expect(restaurant, isNull);
  });
}
