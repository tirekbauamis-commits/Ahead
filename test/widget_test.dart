import 'package:ahead_app/ahead_shell_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AHEAD membuka login baru', (tester) async {
    await tester.runAsync(aheadStore.ensureLoaded);
    await tester.pumpWidget(const AheadShellApp());
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.textContaining('Selamat Datang', findRichText: true),
        findsOneWidget);
    expect(find.text('Masuk dengan Google'), findsOneWidget);
    expect(find.text('contoh@email.com'), findsNothing);
  });
}
