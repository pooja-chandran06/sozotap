import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_colors.dart';
import '../../data/models/template_audit_log.dart';
import '../../data/repositories/template_audit_log_repository.dart';
import '../../domain/utils/admin_role_helper.dart';
import '../providers/templates_admin_provider.dart';

final templateAuditLogRepoProvider = Provider<TemplateAuditLogRepository>((ref) {
  return TemplateAuditLogRepository();
});

final templateAuditHistoryProvider = FutureProvider.family<List<TemplateAuditLog>, String>((ref, templateId) async {
  final repo = ref.watch(templateAuditLogRepoProvider);
  return repo.getHistory(templateId);
});

class TemplateAuditHistoryScreen extends ConsumerWidget {
  final String templateId;

  const TemplateAuditHistoryScreen({super.key, required this.templateId});

  void _restoreVersion(BuildContext context, TemplateAuditLog log, String templateLocale, String userRole) {
    if (!AdminRoleHelper.canEditLocale(userRole, templateLocale)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Permission Denied: Your role ($userRole) cannot restore templates for locale "$templateLocale".'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final targetSnapshot = log.before ?? log.after;
    if (targetSnapshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot restore: No valid snapshot data found in log entry.')),
      );
      return;
    }

    context.push(
      '/admin/templates/edit?id=$templateId&restoreId=${log.id}',
      extra: targetSnapshot,
    );
  }

  void _showDiffDialog(BuildContext context, TemplateAuditLog log, String templateLocale, String userRole) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Audit Log Details (${log.action.toUpperCase()})'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Admin: ${log.changedByUid}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Time: ${log.timestamp}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Divider(),
                if (log.before != null) ...[
                  const Text('BEFORE:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: Colors.red.shade50,
                    child: Text(log.before.toString(), style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                  ),
                  const SizedBox(height: 12),
                ],
                if (log.after != null) ...[
                  const Text('AFTER:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: Colors.green.shade50,
                    child: Text(log.after.toString(), style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
              icon: const Icon(Icons.restore),
              label: const Text('Restore This Version'),
              onPressed: () {
                Navigator.pop(context);
                _restoreVersion(context, log, templateLocale, userRole);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(templateAuditHistoryProvider(templateId));
    final adminState = ref.watch(templatesAdminProvider);
    final userRole = adminState.userRole;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revision History'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: historyAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(child: Text('No revision history found for this template.'));
          }

          return ListView.builder(
            itemCount: logs.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final item = logs[index];
              final templateLocale = item.after?['locale'] ?? item.before?['locale'] ?? 'en';
              final canRestore = AdminRoleHelper.canEditLocale(userRole, templateLocale as String);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.action == 'create' 
                        ? Colors.green 
                        : item.action == 'restore'
                            ? Colors.purple
                            : item.action == 'update' 
                                ? AppColors.accent 
                                : Colors.orange,
                    child: Icon(
                      item.action == 'create' 
                          ? Icons.add 
                          : item.action == 'restore'
                              ? Icons.restore
                              : item.action == 'update' 
                                  ? Icons.edit 
                                  : Icons.tune,
                      color: Colors.white,
                    ),
                  ),
                  title: Text('Action: ${item.action.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('By: ${item.changedByUid}\n${item.timestamp}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (canRestore)
                        IconButton(
                          icon: const Icon(Icons.restore, color: AppColors.accent),
                          tooltip: 'Restore This Version',
                          onPressed: () => _restoreVersion(context, item, templateLocale, userRole),
                        ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => _showDiffDialog(context, item, templateLocale, userRole),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading history: $err')),
      ),
    );
  }
}
