import 'package:flutter_test/flutter_test.dart';
import 'package:sozotap/settings/domain/models/privacy_settings_model.dart';

void main() {
  group('PrivacySettingsModel Tests', () {
    test('recommendedPreset returns correct defaults', () {
      final preset = PrivacySettingsModel.recommendedPreset();
      expect(preset.emergencyAccessEnabled, true);
      expect(preset.shareNameInEmergency, true);
      expect(preset.sharePhotoInEmergency, false);
      expect(preset.shareBloodGroupInEmergency, true);
      expect(preset.shareAllergiesInEmergency, true);
    });

    test('copyWith modifies selected flags', () {
      final model = PrivacySettingsModel.recommendedPreset();
      final updated = model.copyWith(emergencyAccessEnabled: false, sharePhotoInEmergency: true);

      expect(updated.emergencyAccessEnabled, false);
      expect(updated.sharePhotoInEmergency, true);
      expect(updated.shareBloodGroupInEmergency, true);
    });
  });
}
