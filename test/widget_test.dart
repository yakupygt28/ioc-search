import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ios_search/main.dart';

void main() {
  testWidgets('IOC Search app smoke test', (WidgetTester tester) async {
    // Uygulamayı yükle
    await tester.pumpWidget(const IocSearchApp());

    // Ana ekrandaki IOC Search başlığını kontrol et
    expect(find.text('IOC Search'), findsOneWidget);

    // TextField ve buton var mı kontrol et
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);

    // Butona tıkla ve TextField boş bırakılırsa hata mesajı çıkıyor mu
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); // UI güncellensin
    expect(find.text('Domain girmeniz gerekiyor'), findsOneWidget);

    // TextField'a bir domain yaz
    await tester.enterText(find.byType(TextField), 'google.com');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle(); // Navigasyon tamamlanana kadar bekle

    // Sonuç ekranına geçtiğini kontrol et
    expect(find.textContaining('Sonuç: google.com'), findsOneWidget);
  });
}
