# SOZOTAP Testing Infrastructure & Strategy

This document outlines the testing strategy, test file locations, and execution instructions for unit, widget, and integration testing across Flutter and Cloud Functions.

---

## 1. Test Directory Structure
```
sozotap/
├── functions/test/
│   └── functions.test.ts           # Cloud Functions TypeScript unit tests (Jest)
└── test/
    ├── unit/
    │   ├── safe_logger_test.dart       # Tests PII & medical redaction logic
    │   ├── error_mapper_test.dart      # Tests exception mapping
    │   └── app_check_service_test.dart # Tests App Check initialization safety
    ├── widget/
    │   ├── settings_screen_widget_test.dart          # Tests Settings UI rendering
    │   └── privacy_settings_screen_widget_test.dart  # Tests Privacy consent switches
    ├── device_token_test.dart          # Model serialization tests
    ├── hive_cache_service_test.dart    # Offline cache service tests
    ├── notification_item_test.dart     # Notification item tests
    └── settings_model_test.dart        # Settings model tests
```

---

## 2. Running Flutter Tests
```bash
# Run all unit and widget tests
flutter test

# Run tests with code coverage report
flutter test --coverage

# Run specific unit test file
flutter test test/unit/safe_logger_test.dart
```

---

## 3. Running Cloud Functions Backend Tests
```bash
cd functions

# Run Jest unit test suite
npm test
```

---

## 4. CI/CD Automated Testing
Every git push or pull request to `main` or `develop` triggers automated GitHub Actions workflows:
- `.github/workflows/flutter_ci.yml` -> Executes `flutter analyze` and `flutter test`.
- `.github/workflows/functions_ci.yml` -> Executes `npm run lint`, `npm run build`, and `npm test`.
