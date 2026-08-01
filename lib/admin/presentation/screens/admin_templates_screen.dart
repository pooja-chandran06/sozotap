import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_colors.dart';
import '../providers/templates_admin_provider.dart';

class AdminTemplatesScreen extends ConsumerWidget {
  const AdminTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdminAsync = ref.watch(isAdminProvider);

    return isAdminAsync.when(
      data: (isAdmin) {
        if (!isAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('Access Denied'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Admin access required.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }

        final state = ref.watch(templatesAdminProvider);

        final filteredTemplates = state.templates.where((t) {
          if (state.selectedFilterType != null && state.selectedFilterType!.isNotEmpty && t.type != state.selectedFilterType) {
            return false;
          }
          if (state.selectedFilterLocale != null && state.selectedFilterLocale!.isNotEmpty && t.locale != state.selectedFilterLocale) {
            return false;
          }
          return true;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Template Manager (Admin)', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_active_outlined),
                tooltip: 'Notification Settings',
                onPressed: () => context.push('/admin/settings/notifications'),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.read(templatesAdminProvider.notifier).loadTemplates(),
              ),
            ],
          ),
          body: Column(
            children: [
              // Filter Toolbar
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: state.selectedFilterType,
                        decoration: const InputDecoration(labelText: 'Filter Type', isDense: true),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All Types')),
                          DropdownMenuItem(value: 'sms', child: Text('SMS')),
                          DropdownMenuItem(value: 'email', child: Text('Email')),
                          DropdownMenuItem(value: 'push', child: Text('Push')),
                        ],
                        onChanged: (val) => ref.read(templatesAdminProvider.notifier).filterByType(val),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: state.selectedFilterLocale,
                        decoration: const InputDecoration(labelText: 'Filter Locale', isDense: true),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All Locales')),
                          DropdownMenuItem(value: 'en', child: Text('English (en)')),
                          DropdownMenuItem(value: 'es', child: Text('Spanish (es)')),
                          DropdownMenuItem(value: 'fr', child: Text('French (fr)')),
                          DropdownMenuItem(value: 'de', child: Text('German (de)')),
                          DropdownMenuItem(value: 'ar', child: Text('Arabic (ar)')),
                        ],
                        onChanged: (val) => ref.read(templatesAdminProvider.notifier).filterByLocale(val),
                      ),
                    ),
                  ],
                ),
              ),

              // Template List
              Expanded(
                child: state.isLoading && state.templates.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filteredTemplates.isEmpty
                        ? const Center(child: Text('No templates found in Firestore.'))
                        : ListView.builder(
                            itemCount: filteredTemplates.length,
                            padding: const EdgeInsets.all(12),
                            itemBuilder: (context, index) {
                              final item = filteredTemplates[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: item.enabled ? AppColors.primary : Colors.grey,
                                    foregroundColor: Colors.white,
                                    child: Text(item.type[0].toUpperCase()),
                                  ),
                                  title: Text('${item.type.toUpperCase()} • ${item.locale.toUpperCase()} (${item.variant})',
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(item.bodyPreview),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(
                                        value: item.enabled,
                                        activeColor: AppColors.primary,
                                        onChanged: (_) {
                                          ref.read(templatesAdminProvider.notifier).toggleEnabled(item.id, item.enabled);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: AppColors.accent),
                                        onPressed: () {
                                          context.push('/admin/templates/edit?id=${item.id}');
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            onPressed: () => context.push('/admin/templates/edit'),
            icon: const Icon(Icons.add),
            label: const Text('New Template'),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
