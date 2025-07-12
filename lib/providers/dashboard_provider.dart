import 'package:flutter/material.dart';

import '../core/api_status.dart';
import '../core/storage/storage_service.dart';

class DashboardProvider extends ChangeNotifier {

  DashboardProvider({required StorageService storageService})
   : _storageService = storageService;

  final StorageService _storageService;

  final Map<String,String> _otpEntries = {};

  Map<String,String> get otpEntries => _otpEntries;

  ApiStatus _apiStatus = ApiStatus.initial;

  ApiStatus get apiStatus => _apiStatus;

  void loadOtpEntries() async {
    try {
      _apiStatus = ApiStatus.loading;
      notifyListeners();
      final secretKeys = await _storageService.getAllSecretKeys();
      _otpEntries.clear();
      _otpEntries.addAll(secretKeys);
      if(_otpEntries.isNotEmpty) {
        _apiStatus = ApiStatus.success;
      } else {
        _apiStatus = ApiStatus.empty;
      }
    } catch(e) {
      _apiStatus = ApiStatus.error;
    } finally {
      notifyListeners();
    }
  }

  int get otpEntriesCount => _otpEntries.length;
}