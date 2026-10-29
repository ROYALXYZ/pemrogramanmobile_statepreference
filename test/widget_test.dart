import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:state_preferences/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows home, visit count, and toggles dark mode', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang!'), findsOneWidget);
    expect(find.text('Kunjungan ke-1'), findsOneWidget);
    expect(find.text('Favorites'), findsNothing);

    final toggleFinder = find.byTooltip('Toggle Dark Mode');
    expect(toggleFinder, findsOneWidget);
    await tester.tap(toggleFinder);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.light_mode), findsOneWidget);
  });

  testWidgets('supports profile save, persistence across rebuild, and logout', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Navigate to profile screen
    await tester.tap(find.text('Login / Daftar'));
    await tester.pumpAndSettle();

    // Fill profile fields
    await tester.enterText(find.widgetWithText(TextFormField, 'Nama'), 'Budi');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'budi@example.com',
    );
    await tester.tap(find.text('Simpan Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Profil berhasil disimpan'), findsOneWidget);

    // Return to home screen
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Selamat datang, Budi!'), findsOneWidget);
    expect(find.text('budi@example.com'), findsOneWidget);
    expect(find.text('Favorites'), findsNothing);

    // Navigate to profile to logout
    await tester.ensureVisible(find.text('Lihat Profil'));
    await tester.tap(find.text('Lihat Profil'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Logout'));
    await tester.pumpAndSettle();

    // Confirm logout dialog
    await tester.tap(find.widgetWithText(TextButton, 'Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang!'), findsOneWidget);
  });

  testWidgets('adds and removes favorites on the profile screen', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Favorites'), findsNothing);

    await tester.tap(find.text('Login / Daftar'));
    await tester.pumpAndSettle();

    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Catatan Keamanan'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Favorites')).dy,
      greaterThan(tester.getTopLeft(find.text('Catatan Keamanan')).dy),
    );
    expect(find.text('Belum ada favorit.'), findsOneWidget);

    await tester.ensureVisible(
      find.widgetWithText(TextField, 'Tambah favorit...'),
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Tambah favorit...'),
      'Membaca Buku',
    );
    await tester.ensureVisible(find.byIcon(Icons.add_circle));
    await tester.tap(find.byIcon(Icons.add_circle));
    await tester.pumpAndSettle();

    expect(find.text('Membaca Buku'), findsOneWidget);
    expect(find.text('Belum ada favorit.'), findsNothing);

    await tester.ensureVisible(find.byIcon(Icons.remove_circle_outline));
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada favorit.'), findsOneWidget);
  });

  testWidgets('validates dangerous markup in name and email', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Login / Daftar'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama'),
      '<script>alert("xss")</script>',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'user@example.com',
    );
    await tester.tap(find.text('Simpan Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Nama mengandung karakter berbahaya'), findsOneWidget);
  });

  testWidgets(
    'opens Latihan 4 demo, starts at 0, increments to 2, resets to 0',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Latihan 4: Provider'));
      await tester.tap(find.text('Latihan 4: Provider'));
      await tester.pumpAndSettle();

      expect(find.text('Latihan 4 - Provider'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(find.text('0'), findsOneWidget);
    },
  );
}
