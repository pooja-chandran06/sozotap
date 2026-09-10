import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/settings_providers.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class DeleteAccountDialog extends ConsumerStatefulWidget {
  const DeleteAccountDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DeleteAccountDialog(),
    );
  }

  @override
  ConsumerState<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _phraseController = TextEditingController();
  bool _isDeleting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _phraseController.dispose();
    super.dispose();
  }

  Future<void> _executeAccountDeletion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user session.');

      // 1. Re-authenticate user if password exists
      if (user.email != null && _passwordController.text.isNotEmpty) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _passwordController.text.trim(),
        );
        await user.reauthenticateWithCredential(credential);
      }

      // 2. Clear user's local Hive cache
      final uid = user.uid;
      final hiveCacheService = ref.read(hiveCacheServiceProvider);
      await hiveCacheService.clearUserCache(uid);

      // 3. Call backend Cloud Function deleteUserAccount for secure cloud cleanup
      final callable = FirebaseFunctions.instance.httpsCallable('deleteUserAccount');
      await callable.call();

      // 4. Sign out auth provider state
      await ref.read(authRepositoryProvider).signOut();

      if (mounted) {
        Navigator.of(context).pop();
        context.go('/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your SOZOTAP account and data have been permanently deleted.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isDeleting = false;
        _errorMessage = e.message ?? 'Re-authentication failed. Check your password.';
      });
    } on FirebaseFunctionsException catch (e) {
      setState(() {
        _isDeleting = false;
        _errorMessage = e.message ?? 'Backend cleanup failed. Contact support.';
      });
    } catch (e) {
      setState(() {
        _isDeleting = false;
        _errorMessage = 'Deletion error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final hasPassword = user?.providerData.any((p) => p.providerId == 'password') ?? true;

    return AlertDialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: const [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFFF3B30), size: 28),
          SizedBox(width: 10),
          Text('Delete Account?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WARNING: This action is permanent and cannot be undone.',
                style: TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              const Text(
                '• All emergency QR codes will be immediately revoked.\n• Medical profile, emergency contacts, and notification history will be deleted.\n• Your cloud storage media assets will be erased.',
                style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 16),

              if (hasPassword) ...[
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password *',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Password is required to confirm identity.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _phraseController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Type "DELETE" to confirm *',
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: 'DELETE',
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val != 'DELETE') {
                    return 'Must type "DELETE" exactly in uppercase.';
                  }
                  return null;
                },
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF3B30),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isDeleting ? null : _executeAccountDeletion,
          child: _isDeleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('DELETE PERMANENTLY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
