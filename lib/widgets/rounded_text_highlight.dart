import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Paints the actual laid-out selection without inserting inline widgets or
/// changing wrapping, baselines, recognizers, or accessibility text.
class RoundedTextHighlight extends SingleChildRenderObjectWidget {
  const RoundedTextHighlight({
    super.key,
    required this.selection,
    required this.color,
    required super.child,
  });

  final TextSelection? selection;
  final Color color;

  @override
  RenderRoundedTextHighlight createRenderObject(BuildContext context) =>
      RenderRoundedTextHighlight(selection, color);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderRoundedTextHighlight renderObject,
  ) => renderObject.update(selection, color);
}

class RenderRoundedTextHighlight extends RenderProxyBox {
  RenderRoundedTextHighlight(this._selection, this._color);
  TextSelection? _selection;
  Color _color;

  void update(TextSelection? selection, Color color) {
    if (_selection == selection && _color == color) return;
    _selection = selection;
    _color = color;
    markNeedsPaint();
  }

  RenderParagraph? _paragraph(RenderObject root) {
    if (root is RenderParagraph) return root;
    RenderParagraph? found;
    root.visitChildren((node) => found ??= _paragraph(node));
    return found;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final selection = _selection;
    final paragraph = child == null ? null : _paragraph(child!);
    if (selection != null && !selection.isCollapsed && paragraph != null) {
      final transform = paragraph.getTransformTo(this);
      final paint = Paint()..color = _color;
      for (final box in paragraph.getBoxesForSelection(selection)) {
        final rect = MatrixUtils.transformRect(transform, box.toRect());
        if (rect.isEmpty) continue;
        context.canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(
              rect.left - 2,
              rect.top - 1,
              rect.right + 2,
              rect.bottom + 1,
            ).shift(offset),
            const Radius.circular(6),
          ),
          paint,
        );
      }
    }
    super.paint(context, offset);
  }
}
