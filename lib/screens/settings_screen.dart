// Giai đoạn 2
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/notification_service.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';
import '../utils/helpers.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          final settings = settingsProvider.settings;

          return ListView(
            children: [
              // Appearance
              _buildSectionHeader(context, 'Giao diện'),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: const Text('Chế độ tối'),
                subtitle: const Text('Bật giao diện tối'),
                value: settings.isDarkMode,
                onChanged: (_) => settingsProvider.toggleDarkMode(),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.translate),
                title: const Text('Hiển thị Pali'),
                subtitle: const Text('Hiển thị văn bản Pali trên các node'),
                value: settings.showPaliText,
                onChanged: (_) => settingsProvider.togglePaliText(),
              ),

              const Divider(),

              // Notifications
              _buildSectionHeader(context, 'Thông báo'),
              SwitchListTile(
                secondary: const Icon(Icons.notifications),
                title: const Text('Nhắc nhở ôn tập'),
                subtitle: const Text('Nhận thông báo nhắc ôn tập hàng ngày'),
                value: settings.enableNotifications,
                onChanged: (_) async {
                  if (!settings.enableNotifications) {
                    final granted =
                        await NotificationService.requestPermission();
                    if (!granted) {
                      if (context.mounted) {
                        Helpers.showSnackBar(
                          context,
                          'Vui lòng cấp quyền thông báo trong cài đặt',
                          isError: true,
                        );
                      }
                      return;
                    }
                  }
                  settingsProvider.toggleNotifications();
                },
              ),
              if (settings.enableNotifications)
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Thời gian nhắc nhở'),
                  subtitle: Text(
                    '${settings.reminderTime.hour.toString().padLeft(2, '0')}:'
                    '${settings.reminderTime.minute.toString().padLeft(2, '0')}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: settings.reminderTime,
                    );
                    if (time != null) {
                      settingsProvider.setReminderTime(time);
                    }
                  },
                ),

              const Divider(),

              // Review settings
              _buildSectionHeader(context, 'Ôn tập'),
              SwitchListTile(
                secondary: const Icon(Icons.vibration),
                title: const Text('Rung phản hồi'),
                subtitle: const Text('Rung khi vuốt thẻ'),
                value: settings.enableHaptics,
                onChanged: (_) => settingsProvider.toggleHaptics(),
              ),
              ListTile(
                leading: const Icon(Icons.filter_9_plus),
                title: const Text('Số thẻ mỗi phiên'),
                subtitle: Text('${settings.cardsPerSession} thẻ'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    _showCardsPerSessionDialog(context, settingsProvider),
              ),

              const Divider(),

              // Data
              _buildSectionHeader(context, 'Dữ liệu'),
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('Sao lưu dữ liệu'),
                subtitle: const Text('Xuất toàn bộ dữ liệu ra file'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _backupData(context),
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Khôi phục dữ liệu'),
                subtitle: const Text('Nhập dữ liệu từ file backup'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _restoreData(context),
              ),

              const Divider(),

              // About
              _buildSectionHeader(context, 'Thông tin'),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Về ứng dụng'),
                subtitle: Text('Phiên bản ${AppConstants.appVersion}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAboutDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('Mã nguồn mở'),
                subtitle: const Text('Xem trên GitHub'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  // TODO: Open GitHub link
                  Helpers.showSnackBar(context, 'Sẽ sớm có link GitHub');
                },
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          letterSpacing: 1,
        ),
      ),
    );
  }

  void _showCardsPerSessionDialog(
    BuildContext context,
    SettingsProvider provider,
  ) {
    final options = [10, 15, 20, 30, 50, 100];

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Số thẻ mỗi phiên',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            ...options.map(
              (count) => ListTile(
                title: Text('$count thẻ'),
                trailing: provider.settings.cardsPerSession == count
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  provider.setCardsPerSession(count);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _backupData(BuildContext context) async {
    try {
      await ExportService.shareBackup();
      if (context.mounted) {
        Helpers.showSnackBar(context, 'Đã tạo file backup');
      }
    } catch (e) {
      if (context.mounted) {
        Helpers.showSnackBar(context, 'Lỗi: $e', isError: true);
      }
    }
  }

  Future<void> _restoreData(BuildContext context) async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      title: 'Khôi phục dữ liệu?',
      message: 'Dữ liệu hiện tại sẽ được gộp với dữ liệu từ file backup.',
      confirmText: 'Tiếp tục',
    );

    if (!confirmed) return;

    final result = await ImportService.pickAndImport();

    if (context.mounted) {
      Helpers.showSnackBar(context, result.message, isError: !result.success);
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: const Text('🪷', style: TextStyle(fontSize: 48)),
      children: const [
        Text(AppConstants.appDescription),
        SizedBox(height: 16),
        Text(
          'Ứng dụng mã nguồn mở, phi lợi nhuận.\n'
          'Dành cho việc học tập và tu tập Phật pháp.\n\n'
          '🙏 Nguyện cầu tất cả chúng sinh an lạc.',
          style: TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}
