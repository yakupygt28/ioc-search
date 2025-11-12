import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ios_search/main.dart';

void main() {
  testWidgets('IOC Search app smoke test', (WidgetTester tester) async {
    
    await tester.pumpWidget(const IocSearchApp());

    
    expect(find.text('IOC Search'), findsOneWidget);

    
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);

    
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); 
    expect(find.text('Domain girmeniz gerekiyor'), findsOneWidget);

    
    await tester.enterText(find.byType(TextField), 'google.com');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle(); 

    
    expect(find.textContaining('Sonuç: google.com'), findsOneWidget);
  });
}
