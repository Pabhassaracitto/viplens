class BuddhistTemplates {
  static const List<String> templateNames = [
    'Tứ Diệu Đế',
    'Bát Chánh Đạo',
    'Ngũ Uẩn',
    'Thập Nhị Nhân Duyên',
  ];

  static List<String>? getTemplate(String name) {
    switch (name) {
      case 'Tứ Diệu Đế':
        return [
          '- Khổ đế (Dukkha)',
          '  - Sinh là khổ',
          '  - Già là khổ',
          '  - Bệnh là khổ',
          '  - Chết là khổ',
          '- Tập đế (Samudaya)',
          '  - Dục ái',
          '  - Hữu ái',
          '  - Phi hữu ái',
          '- Diệt đế (Nirodha)',
          '  - Sự diệt tận của khát ái',
          '- Đạo đế (Magga)',
          '  - Bát chánh đạo'
        ];
      case 'Bát Chánh Đạo':
        return [
          '- Chánh kiến (Sammā-diṭṭhi)',
          '- Chánh tư duy (Sammā-saṅkappa)',
          '- Chánh ngữ (Sammā-vācā)',
          '- Chánh nghiệp (Sammā-kammanta)',
          '- Chánh mạng (Sammā-ājīva)',
          '- Chánh tinh tấn (Sammā-vāyāma)',
          '- Chánh niệm (Sammā-sati)',
          '- Chánh định (Sammā-samādhi)'
        ];
      case 'Ngũ Uẩn':
        return [
          '- Sắc uẩn (Rūpa)',
          '- Thọ uẩn (Vedanā)',
          '- Tưởng uẩn (Saññā)',
          '- Hành uẩn (Saṅkhāra)',
          '- Thức uẩn (Viññāṇa)'
        ];
      case 'Thập Nhị Nhân Duyên':
        return [
          '- Vô minh (Avijjā)',
          '- Hành (Saṅkhāra)',
          '- Thức (Viññāṇa)',
          '- Danh sắc (Nāma-rūpa)',
          '- Lục nhập (Saḷāyatana)',
          '- Xúc (Phassa)',
          '- Thọ (Vedanā)',
          '- Ái (Taṇhā)',
          '- Thủ (Upādāna)',
          '- Hữu (Bhava)',
          '- Sinh (Jāti)',
          '- Lão tử (Jarā-maraṇa)'
        ];
      default:
        return null;
    }
  }
}
