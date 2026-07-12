import '../config/app_config.dart';
import 'auth_repository.dart';
import 'local_auth_repository.dart';
import 'local_profile_repository.dart';
import 'local_restaurant_repository.dart';
import 'profile_repository.dart';
import 'remote_auth_repository.dart';
import 'remote_profile_repository.dart';
import 'remote_restaurant_repository.dart';
import 'restaurant_repository.dart';

/// Uygulamanın herhangi bir yerinde `RepositoryProvider.auth` ya da
/// `RepositoryProvider.profile` çağrılarak doğru implementasyon (local ya da
/// remote) alınır. Backend hazır olduğunda tek yapılması gereken
/// AppConfig.useRemoteBackend değerini değiştirmektir; ekranlarda HİÇBİR
/// değişiklik gerekmez.
class RepositoryProvider {
  RepositoryProvider._();

  static AuthRepository get auth =>
      AppConfig.useRemoteBackend ? RemoteAuthRepository() : LocalAuthRepository();

  static ProfileRepository get profile => AppConfig.useRemoteBackend
      ? RemoteProfileRepository()
      : LocalProfileRepository();

  static RestaurantRepository get restaurant => AppConfig.useRemoteBackend
      ? RemoteRestaurantRepository()
      : LocalRestaurantRepository();
}
