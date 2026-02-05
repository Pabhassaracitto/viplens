import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/mindmap_model.dart';
import '../models/node_model.dart';
import '../services/screenshot_service.dart';
import '../utils/colors.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/image_viewer_widget.dart';

class PresentationScreen extends StatefulWidget {
  final MindMapModel mindmap;

  const PresentationScreen({
    super.key,
    required this.mindmap,
  });

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen>
    with SingleTickerProviderStateMixin {
  late List<NodeModel> _presentationNodes;
  int _currentIndex = 0;
  bool _showControls = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final GlobalKey _screenshotKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Giữ màn hình sáng
    WakelockPlus.enable();

    // Ẩn status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Lấy danh sách nodes theo thứ tự
    _presentationNodes = _getOrderedNodes();

    // Animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  List<NodeModel> _getOrderedNodes() {
    final nodes = <NodeModel>[];

    void addNode(NodeModel node) {
      nodes.add(node);
      for (final childId in node.childIds) {
        final child = widget.mindmap.getNodeById(childId);
        if (child != null) {
          addNode(child);
        }
      }
    }

    addNode(widget.mindmap.rootNode);
    return nodes;
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _fadeController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentIndex < _presentationNodes.length - 1) {
      _fadeController.reverse().then((_) {
        setState(() {
          _currentIndex++;
        });
        _fadeController.forward();
      });
    }
  }

  void _previous() {
    if (_currentIndex > 0) {
      _fadeController.reverse().then((_) {
        setState(() {
          _currentIndex--;
        });
        _fadeController.forward();
      });
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  Future<void> _shareCurrentSlide() async {
    // Tạm ẩn controls để screenshot đẹp hơn
    setState(() => _showControls = false);
    await Future.delayed(const Duration(milliseconds: 100)); // Chờ UI update

    await ScreenshotService.captureAndShare(
      _screenshotKey,
      title: 'Chia sẻ slide: ${widget.mindmap.title}',
      text: _presentationNodes[_currentIndex].content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentNode = _presentationNodes[_currentIndex];
    final parentNode = currentNode.parentId != null
        ? widget.mindmap.getNodeById(currentNode.parentId!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.zenBackground,
      body: RepaintBoundary(
        key: _screenshotKey,
        child: GestureDetector(
          onTap: _toggleControls,
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! < 0) {
              _next();
            } else if (details.primaryVelocity! > 0) {
              _previous();
            }
          },
          child: Stack(
            children: [
              // Content
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Breadcrumb
                        if (parentNode != null)
                          Text(
                            parentNode.content,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.zenText.withAlpha(128),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Pali text
                        if (currentNode.paliText != null &&
                            currentNode.paliText!.isNotEmpty)
                          Text(
                            currentNode.paliText!,
                            style: TextStyle(
                              fontSize: 24,
                              fontStyle: FontStyle.italic,
                              color: AppColors.zenAccent.withAlpha(204),
                            ),
                            textAlign: TextAlign.center,
                          ),

                        const SizedBox(height: 16),

                        // Main content
                        Text(
                          currentNode.content,
                          style: TextStyle(
                            fontSize: currentNode.level == 0 ? 42 : 32,
                            fontWeight: currentNode.level == 0
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: AppColors.zenText,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        // Note
                        if (currentNode.note != null &&
                            currentNode.note!.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.zenSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              currentNode.note!,
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.zenText.withAlpha(204),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],

                        // Image
                        if (currentNode.hasImage) ...[
                          const SizedBox(height: 32),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ImageViewerWidget(
                                    imagePath: currentNode.imagePath ?? '',
                                    imageUrl: currentNode.imageUrl,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              constraints: const BoxConstraints(
                                maxHeight: 200,
                                maxWidth: 300,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(77),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: currentNode.imagePath != null
                                    ? Image.file(
                                        File(currentNode.imagePath!),
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(currentNode.imageUrl!,
                                        fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        ],

                        // Audio
                        if (currentNode.hasAudio) ...[
                          const SizedBox(height: 32),
                          AudioPlayerWidget(
                            audioPath: currentNode.audioPath!,
                            durationMs: currentNode.audioDuration,
                            compact: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Controls overlay
              if (_showControls) ...[
                // Top bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      right: 16,
                      bottom: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(128),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Text(
                          widget.mindmap.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.white),
                          onPressed: _shareCurrentSlide,
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                      left: 24,
                      right: 24,
                      top: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withAlpha(128),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Progress bar
                        LinearProgressIndicator(
                          value:
                              (_currentIndex + 1) / _presentationNodes.length,
                          backgroundColor: Colors.white24,
                          valueColor:
                              const AlwaysStoppedAnimation(Colors.white),
                        ),
                        const SizedBox(height: 16),

                        // Navigation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left,
                                  color: Colors.white, size: 32),
                              onPressed: _currentIndex > 0 ? _previous : null,
                            ),
                            Text(
                              '${_currentIndex + 1} / ${_presentationNodes.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right,
                                  color: Colors.white, size: 32),
                              onPressed:
                                  _currentIndex < _presentationNodes.length - 1
                                      ? _next
                                      : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
