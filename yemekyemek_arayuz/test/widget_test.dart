// Basit bir smoke test: uygulama gerçek widget ağacıyla (YemekYemekApp)
// çöküp çökmeden açılıyor mu diye kontrol eder.
//
// Not: SplashDecisionScreen açılışta path_provider ile session.txt okumaya
// çalıştığı için testte gerçek platform kanalları olmadan tamamlanmayabilir;
// bu yüzden test yalnızca ilk frame'in (CircularProgressIndicator) hatasız
// çizildiğini doğrular.

import 'package:flutter_test/flutter_test.dart';

import 'package:yemekyemek_arayuz/main.dart';

void main() {
  testWidgets('YemekYemekApp splash ekranıyla açılır', (tester) async {
    await tester.pumpWidget(const YemekYemekApp());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
