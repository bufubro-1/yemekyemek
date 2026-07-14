# Commit Rehberi — yemekyemek

Bu doküman, repoya **nelerin eklenmesi** ve **nelerin eklenmemesi** gerektiğini özetler.
Commit atmadan önce `git status` ile değişiklikleri kontrol et.

## Proje yapısı (hatırlatma)


| Klasör / dosya       | Açıklama                                             |
| -------------------- | ---------------------------------------------------- |
| `yemekyemek_arayuz/` | Flutter uygulaması (kaynak kod + platform projeleri) |
| `database/`          | PostgreSQL şema ve SQL scriptleri                    |
| `README.md`          | Proje tanıtımı                                       |
| `.gitignore`         | Kök ignore kuralları (şu an özellikle `.env`)        |


---



## Commit edilmeli



### Kaynak kod ve dokümantasyon

- `yemekyemek_arayuz/lib/**` — Dart kaynak kodu (`screens`, `models`, `repositories`, vb.)
- `yemekyemek_arayuz/test/**` — test dosyaları
- `yemekyemek_arayuz/pubspec.yaml` — bağımlılık tanımları
- `yemekyemek_arayuz/pubspec.lock` — kilitlenen sürümler (**uygulama olduğu için commit edilmeli**; takımda aynı paket sürümleri kullanılır)
- `yemekyemek_arayuz/analysis_options.yaml`
- `yemekyemek_arayuz/README.md`, `yemekyemek_arayuz/DEPENDENCIES.md`
- Kök `README.md`, `COMMIT.md` ve benzeri proje dokümanları



### Veritabanı

- `database/*.sql` — şema scriptleri (`00_extensions.sql` … `06_follows.sql`, `schema.sql`)
- `database/README.md`



### Platform / native projeler (bilinçli değişiklikler)

Aşağıdakiler **paylaşılan proje ayarı** değiştiğinde commit edilir:

- `android/` — `build.gradle.kts`, `AndroidManifest.xml`, kaynaklar, ikonlar
- `ios/` — `Info.plist`, `project.pbxproj`, storyboard, asset’ler (bilerek yapılan native değişiklikler)
- `web/`, `linux/`, `macos/`, `windows/` — platform giriş noktaları ve yapılandırma

> Not: Xcode/Android Studio bazen `project.pbxproj` veya Gradle dosyalarını otomatik günceller.
> Diff’i oku; sadece senin amacına uygun değişiklikleri stage’le.



### Ignore kuralları

- Kök `.gitignore`
- `yemekyemek_arayuz/.gitignore` ve platform altındaki `.gitignore` dosyaları

---



## Commit edilmemeli



### Gizli / ortam dosyaları

- `.env` ve tüm gerçek secret’lar (API key, DB şifresi, JWT secret, vb.)
- Makineye özel URL/credential içeren yerel config dosyaları

Secret örneği gerekiyorsa `.env.example` gibi **değerleri boş/placeholder** bir şablon commit edilebilir; gerçek `.env` asla commit edilmez.

### Build ve araç çıktıları

Flutter `.gitignore` zaten bunları kapsar; yine de stage’e alma:

- `yemekyemek_arayuz/build/`
- `yemekyemek_arayuz/.dart_tool/`
- `.flutter-plugins-dependencies` (üretilen dosya)
- `**/ios/Flutter/ephemeral/`, `**/macos/Flutter/ephemeral/`
- `coverage/`, `*.log`, `*.class`, `*.pyc`



### IDE / işletim sistemi

- `.idea/` — IntelliJ / Android Studio proje ayarları
- `*.iml`, `*.ipr`, `*.iws`
- `.DS_Store` — macOS klasör meta verisi
- `.vscode/` — kişisel editör ayarları (takım paylaşmak isterse bilinçli istisna yapılabilir)
- `.history/`, `.atom/` vb. editör artıkları



### Yerel / kişisel veri

- Cihazda üretilen kullanıcı/restoran JSON `.txt` depoları (varsa)
- Kişisel debug notları, geçici scriptler, yedek klasörler

---



## Hızlı kontrol listesi

Commit öncesi:

1. `git status` — beklenmeyen untracked dosya var mı?
2. `git diff` — değişiklik gerçekten bu işe mi ait?
3. Secret var mı? (`.env`, key, şifre, token)
4. `build/`, `.dart_tool/`, `.idea/`, `.DS_Store` stage’de mi? → çıkar
5. `pubspec.yaml` değiştiyse `pubspec.lock` da birlikte mi?

Örnek güvenli stage:

```bash
# Örnek: sadece uygulama + DB + doküman
git add README.md COMMIT.md database/
git add yemekyemek_arayuz/lib/ yemekyemek_arayuz/pubspec.yaml yemekyemek_arayuz/pubspec.lock
git add yemekyemek_arayuz/README.md yemekyemek_arayuz/DEPENDENCIES.md

# Bunları ekleme
# git add .idea/ .DS_Store yemekyemek_arayuz/build/ .env
```

---



## Bu repodaki bilinen tuzaklar

Şu an `git status`’ta sık görülebilecekler:


| Dosya / klasör                   | Ne yapmalı?                                                                                                  |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `.DS_Store`                      | Commit etme. Mümkünse tracking’den çıkar: `git rm --cached .DS_Store` ve kök `.gitignore`’a `.DS_Store` ekle |
| `.idea/`                         | Commit etme (IDE ayarı)                                                                                      |
| `yemekyemek_arayuz/pubspec.lock` | **Commit et** (Flutter uygulaması)                                                                           |
| `ios/.../project.pbxproj`        | Sadece bilinçli native değişiklikse commit et; rastgele Xcode diff’ini incele                                |


Kök `.gitignore` şu an yalnızca `.env` içeriyor. Önerilen eklemeler:

```gitignore
.env
.DS_Store
.idea/
```

(`yemekyemek_arayuz/.gitignore` zaten `.idea/` ve `.DS_Store` içerir; kökteki `.idea/` ve `.DS_Store` için kök ignore da güncellenmeli.)

---



## Commit mesajı

Kısa ve “neden” odaklı yaz:

- `feat: kullanıcı kaydında rol seçimi ekle`
- `fix: splash sonrası yanlış ana ekrana yönlendirmeyi düzelt`
- `docs: commit rehberi ekle`
- `chore: pubspec bağımlılıklarını güncelle`
- `db: follows tablosu scriptini ekle`

Mümkünse bir commit = bir konu. UI + şema + IDE ayarı aynı commit’te karışmasın.