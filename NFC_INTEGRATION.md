# SOZOTAP NFC SmartTag Integration Guide

This document describes the architecture, payload format, security model, and user screens for SOZOTAP NFC SmartTag integration.

---

## 1. Overview
SOZOTAP NFC SmartTags serve as a physical emergency medical ID extension. Touching an NDEF-compatible NFC tag (e.g. NTAG213, NTAG215, NTAG216) with an NFC-enabled smartphone launches or directs the user to the public paramedic emergency viewer (`/scan?token=...`).

---

## 2. Security & Zero PII Policy
- **NDEF URI Payload Format**: `https://vitanexus.web.app/scan?token=<opaque_token>`
- **Zero Medical Data on Tag**: Physical NFC tags store **only** an opaque security token. Zero patient names, blood groups, allergies, medications, phone numbers, or Firebase UIDs are stored on the chip.
- **Revocation Safety**: If an NFC tag is lost or stolen, revoking the dynamic QR token from the mobile app immediately renders the physical NFC tag invalid.

---

## 3. Flutter Architecture & Hardware Checks
- **Repository Interface**: `NfcTagRepository` (`lib/nfc/domain/repositories/nfc_tag_repository.dart`)
- **Package Implementation**: `NfcTagRepositoryImpl` using `nfc_manager: ^3.3.0`.
- **Management UI**: `NfcManagementScreen` (`/devices/nfc`).

### Validation Criteria:
1. Checks hardware availability (`isNfcAvailable()`).
2. Validates NDEF compatibility and `isWritable` flag.
3. Enforces NDEF byte size capacity.
4. Provides clear fallback message: *"Use the QR medical ID if NFC is unavailable."*
