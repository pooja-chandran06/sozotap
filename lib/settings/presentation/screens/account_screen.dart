import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/delete_account_dialog.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _isSendingReset = false;

  Future<void> _sendPasswordReset() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email address associated with this account.')),
      );
      return;
    }

    setState(() => _isSendingReset = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to $email. Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send password reset email: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingReset = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Account & Security Controls', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFF0A84FF).withOpacity(0.2),
                  child: const Icon(Icons.person, size: 40, color: Color(0xFF0A84FF)),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.displayName ?? 'SOZOTAP User',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(user?.email ?? 'No email bound', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                Text('User ID: ${user?.uid ?? "Unknown"}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text('SECURITY ACTIONS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.lock_reset, color: Color(0xFF0A84FF)),
              title: const Text('Change Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: const Text('Send a secure password reset link to your email', style: TextStyle(color: Colors.grey, fontSize: 12)),
              trailing: _isSendingReset
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0A84FF)))
                  : const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
              onTap: _isSendingReset ? null : _sendPasswordReset,
            ),
          ),

          const SizedBox(height: 32),
          const Text('DANGER ZONE', style: TextStyle(color: Color(0xFFFF3B30), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFF3B30).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF3B30).withOpacity(0.4)),
            ),
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Color(0xFFFF3B30)),
              title: const Text('Delete Account & Cloud Data', style: TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.bold)),
              subtitle: const Text('Permanently remove all medical profiles, QR codes, contacts, and account records.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              onTap: () => DeleteAccountDialog.show(context),
            ),
          ),
        ],
      ),
    );
  }
}
