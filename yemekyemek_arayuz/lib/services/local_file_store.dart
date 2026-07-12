import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Uygulamanın belge dizininde .txt dosyaları üzerinden basit bir "veritabanı"
/// simülasyonu yapan yardımcı sınıf.
///
/// Her dosya, içeriğinde JSON (liste ya da map) tutar. Bu sınıf yalnızca
/// prototip aşaması için kullanılmaktadır; ileride [AppConfig.useRemoteBackend]
/// `true` yapılıp Remote*Repository sınıflarına geçildiğinde bu servise artık
/// ihtiyaç kalmayacaktır.
class LocalFileStore {
  static final LocalFileStore instance = LocalFileStore._internal();
  LocalFileStore._internal();

  Future<File> _fileFor(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    if (!await file.exists()) {
      await file.create(recursive: true);
      // Varsayılan olarak boş bir JSON listesi ile başlat.
      await file.writeAsString('[]');
    }
    return file;
  }

  /// Dosyadan JSON listesi okur. Dosya boşsa ya da bozuksa boş liste döner.
  Future<List<dynamic>> readList(String fileName) async {
    final file = await _fileFor(fileName);
    final content = await file.readAsString();
    if (content.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) return decoded;
      return [];
    } catch (_) {
      return [];
    }
  }

  /// JSON listesini dosyaya (biçimlendirilmiş şekilde) yazar.
  Future<void> writeList(String fileName, List<dynamic> data) async {
    final file = await _fileFor(fileName);
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(data));
  }

  /// Basit anahtar-değer (tekil obje) dosyaları için, örn. session.txt
  Future<Map<String, dynamic>?> readMap(String fileName) async {
    final file = await _fileFor(fileName);
    final content = await file.readAsString();
    if (content.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeMap(String fileName, Map<String, dynamic> data) async {
    final file = await _fileFor(fileName);
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(data));
  }

  Future<void> clearFile(String fileName) async {
    final file = await _fileFor(fileName);
    await file.writeAsString('');
  }
}

/// Bu prototipte kullanılan dosya adları tek yerden yönetilir.
class LocalFileNames {
  LocalFileNames._();
  static const String users = 'users.txt';
  static const String profiles = 'profiles.txt';
  static const String session = 'session.txt';
  static const String restaurants = 'restaurants.txt';
}
