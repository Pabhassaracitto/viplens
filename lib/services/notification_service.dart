import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Khởi tạo notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  }

  /// Xử lý khi tap vào notification
  static void _onNotificationTap(NotificationResponse response) {
    // TODO: Navigate to review screen
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Yêu cầu quyền notification (Android 13+)
  static Future<bool> requestPermission() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    return true;
  }

  /// Lên lịch nhắc nhở ôn tập hàng ngày
  static Future<void> scheduleDailyReminder(TimeOfDay time) async {
    await _notifications.cancelAll();

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Nếu thời gian đã qua hôm nay, lên lịch cho ngày mai
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      0,
      '🪷 Dhamma Mind',
      'Đã đến giờ ôn tập! Hãy dành vài phút để củng cố kiến thức.',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Nhắc nhở hàng ngày',
          channelDescription: 'Nhắc nhở ôn tập hàng ngày',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Lặp lại hàng ngày
      payload: 'review',
    );
  }

  /// Hiển thị notification ngay lập tức
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'general',
          'Thông báo chung',
          channelDescription: 'Thông báo chung từ ứng dụng',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  /// Hiển thị notification khi có thẻ cần ôn tập
  static Future<void> showDueCardsNotification(int count) async {
    if (count <= 0) return;

    await showNotification(
      title: '🎴 Có $count thẻ cần ôn tập',
      body: 'Hãy dành vài phút để củng cố kiến thức của bạn.',
      payload: 'review',
    );
  }

  /// Hủy tất cả notifications
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Cập nhật badge count (iOS)
  static Future<void> updateBadge(int count) async {
    // iOS badge is handled automatically with notifications
  }
}
