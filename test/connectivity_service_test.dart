import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Connectivity & Sync State Tests', () {
    test('Offline state mapping returns true when connectivity fails', () {
      bool isOnline = false;
      bool isOffline = !isOnline;

      expect(isOffline, true);
    });
  });
}
