import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:logger/logger.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final InternetConnection _internetChecker = InternetConnection();
  final Logger _logger = Logger();

  final _controller = StreamController<bool>.broadcast();

  Stream<bool> get onConnectivityChanged => _controller.stream;

  ConnectivityService() {
    _init();
  }

  void _init() {
    _connectivity.onConnectivityChanged.listen((results) async {
      final hasSignal = results.any((r) => r != ConnectivityResult.none);
      if (!hasSignal) {
        _controller.add(false);
      } else {
        final hasRealInternet = await _internetChecker.hasInternetAccess;
        _controller.add(hasRealInternet);
      }
    });

    _internetChecker.onStatusChange.listen((status) {
      final isConnected = status == InternetStatus.connected;
      _logger.i('Internet status changed: $status');
      _controller.add(isConnected);
    });
  }

  Future<bool> checkHasInternet() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasSignal = results.any((r) => r != ConnectivityResult.none);
      if (!hasSignal) return false;
      return await _internetChecker.hasInternetAccess;
    } catch (e) {
      _logger.e('Error checking internet connectivity', error: e);
      return false;
    }
  }

  void dispose() {
    _controller.close();
  }
}
