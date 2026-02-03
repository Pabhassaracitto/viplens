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

  final Map<String, Offset> _nodePositions = {};
  final Map<String, Size> _nodeSizes = {};

  // Tăng khoảng cách để tránh chồng lấn
  static const double _nodeSpacingX = 220.0;
  static const double _nodeSpacingY = 25.0;
  static const double _rootOffsetX = 80.0;
  static const double _rootOffsetY = 800.0;

  @override
  void initState() {
    super.initState();
    _calculateLayout();
  }

  @override
  void didUpdateWidget(MindMapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mindmap != widget.mindmap ||
        oldWidget.showPaliText != widget.showPaliText) {
      _calculateLayout();
    }
  }

  void _calculateLayout() {
    _nodePositions.clear();
    _nodeSizes.clear();

    final root = widget.mindmap.rootNode;
    _layoutNode(root, _rootOffsetX, _rootOffsetY, 0);
  }

  double _layoutNode(NodeModel node, double x, double y, int depth) {
    final estimatedWidth = _estimateNodeWidth(node);
    final estimatedHeight = _estimateNodeHeight(node);
    _nodeSizes[node.id] = Size(estimatedWidth, estimatedHeight);

    final children = widget.mindmap.getChildren(node.id);

    if (children.isEmpty) {
      _nodePositions[node.id] = Offset(x, y);
      return y + estimatedHeight + _nodeSpacingY;
    }

    double childY = y;
    double minChildCenterY = double.infinity;
    double maxChildCenterY = 0;

    for (final child in children) {
      final childHeight = _estimateNodeHeight(child);

      final nextY = _layoutNode(child, x + _nodeSpacingX, childY, depth + 1);

      final childPos = _nodePositions[child.id];
      if (childPos != null) {
        final childCenterY = childPos.dy + childHeight / 2;
        minChildCenterY = math.min(minChildCenterY, childCenterY);
        maxChildCenterY = math.max(maxChildCenterY, childCenterY);
      }

      childY = nextY;
    }

    // Node cha nằm giữa các node con
    final parentCenterY = (minChildCenterY + maxChildCenterY) / 2;
    _nodePositions[node.id] = Offset(x, parentCenterY - estimatedHeight / 2);

    return childY;
  }

  double _estimateNodeWidth(NodeModel node) {
    return widget.isZenMode ? 250.0 : 180.0;
  }

  double _estimateNodeHeight(NodeModel node) {
    // Tăng chiều cao ước lượng để không bị cắt
    double height = 50.0;

    // Ước lượng số dòng dựa trên độ dài nội dung
    int contentLines = (node.content.length / 18).ceil();
    contentLines = contentLines.clamp(1, 4);
    height += (contentLines - 1) * 18.0;

    // Thêm không gian cho Pali
    if (node.paliText != null &&
        node.paliText!.isNotEmpty &&
        widget.showPaliText) {
      height += 22.0;
    }

    // Thêm không gian cho badge flashcard
    if (node.isFlashcard) {
      height += 24.0;
    }

    return height;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.isZenMode ? AppColors.zenBackground : Colors.grey[50],
      child: InteractiveViewer(
        transformationController: _transformationController,
        boundaryMargin: const EdgeInsets.all(1000),
        minScale: 0.1,
        maxScale: 3.0,
        constrained: false,
        child: SizedBox(
          width: 4000,
          height: 4000,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Vẽ đường nối
              Positioned.fill(
                child: CustomPaint(
                  painter: _ConnectionPainter(
                    mindmap: widget.mindmap,
                    nodePositions: _nodePositions,
                    nodeSizes: _nodeSizes,
                    isZenMode: widget.isZenMode,
                  ),
                ),
              ),

              // Vẽ các node - KHÔNG dùng RepaintBoundary
              ...widget.mindmap.nodes.map((node) {
                final position = _nodePositions[node.id];
                if (position == null) return const SizedBox.shrink();

                return Positioned(
                  left: position.dx,
                  top: position.dy,
                  child: NodeWidget(
                    key: ValueKey(node.id),
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
              }),
            ],
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

/// Vẽ đường nối giữa các node
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

    // Từ giữa cạnh phải của node cha
    final start = Offset(
      startPos.dx + startSize.width,
      startPos.dy + startSize.height / 2,
    );

    // Đến giữa cạnh trái của node con
    final end = Offset(endPos.dx, endPos.dy + endSize.height / 2);

    // Đường cong bezier
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
