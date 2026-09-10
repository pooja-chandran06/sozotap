import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../constants/app_colors.dart';
import '../../../core/security/phone_normalizer.dart';
import '../../domain/models/emergency_contact.dart';
import '../providers/emergency_contacts_provider.dart';

class AddEditContactScreen extends ConsumerStatefulWidget {
  final EmergencyContact? contact;

  const AddEditContactScreen({super.key, this.contact});

  @override
  ConsumerState<AddEditContactScreen> createState() => _AddEditContactScreenState();
}

class _AddEditContactScreenState extends ConsumerState<AddEditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _countryCodeController;
  late Relationship _selectedRelationship;
  late int _priority;
  late bool _isPrimary;
  late bool _canCall;
  late bool _canSms;
  late bool _allowPushNotifications;
  late bool _allowSmsNotifications;
  DateTime? _smsConsentAt;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.contact;
    _nameController = TextEditingController(text: c?.name ?? '');
    _phoneController = TextEditingController(text: c?.phoneNumber ?? '');
    _countryCodeController = TextEditingController(text: c?.countryCode ?? '+1');
    _selectedRelationship = c?.relationship ?? Relationship.family;
    _priority = c?.priority ?? 1;
    _isPrimary = c?.isPrimary ?? (c?.priority == 1);
    _canCall = c?.canCall ?? true;
    _canSms = c?.canSms ?? true;
    _allowPushNotifications = c?.allowPushNotifications ?? true;
    _allowSmsNotifications = c?.allowSmsNotifications ?? false;
    _smsConsentAt = c?.smsConsentAt;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _countryCodeController.dispose();
    super.dispose();
  }

  Future<String?> _lookupRecipientUserId(String normalizedPhone) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneNumber', isEqualTo: normalizedPhone)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
    } catch (_) {
      // Ignore lookup failure gracefully
    }
    return null;
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = ref.read(authStateProvider).value;
      final userId = user?.id ?? '';
      if (userId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User session expired. Please sign in again.')),
        );
        setState(() => _isSaving = false);
        return;
      }

      final phoneNormalizer = ref.read(phoneNormalizerProvider);
      final rawPhone = _phoneController.text.trim();
      final countryCode = _countryCodeController.text.trim();
      final normalizedPhone = phoneNormalizer.normalize(rawPhone, countryCode);

      // Auto-lookup matching SOZOTAP user for FCM recipient link
      final recipientUserId = await _lookupRecipientUserId(normalizedPhone);

      final isEditing = widget.contact != null;
      final now = DateTime.now();

      final updatedContact = EmergencyContact(
        id: isEditing ? widget.contact!.id : const Uuid().v4(),
        userId: userId,
        recipientUserId: recipientUserId ?? widget.contact?.recipientUserId,
        name: _nameController.text.trim(),
        relationship: _selectedRelationship,
        phoneNumber: normalizedPhone,
        countryCode: countryCode,
        priority: _isPrimary ? 1 : _priority,
        isPrimary: _isPrimary,
        canCall: _canCall,
        canSms: _canSms,
        allowPushNotifications: _allowPushNotifications,
        allowSmsNotifications: _allowSmsNotifications,
        smsConsentAt: _allowSmsNotifications ? (_smsConsentAt ?? now) : null,
        createdAt: isEditing ? widget.contact!.createdAt : now,
        updatedAt: now,
      );

      await ref.read(emergencyContactsProvider.notifier).save(updatedContact);

      if (mounted) {
        final hasRecipient = updatedContact.recipientUserId != null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Contact updated successfully${hasRecipient ? " (Linked for FCM Push)" : ""}'
                  : 'Contact added successfully${hasRecipient ? " (Linked for FCM Push)" : ""}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving contact: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.contact != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Emergency Contact' : 'Add Emergency Contact',
          style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contact Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name *',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a contact name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Relationship>(
                        value: _selectedRelationship,
                        decoration: InputDecoration(
                          labelText: 'Relationship *',
                          prefixIcon: const Icon(Icons.people),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: Relationship.values.map((rel) {
                          return DropdownMenuItem(
                            value: rel,
                            child: Text(
                              rel.name.toUpperCase(),
                              style: const TextStyle(fontFamily: 'Poppins'),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedRelationship = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              controller: _countryCodeController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Code',
                                hintText: '+1',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Phone Number *',
                                prefixIcon: const Icon(Icons.phone),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a phone number';
                                }
                                final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');
                                if (cleaned.length < 7) {
                                  return 'Enter a valid phone number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SOS & Priority Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        value: _isPrimary,
                        activeColor: AppColors.primary,
                        title: const Text('Set as Primary Contact', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Designates this contact as your #1 primary emergency recipient'),
                        onChanged: (val) {
                          setState(() {
                            _isPrimary = val;
                            if (val) _priority = 1;
                          });
                        },
                      ),
                      const Divider(height: 16),
                      DropdownButtonFormField<int>(
                        value: _priority,
                        decoration: InputDecoration(
                          labelText: 'Priority Level (1 = Highest)',
                          prefixIcon: const Icon(Icons.low_priority),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: [1, 2, 3, 4, 5].map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text('Priority $p ${p == 1 ? "(Primary)" : ""}'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _priority = val;
                              _isPrimary = (val == 1);
                            });
                          }
                        },
                      ),
                      const Divider(height: 24),
                      SwitchListTile(
                        value: _canCall,
                        activeColor: AppColors.primary,
                        title: const Text('Allow Emergency Voice Calls', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Enable direct dialing button during SOS'),
                        onChanged: (val) => setState(() => _canCall = val),
                      ),
                      SwitchListTile(
                        value: _allowPushNotifications,
                        activeColor: AppColors.primary,
                        title: const Text('FCM Push Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Dispatch FCM push notifications if contact uses SOZOTAP'),
                        onChanged: (val) => setState(() => _allowPushNotifications = val),
                      ),
                      SwitchListTile(
                        value: _allowSmsNotifications,
                        activeColor: AppColors.primary,
                        title: const Text('SMS Backup Dispatch Opt-In', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Explicit consent: Send SMS backup alerts to contact during an active SOS.'),
                        onChanged: (val) {
                          setState(() {
                            _allowSmsNotifications = val;
                            if (val) {
                              _smsConsentAt = DateTime.now();
                            } else {
                              _smsConsentAt = null;
                            }
                          });
                        },
                      ),
                      if (_allowSmsNotifications) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 8),
                          child: Text(
                            'SMS consent recorded at: ${_smsConsentAt != null ? _smsConsentAt.toString().substring(0, 19) : "Now"}\nNote: Phone/SMS carrier rates & regional compliance regulations apply.',
                            style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveForm,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving ? 'Saving...' : (isEditing ? 'UPDATE CONTACT' : 'SAVE CONTACT'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
