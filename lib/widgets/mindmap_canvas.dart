import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/mindmap_model.dart';
import '../models/node_model.dart';
import '../utils/colors.dart';
import 'node_widget.dart';

class MindMapCanvas extends StatefulWidget {
  final MindMapModel mindmap;
  final String? selectedNodeId;
  final Function(String)? onNodeTap;
  final Function(String)? onNodeDoubleTap;
  final Function(String)? onNodeLongPress;
  final bool isZenMode;
  final bool showPaliText;

  const MindMapCanvas({
    super.key,
    required this.mindmap,
    this.selectedNodeId,
    this.onNodeTap,
    this.onNodeDoubleTap,
    this.onNodeLongPress,
    this.isZenMode = false,
    this.showPaliText = true,
  });

  @override
  State<MindMapCanvas> createState() => _MindMapCanvasState();
}

class _MindMapCanvasState extends State<MindMapCanvas> {
  final TransformationController _transformationController =
      TransformationController();

  Map<String, Offset> _nodePositions = {};
  Map<String, Size> _nodeSizes = {};

  static const double _nodeSpacingX = 180.0;
  static const double _nodeSpacingY = 80.0;
  static const double _rootOffsetX = 100.0;

  @override
  void initState() {
    super.initState();
    _calculateLayout();
  }

  @override
  void didUpdateWidget(MindMapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mindmap != widget.mindmap) {
      _calculateLayout();
    }
  }

  void _calculateLayout() {
    _nodePositions.clear();
    _nodeSizes.clear();

    final root = widget.mindmap.rootNode;
    _layoutNode(root, _rootOffsetX, 300, 0);
  }

  double _layoutNode(NodeModel node, double x, double y, int depth) {
    // Ước lượng size của node
    final estimatedWidth = _estimateNodeWidth(node);
    final estimatedHeight = _estimateNodeHeight(node);
    _nodeSizes[node.id] = Size(estimatedWidth, estimatedHeight);

    final children = widget.mindmap.getChildren(node.id);

    if (children.isEmpty) {
      _nodePositions[node.id] = Offset(x, y);
      return y + estimatedHeight + _nodeSpacingY;
    }

    // Layout children first
    double childY = y;
    double minChildY = double.infinity;
    double maxChildY = 0;

    for (final child in children) {
      final nextY = _layoutNode(child, x + _nodeSpacingX, childY, depth + 1);

      final childPos = _nodePositions[child.id];
      if (childPos != null) {
        minChildY = math.min(minChildY, childPos.dy);
        maxChildY = math.max(maxChildY, childPos.dy);
      }

      childY = nextY;
    }

    // Center parent vertically relative to children
    final centerY = (minChildY + maxChildY) / 2;
    _nodePositions[node.id] = Offset(x, centerY);

    return childY;
  }

  double _estimateNodeWidth(NodeModel node) {
    final textLength = node.content.length;
    final baseWidth = 80.0;
    final charWidth = 8.0;
    return math.min(180.0, math.max(baseWidth, textLength * charWidth));
  }

  double _estimateNodeHeight(NodeModel node) {
    double height = 40.0;
    if (node.paliText != null && node.paliText!.isNotEmpty) {
      height += 16.0;
    }
    if (node.isFlashcard) {
      height += 20.0;
    }
    return height;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.isZenMode ? AppColors.zenBackground : null,
      child: InteractiveViewer(
        transformationController: _transformationController,
        boundaryMargin: const EdgeInsets.all(500),
        minScale: 0.3,
        maxScale: 2.5,
        child: SizedBox(
          width: 2000,
          height: 2000,
          child: CustomPaint(
            painter: _ConnectionPainter(
              mindmap: widget.mindmap,
              nodePositions: _nodePositions,
              nodeSizes: _nodeSizes,
              isZenMode: widget.isZenMode,
            ),
            child: Stack(
              children: widget.mindmap.nodes.map((node) {
                final position = _nodePositions[node.id];
                if (position == null) return const SizedBox.shrink();

                return Positioned(
                  left: position.dx,
                  top: position.dy,
                  child: NodeWidget(
                    node: node,
                    isSelected: node.id == widget.selectedNodeId,
                    isRoot: node.id == widget.mindmap.rootNodeId,
                    showPaliText: widget.showPaliText,
                    isZenMode: widget.isZenMode,
                    onTap: () => widget.onNodeTap?.call(node.id),
                    onDoubleTap: () => widget.onNodeDoubleTap?.call(node.id),
                    onLongPress: () => widget.onNodeLongPress?.call(node.id),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }
}

/// Custom painter để vẽ các đường nối giữa nodes
class _ConnectionPainter extends CustomPainter {
  final MindMapModel mindmap;
  final Map<String, Offset> nodePositions;
  final Map<String, Size> nodeSizes;
  final bool isZenMode;

  _ConnectionPainter({
    required this.mindmap,
    required this.nodePositions,
    required this.nodeSizes,
    this.isZenMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final node in mindmap.nodes) {
      final nodePos = nodePositions[node.id];
      final nodeSize = nodeSizes[node.id];
      if (nodePos == null || nodeSize == null) continue;

      for (final childId in node.childIds) {
        final childPos = nodePositions[childId];
        final childSize = nodeSizes[childId];
        if (childPos == null || childSize == null) continue;

        final child = mindmap.getNodeById(childId);
        if (child == null) continue;

        _drawConnection(
          canvas,
          nodePos,
          nodeSize,
          childPos,
          childSize,
          AppColors.getNodeColor(child.colorIndex),
        );
      }
    }
  }

  void _drawConnection(
    Canvas canvas,
    Offset startPos,
    Size startSize,
    Offset endPos,
    Size endSize,
    Color color,
  ) {
    final paint = Paint()
      ..color = isZenMode
          ? AppColors.zenAccent.withOpacity(0.4)
          : color.withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Điểm bắt đầu (bên phải của node cha)
    final start = Offset(
      startPos.dx + startSize.width,
      startPos.dy + startSize.height / 2,
    );

    // Điểm kết thúc (bên trái của node con)
    final end = Offset(endPos.dx, endPos.dy + endSize.height / 2);

    // Vẽ đường cong bezier
    final controlPoint1 = Offset(start.dx + (end.dx - start.dx) / 2, start.dy);
    final controlPoint2 = Offset(start.dx + (end.dx - start.dx) / 2, end.dy);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        end.dx,
        end.dy,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ConnectionPainter oldDelegate) {
    return oldDelegate.nodePositions != nodePositions ||
        oldDelegate.mindmap != mindmap;
  }
}
