# Contributing to SOZOTAP

Thank you for contributing to SOZOTAP! Please follow these guidelines when creating pull requests or submitting issue reports.

---

## Code Style & Guidelines
1. **Formatting**: Always format Dart code using `flutter format .` and TypeScript code using `npm run lint`.
2. **Clean Architecture**: Place feature logic in feature-first folders (`lib/<feature_name>/`). Maintain strict separation between data, domain, and presentation layers.
3. **No Direct Secret Commits**: Ensure `key.properties`, keystores, `.env`, service account JSON files, or API credentials are never added to source control.
4. **Safe Logging**: Use `SafeLogger` for all diagnostic logging. Never log raw emails, phone numbers, auth tokens, coordinates, or medical record values.

---

## Submitting a Pull Request
1. Fork repository and create a feature branch (`git checkout -b feature/amazing-feature`).
2. Run `flutter analyze` and ensure zero warnings or errors.
3. Run `flutter test` and `cd functions && npm test`.
4. Commit your changes with descriptive messages (`git commit -m 'feat: add BLE SOS trigger support'`).
5. Push to branch and submit a Pull Request.
