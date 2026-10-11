import 'package:flutter/material.dart';

/// Text painted with the metallic gradient of the titles, the car name and the
/// battery (spec 3.1): a vertical fade from white to a cool grey.
///
/// One line by default; what does not fit ends in an ellipsis.
class MetalText extends StatelessWidget {
  const MetalText(
    this.text, {
    super.key,
    required this.style,
    this.maxLines = 1,
  });

  final String text;
  final TextStyle style;
  final int maxLines;

  /// Top of the gradient, `#FFFFFF`.
  static const Color top = Color(0xFFFFFFFF);

  /// Bottom of the gradient, `#8E959F`.
  static const Color bottom = Color(0xFF8E959F);

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      // The glyphs are drawn opaque white; the gradient takes their shape.
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, bottom],
      ).createShader(bounds),
      child: Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: style.copyWith(color: top),
      ),
    );
  }
}
