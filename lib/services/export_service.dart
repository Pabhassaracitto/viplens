import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/mindmap_model.dart';
import '../models/node_model.dart';
import 'database_service.dart';

class ExportService {
  /// Export mindmap thành Markdown
  static String exportToMarkdown(MindMapModel mindmap) {
    final buffer = StringBuffer();

    // Title
    buffer.writeln('# ${mindmap.title}');
    buffer.writeln();

    if (mindmap.description != null && mindmap.description!.isNotEmpty) {
      buffer.writeln('> ${mindmap.description}');
      buffer.writeln();
    }

    // Tags
    if (mindmap.tags.isNotEmpty) {
      buffer.writeln('**Tags:** ${mindmap.tags.map((t) => '#$t').join(' ')}');
      buffer.writeln();
    }

    // Content
    void writeNode(NodeModel node, int level) {
      if (level > 0) {
        final indent = '  ' * (level - 1);
        String line = '$indent- ${node.content}';
        if (node.paliText != null && node.paliText!.isNotEmpty) {
          line += ' *(${node.paliText})*';
        }
        buffer.writeln(line);

        if (node.note != null && node.note!.isNotEmpty) {
          buffer.writeln('$indent  > ${node.note}');
        }
      }

      for (final childId in node.childIds) {
        final child = mindmap.getNodeById(childId);
        if (child != null) {
          writeNode(child, level + 1);
        }
      }
    }

    writeNode(mindmap.rootNode, 0);

    // Metadata
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln('*Xuất từ Dhamma Mind*');
    buffer.writeln('*Ngày: ${DateTime.now().toString().substring(0, 10)}*');

    return buffer.toString();
  }

  /// Export mindmap thành JSON
  static String exportToJson(MindMapModel mindmap) {
    return const JsonEncoder.withIndent('  ').convert(mindmap.toJson());
  }

  /// Export tất cả dữ liệu thành JSON (backup)
  static String exportAllToJson() {
    final data = DatabaseService.exportAllData();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Export mindmap thành plain text
  static String exportToPlainText(MindMapModel mindmap) {
    final buffer = StringBuffer();

    buffer.writeln(mindmap.title);
    buffer.writeln('=' * mindmap.title.length);
    buffer.writeln();

    void writeNode(NodeModel node, int level) {
      if (level > 0) {
        final indent = '    ' * (level - 1);
        final prefix = level == 1 ? '■' : (level == 2 ? '●' : '○');
        String line = '$indent$prefix ${node.content}';
        if (node.paliText != null && node.paliText!.isNotEmpty) {
          line += ' (${node.paliText})';
        }
        buffer.writeln(line);
      }

      for (final childId in node.childIds) {
        final child = mindmap.getNodeById(childId);
        if (child != null) {
          writeNode(child, level + 1);
        }
      }
    }

    writeNode(mindmap.rootNode, 0);

    return buffer.toString();
  }

  /// Lưu file và chia sẻ
  static Future<void> shareText(String content, String filename) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(content);

    await Share.shareXFiles([XFile(file.path)], subject: filename);
  }

  /// Share Markdown
  static Future<void> shareAsMarkdown(MindMapModel mindmap) async {
    final content = exportToMarkdown(mindmap);
    final filename = '${_sanitizeFilename(mindmap.title)}.md';
    await shareText(content, filename);
  }

  /// Share JSON
  static Future<void> shareAsJson(MindMapModel mindmap) async {
    final content = exportToJson(mindmap);
    final filename = '${_sanitizeFilename(mindmap.title)}.json';
    await shareText(content, filename);
  }

  /// Share full backup
  static Future<void> shareBackup() async {
    final content = exportAllToJson();
    final date = DateTime.now().toString().substring(0, 10);
    final filename = 'dhamma_mind_backup_$date.json';
    await shareText(content, filename);
  }

  /// Export thành PDF
  static Future<Uint8List> exportToPdf(MindMapModel mindmap) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          final widgets = <pw.Widget>[];

          // Title
          widgets.add(
            pw.Header(
              level: 0,
              child: pw.Text(
                mindmap.title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          );

          // Description
          if (mindmap.description != null && mindmap.description!.isNotEmpty) {
            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Text(
                  mindmap.description!,
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            );
          }

          widgets.add(pw.SizedBox(height: 20));

          // Content
          void addNode(NodeModel node, int level) {
            if (level > 0) {
              widgets.add(
                pw.Padding(
                  padding: pw.EdgeInsets.only(left: (level - 1) * 20.0),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 6,
                        height: 6,
                        margin: const pw.EdgeInsets.only(top: 5, right: 8),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.blue,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              node.content,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: level == 1
                                    ? pw.FontWeight.bold
                                    : pw.FontWeight.normal,
                              ),
                            ),
                            if (node.paliText != null &&
                                node.paliText!.isNotEmpty)
                              pw.Text(
                                node.paliText!,
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.grey600,
                                  fontStyle: pw.FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
              widgets.add(pw.SizedBox(height: 4));
            }

            for (final childId in node.childIds) {
              final child = mindmap.getNodeById(childId);
              if (child != null) {
                addNode(child, level + 1);
              }
            }
          }

          addNode(mindmap.rootNode, 0);

          // Footer
          widgets.add(pw.SizedBox(height: 30));
          widgets.add(pw.Divider(color: PdfColors.grey300));
          widgets.add(
            pw.Text(
              'Xuất từ Dhamma Mind - ${DateTime.now().toString().substring(0, 10)}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
            ),
          );

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  /// Share PDF
  static Future<void> shareAsPdf(MindMapModel mindmap) async {
    final bytes = await exportToPdf(mindmap);
    final directory = await getTemporaryDirectory();
    final filename = '${_sanitizeFilename(mindmap.title)}.pdf';
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], subject: mindmap.title);
  }

  /// Sanitize filename
  static String _sanitizeFilename(String name) {
    return name
        .replaceAll(RegExp(r'[^\w\s\-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }
}
