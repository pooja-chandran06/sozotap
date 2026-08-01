abstract class SmsDispatchService {
  Future<void> sendSms({
    required String toPhoneNumber,
    required String body,
    Map<String, dynamic>? metadata,
  });
}
