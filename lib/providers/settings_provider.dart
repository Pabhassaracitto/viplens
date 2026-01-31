import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = AppSettings();

  AppSettings get settings => _settings;

  /// Load settings từ database
  Future<void> loadSettings() async {
    final json = DatabaseService.getSetting<Map>('appSettings');
    if (json != null) {
      _settings = AppSettings.fromJson(Map<String, dynamic>.from(json));
    }
    notifyListeners();
  }

  /// Lưu settings
  Future<void> _saveSettings() async {
    await DatabaseService.saveSetting('appSettings', _settings.toJson());
  }

  /// Toggle dark mode
  Future<void> toggleDarkMode() async {
    _settings = _settings.copyWith(isDarkMode: !_settings.isDarkMode);
    await _saveSettings();
    notifyListeners();
  }

  /// Set dark mode
  Future<void> setDarkMode(bool value) async {
    _settings = _settings.copyWith(isDarkMode: value);
    await _saveSettings();
    notifyListeners();
  }

  /// Toggle Pali text
  Future<void> togglePaliText() async {
    _settings = _settings.copyWith(showPaliText: !_settings.showPaliText);
    await _saveSettings();
    notifyListeners();
  }

  /// Toggle notifications
  Future<void> toggleNotifications() async {
    final newValue = !_settings.enableNotifications;
    _settings = _settings.copyWith(enableNotifications: newValue);

    if (newValue) {
      await NotificationService.scheduleDailyReminder(_settings.reminderTime);
    } else {
      await NotificationService.cancelAll();
    }

    await _saveSettings();
    notifyListeners();
  }

  /// Set reminder time
  Future<void> setReminderTime(TimeOfDay time) async {
    _settings = _settings.copyWith(reminderTime: time);

    if (_settings.enableNotifications) {
      await NotificationService.scheduleDailyReminder(time);
    }

    await _saveSettings();
    notifyListeners();
  }

  /// Toggle haptics
  Future<void> toggleHaptics() async {
    _settings = _settings.copyWith(enableHaptics: !_settings.enableHaptics);
    await _saveSettings();
    notifyListeners();
  }

  /// Set cards per session
  Future<void> setCardsPerSession(int count) async {
    _settings = _settings.copyWith(cardsPerSession: count);
    await _saveSettings();
    notifyListeners();
  }
}
