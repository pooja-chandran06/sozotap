import 'package:dio/dio.dart';
import 'sms_dispatch_service.dart';
import '../config/app_config.dart';
import '../../utils/logger.dart';

class HttpSmsDispatchService implements SmsDispatchService {
  final Dio _dio;

  HttpSmsDispatchService({Dio? dio}) : _dio = dio ?? Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    )
  );

  @override
  Future<void> sendSms({
    required String toPhoneNumber,
    required String body,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _dio.post(
        AppConfig.smsCloudFunctionUrl,
        data: {
          'toPhoneNumber': toPhoneNumber,
          'body': body,
          if (metadata != null) 'metadata': metadata,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.i('HTTP SMS dispatched successfully to $toPhoneNumber');
      } else {
        AppLogger.w('HTTP SMS dispatch returned unexpected status: ${response.statusCode}');
        throw Exception('Failed to send HTTP SMS: ${response.statusCode}');
      }
    } on DioException catch (e, st) {
      AppLogger.e('Dio HTTP SMS dispatch failed', e, st);
      throw Exception('Network error while dispatching SMS');
    } catch (e, st) {
      AppLogger.e('Unknown HTTP SMS dispatch error', e, st);
      throw Exception('Failed to send SMS');
    }
  }
}
