import 'package:flutter/material.dart';

class AppSettings {
  final bool isDarkMode;
  final bool showPaliText;
  final bool enableNotifications;
  final TimeOfDay reminderTime;
  final bool enableSound;
  final bool enableHaptics;
  final int cardsPerSession;
  final bool autoPlayNext;

  AppSettings({
    this.isDarkMode = false,
    this.showPaliText = true,
    this.enableNotifications = true,
    this.reminderTime = const TimeOfDay(hour: 8, minute: 0),
    this.enableSound = false,
    this.enableHaptics = true,
    this.cardsPerSession = 20,
    this.autoPlayNext = false,
  });

  AppSettings copyWith({
    bool? isDarkMode,
    bool? showPaliText,
    bool? enableNotifications,
    TimeOfDay? reminderTime,
    bool? enableSound,
    bool? enableHaptics,
    int? cardsPerSession,
    bool? autoPlayNext,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      showPaliText: showPaliText ?? this.showPaliText,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      reminderTime: reminderTime ?? this.reminderTime,
      enableSound: enableSound ?? this.enableSound,
      enableHaptics: enableHaptics ?? this.enableHaptics,
      cardsPerSession: cardsPerSession ?? this.cardsPerSession,
      autoPlayNext: autoPlayNext ?? this.autoPlayNext,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isDarkMode': isDarkMode,
      'showPaliText': showPaliText,
      'enableNotifications': enableNotifications,
      'reminderHour': reminderTime.hour,
      'reminderMinute': reminderTime.minute,
      'enableSound': enableSound,
      'enableHaptics': enableHaptics,
      'cardsPerSession': cardsPerSession,
      'autoPlayNext': autoPlayNext,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      isDarkMode: json['isDarkMode'] as bool? ?? false,
      showPaliText: json['showPaliText'] as bool? ?? true,
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      reminderTime: TimeOfDay(
        hour: json['reminderHour'] as int? ?? 8,
        minute: json['reminderMinute'] as int? ?? 0,
      ),
      enableSound: json['enableSound'] as bool? ?? false,
      enableHaptics: json['enableHaptics'] as bool? ?? true,
      cardsPerSession: json['cardsPerSession'] as int? ?? 20,
      autoPlayNext: json['autoPlayNext'] as bool? ?? false,
    );
  }
}
