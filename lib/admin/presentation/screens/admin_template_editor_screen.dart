import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_colors.dart';
import '../../data/repositories/templates_admin_repository.dart';
import '../../domain/utils/admin_role_helper.dart';
import '../providers/templates_admin_provider.dart';

class AdminTemplateEditorScreen extends ConsumerStatefulWidget {
  final String? templateId;
  final Map<String, dynamic>? restorationSnapshot;
  final bool isRestoration;
  final String? restoreId;

  const AdminTemplateEditorScreen({
    super.key,
    this.templateId,
    this.restorationSnapshot,
    this.isRestoration = false,
    this.restoreId,
  });

  @override
  ConsumerState<AdminTemplateEditorScreen> createState() => _AdminTemplateEditorScreenState();
}

class _AdminTemplateEditorScreenState extends ConsumerState<AdminTemplateEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _type = 'sms';
  String _locale = 'en';
  String _variant = 'brief';
  String _subject = '';
  String _title = '';
  String _body = '';
  bool _enabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.restorationSnapshot != null) {
      _applySnapshot(widget.restorationSnapshot!);
    } else if (widget.templateId != null && widget.templateId!.isNotEmpty) {
      _loadExistingTemplate();
    }
  }

  void _applySnapshot(Map<String, dynamic> data) {
    setState(() {
      _type = data['type'] as String? ?? 'sms';
      _locale = data['locale'] as String? ?? 'en';
      _variant = data['variant'] as String? ?? 'brief';
      _subject = data['subjectTemplate'] as String? ?? '';
      _title = data['titleTemplate'] as String? ?? '';
      _body = data['bodyTemplate'] as String? ?? '';
      _enabled = data['enabled'] as bool? ?? true;
    });
  }

  Future<void> _loadExistingTemplate() async {
    setState(() => _isLoading = true);
    final repo = ref.read(templatesAdminRepositoryProvider);
    final doc = await repo.getTemplate(widget.templateId!);
    if (doc != null && mounted) {
      setState(() {
        _type = doc.type;
        _locale = doc.locale;
        _variant = doc.variant;
        _subject = doc.subjectTemplate ?? '';
        _title = doc.titleTemplate ?? '';
        _body = doc.bodyTemplate;
        _enabled = doc.enabled;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _renderPreview() {
    String preview = _body;
    final Map<String, String> sampleVars = {
      'patientName': 'Jane Doe',
      'bloodGroup': 'A+',
      'conditions': 'Asthma',
      'allergies': 'Penicillin',
      'medications': 'Albuterol',
      'doctorName': 'Dr. Smith',
      'hospitalName': 'City Hospital',
      'gpsUrl': 'https://maps.google.com/?q=37.7749,-122.4194',
      'timestamp': '2026-08-01 12:00',
    };

    sampleVars.forEach((key, val) {
      preview = preview.replaceAll('{{$key}}', val);
    });

    return preview;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final doc = TemplateDocument(
      id: widget.templateId ?? '',
      type: _type,
      locale: _locale,
      variant: _variant,
      subjectTemplate: _subject.isNotEmpty ? _subject : null,
      titleTemplate: _title.isNotEmpty ? _title : null,
      bodyTemplate: _body,
      enabled: _enabled,
      updatedAt: DateTime.now(),
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isRestoration ? 'Confirm Restoration' : 'Confirm Save'),
        content: Text(
          widget.isRestoration
              ? 'Are you sure you want to restore this template to the selected historical version? An audit entry will be logged.'
              : 'Are you sure you want to save this template? Changes will be logged to audit_logs.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isRestoration ? Colors.purple : AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(widget.isRestoration ? 'Restore & Save' : 'Save'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final repo = ref.read(templatesAdminRepositoryProvider);
        final adminState = ref.read(templatesAdminProvider);

        await repo.saveTemplate(
          doc,
          ref.read(templatesAdminNotifierProviderUserId),
          adminState.userRole,
          isRestoration: widget.isRestoration,
          restoredFromAuditLogId: widget.restoreId,
        );

        await ref.read(templatesAdminProvider.notifier).init();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isRestoration ? 'Template restored and logged successfully!' : 'Template saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving template: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(templatesAdminProvider);
    final userRole = adminState.userRole;
    final isGlobalAdmin = AdminRoleHelper.isGlobalAdmin(userRole);
    final scopedLocale = AdminRoleHelper.getLocaleForRole(userRole);

    if (scopedLocale != null && widget.templateId == null && _locale != scopedLocale) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _locale = scopedLocale);
      });
    }

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isRestoration
            ? 'Restore Template'
            : (widget.templateId == null ? 'Create Template' : 'Edit Template')),
        backgroundColor: widget.isRestoration ? Colors.purple : AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (widget.templateId != null && widget.templateId!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'View Revision History',
              onPressed: () {
                context.push('/admin/templates/history?id=${widget.templateId}');
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restoration Mode Banner
              if (widget.isRestoration) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    border: Border.all(color: Colors.purple.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.restore, color: Colors.purple),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Restoration Mode: Pre-filled from historical audit log. Review changes before saving.',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Role Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isGlobalAdmin ? Colors.blue.shade50 : Colors.amber.shade50,
                  border: Border.all(color: isGlobalAdmin ? Colors.blue.shade300 : Colors.amber.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(isGlobalAdmin ? Icons.admin_panel_settings : Icons.security, 
                         color: isGlobalAdmin ? Colors.blue : Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isGlobalAdmin
                            ? 'Role: Global Admin (Unrestricted Access)'
                            : 'Role: $userRole (Scoped to "$scopedLocale" locale)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              // Type & Locale Dropdowns
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(value: 'sms', child: Text('SMS')),
                        DropdownMenuItem(value: 'email', child: Text('Email')),
                        DropdownMenuItem(value: 'push', child: Text('Push')),
                      ],
                      onChanged: (v) => setState(() => _type = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _locale,
                      decoration: const InputDecoration(labelText: 'Locale'),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English (en)')),
                        DropdownMenuItem(value: 'es', child: Text('Spanish (es)')),
                        DropdownMenuItem(value: 'fr', child: Text('French (fr)')),
                        DropdownMenuItem(value: 'de', child: Text('German (de)')),
                        DropdownMenuItem(value: 'ar', child: Text('Arabic (ar)')),
                      ],
                      onChanged: isGlobalAdmin ? (v) => setState(() => _locale = v!) : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _variant,
                decoration: const InputDecoration(labelText: 'Variant'),
                items: const [
                  DropdownMenuItem(value: 'brief', child: Text('Brief')),
                  DropdownMenuItem(value: 'detailed', child: Text('Detailed')),
                ],
                onChanged: (v) => setState(() => _variant = v!),
              ),
              const SizedBox(height: 16),

              if (_type == 'email' || _type == 'push') ...[
                TextFormField(
                  initialValue: _subject,
                  decoration: const InputDecoration(labelText: 'Subject / Title Template'),
                  onChanged: (v) => setState(() => _subject = v),
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                initialValue: _body,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Body Template',
                  hintText: 'Use {{patientName}}, {{bloodGroup}}, {{gpsUrl}}, {{conditions}}, etc.',
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Body template cannot be empty' : null,
                onChanged: (v) => setState(() => _body = v),
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                title: const Text('Enabled'),
                subtitle: const Text('If disabled, system will fall back to local assets.'),
                value: _enabled,
                activeColor: widget.isRestoration ? Colors.purple : AppColors.primary,
                onChanged: (v) => setState(() => _enabled = v),
              ),
              const SizedBox(height: 24),

              const Text('Live Rendered Preview:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _renderPreview().isEmpty ? '(Empty preview)' : _renderPreview(),
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: Icon(widget.isRestoration ? Icons.restore : Icons.save),
                  label: Text(
                    widget.isRestoration ? 'Restore & Save Template' : 'Save Template Document',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isRestoration ? Colors.purple : AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
