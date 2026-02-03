/// Các hằng số của ứng dụng
class AppConstants {
  // App info
  static const String appName = 'Dhamma Mind';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Ứng dụng Mindmap cho việc học tập và tu tập Phật pháp';

  // Database
  static const String mindmapBoxName = 'mindmaps';
  static const String settingsBoxName = 'settings';

  // UI
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  static const double borderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 20.0;

  static const double nodeMinWidth = 80.0;
  static const double nodeMaxWidth = 200.0;
  static const double nodeHeight = 40.0;
  static const double nodeSpacing = 60.0;
  static const double levelSpacing = 100.0;

  // Animation
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 350);
  static const Duration longDuration = Duration(milliseconds: 500);

  // Spaced Repetition
  static const double defaultEaseFactor = 2.5;
  static const double minEaseFactor = 1.3;
  static const int masteryThresholdDays = 21;

  // Limits
  static const int maxNodeContentLength = 500;
  static const int maxTitleLength = 100;
  static const int maxTagsCount = 10;
}

/// Các key cho SharedPreferences / Hive settings
class SettingsKeys {
  static const String isDarkMode = 'isDarkMode';
  static const String defaultZenMode = 'defaultZenMode';
  static const String showPaliText = 'showPaliText';
  static const String lastBackupDate = 'lastBackupDate';
  static const String reviewReminder = 'reviewReminder';
  static const String reminderTime = 'reminderTime';
}

/// Các template Phật học có sẵn
class BuddhistTemplates {
  static const Map<String, List<String>> templates = {
    'Tứ Diệu Đế': [
      'Khổ đế (Dukkha)',
      'Tập đế (Samudaya)',
      'Diệt đế (Nirodha)',
      'Đạo đế (Magga)',
    ],
    'Bát Chánh Đạo': [
      'Chánh kiến (Sammā-diṭṭhi)',
      'Chánh tư duy (Sammā-saṅkappa)',
      'Chánh ngữ (Sammā-vācā)',
      'Chánh nghiệp (Sammā-kammanta)',
      'Chánh mạng (Sammā-ājīva)',
      'Chánh tinh tấn (Sammā-vāyāma)',
      'Chánh niệm (Sammā-sati)',
      'Chánh định (Sammā-samādhi)',
    ],
    'Ngũ Uẩn': [
      'Sắc uẩn (Rūpa)',
      'Thọ uẩn (Vedanā)',
      'Tưởng uẩn (Saññā)',
      'Hành uẩn (Saṅkhāra)',
      'Thức uẩn (Viññāṇa)',
    ],
    'Thập Nhị Nhân Duyên': [
      'Vô minh (Avijjā)',
      'Hành (Saṅkhāra)',
      'Thức (Viññāṇa)',
      'Danh sắc (Nāma-rūpa)',
      'Lục nhập (Saḷāyatana)',
      'Xúc (Phassa)',
      'Thọ (Vedanā)',
      'Ái (Taṇhā)',
      'Thủ (Upādāna)',
      'Hữu (Bhava)',
      'Sinh (Jāti)',
      'Lão tử (Jarā-maraṇa)',
    ],
    'Thất Giác Chi': [
      'Niệm giác chi (Sati)',
      'Trạch pháp giác chi (Dhamma-vicaya)',
      'Tinh tấn giác chi (Vīriya)',
      'Hỷ giác chi (Pīti)',
      'Khinh an giác chi (Passaddhi)',
      'Định giác chi (Samādhi)',
      'Xả giác chi (Upekkhā)',
    ],
    'Tứ Niệm Xứ': [
      'Thân niệm xứ (Kāyānupassanā)',
      'Thọ niệm xứ (Vedanānupassanā)',
      'Tâm niệm xứ (Cittānupassanā)',
      'Pháp niệm xứ (Dhammānupassanā)',
    ],
    'Tam Học': [
      'Giới (Sīla)',
      'Định (Samādhi)',
      'Tuệ (Paññā)',
    ],
    'Tứ Vô Lượng Tâm': [
      'Từ (Mettā)',
      'Bi (Karuṇā)',
      'Hỷ (Muditā)',
      'Xả (Upekkhā)',
    ],
    'Ngũ Giới': [
      'Không sát sinh (Pāṇātipātā)',
      'Không trộm cắp (Adinnādānā)',
      'Không tà dâm (Kāmesumicchācāra)',
      'Không nói dối (Musāvādā)',
      'Không uống rượu (Surāmerayamajjapamādaṭṭhānā)',
    ],
    'Lục Độ': [
      'Bố thí (Dāna)',
      'Trì giới (Sīla)',
      'Nhẫn nhục (Khanti)',
      'Tinh tấn (Vīriya)',
      'Thiền định (Jhāna)',
      'Trí tuệ (Paññā)',
    ],
  };

  /// Lấy danh sách tên templates
  static List<String> get templateNames => templates.keys.toList();

  /// Lấy nội dung template theo tên
  static List<String>? getTemplate(String name) => templates[name];
}
