import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/sos/message_status.dart';
import '../providers/message_status_provider.dart';
import '../../../constants/app_colors.dart';

class SosStatusWidget extends ConsumerWidget {
  final List<String> messageIds;

  const SosStatusWidget({super.key, required this.messageIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (messageIds.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No messages were dispatched.'),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Dispatch Status',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: messageIds.length,
          itemBuilder: (context, index) {
            final messageId = messageIds[index];
            final statusAsync = ref.watch(messageStatusProvider(messageId));

            return statusAsync.when(
              data: (status) {
                if (status == null) return const ListTile(title: Text('Message not found'));
                return ListTile(
                  leading: Icon(
                    status.channel == 'sms' 
                        ? Icons.message 
                        : status.channel == 'email' 
                            ? Icons.email 
                            : Icons.notifications_active,
                    color: AppColors.primary,
                  ),
                  title: Text(status.recipient, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(_getStatusText(status.status)),
                  trailing: _getStatusIcon(status.status),
                );
              },
              loading: () => const ListTile(
                leading: CircularProgressIndicator(),
                title: Text('Loading status...'),
              ),
              error: (e, _) => ListTile(title: Text('Error: $e')),
            );
          },
        ),
      ],
    );
  }

  String _getStatusText(MessageStatus status) {
    switch (status) {
      case MessageStatus.queued: return 'Queued for delivery...';
      case MessageStatus.processing: return 'Processing...';
      case MessageStatus.success: return 'Delivered successfully!';
      case MessageStatus.failure: return 'Failed to deliver.';
    }
  }

  Widget _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.queued:
        return const Icon(Icons.access_time, color: Colors.grey);
      case MessageStatus.processing:
        return const SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case MessageStatus.success:
        return const Icon(Icons.check_circle, color: Colors.green);
      case MessageStatus.failure:
        return const Icon(Icons.error, color: Colors.red);
    }
  }
}
