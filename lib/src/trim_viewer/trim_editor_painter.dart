import 'package:flutter/material.dart';
import 'package:video_trimmer/src/utils/duration_style.dart';

enum TextPosition {
  top,
  bottom,
  center;

  double value() {
    switch (this) {
      case TextPosition.top:
        return -1;
      case TextPosition.bottom:
        return 1;
      case TextPosition.center:
        return 0;
    }
  }
}

class TrimEditorPainter extends CustomPainter {
  /// To define the start offset
  final Offset startPos;

  /// To define the end offset
  final Offset endPos;

  final double videoStartPos;

  final double videoEndPos;

  final DurationStyle durationStyle;

  /// For showing the trimmer details
  final bool showTrimmerDetails;

  /// To define the horizontal length of the selected video area
  final double scrubberAnimationDx;

  /// For specifying a circular border radius
  /// to the corners of the trim area.
  /// By default it is set to `4.0`.
  final double borderRadius;

  /// For specifying a size to the start holder
  /// of the video trimmer area.
  /// By default it is set to `0.5`.
  final double startCircleSize;

  /// For specifying a size to the end holder
  /// of the video trimmer area.
  /// By default it is set to `0.5`.
  final double endCircleSize;

  /// For specifying the width of the border around
  /// the trim area. By default it is set to `3`.
  final double borderWidth;

  /// For specifying the width of the video scrubber
  final double scrubberWidth;

  /// For specifying whether to show the scrubber
  final bool showScrubber;

  /// For specifying a color to the border of
  /// the trim area. By default it is set to `Colors.white`.
  final Color borderPaintColor;

  /// For specifying a color to the circle.
  /// By default it is set to `Colors.white`
  final Color circlePaintColor;

  /// For specifying a color to the video
  /// scrubber inside the trim area. By default it is set to
  /// `Colors.white`.
  final Color scrubberPaintColor;

  final bool isCenterPadding;

  final double textFontSize;

  final Color textColor;

  final Color backgroundColor;

  final double endAndStartPadding;

  final double rectHorizontalPadding;

  final double rectVerticalPadding;

  final TextPosition textPosition;

  /// For drawing the trim editor slider
  ///
  /// The required parameters are [startPos], [endPos]
  /// & [scrubberAnimationDx]
  ///
  /// * [startPos] to define the start offset
  ///
  ///
  /// * [endPos] to define the end offset
  ///
  ///
  /// * [scrubberAnimationDx] to define the horizontal length of the
  /// selected video area
  ///
  ///
  /// The optional parameters are:
  ///
  /// * [startCircleSize] for specifying a size to the start holder
  /// of the video trimmer area.
  /// By default it is set to `0.5`.
  ///
  ///
  /// * [endCircleSize] for specifying a size to the end holder
  /// of the video trimmer area.
  /// By default it is set to `0.5`.
  ///
  ///
  /// * [borderRadius] for specifying a circular border radius
  /// to the corners of the trim area.
  /// By default it is set to `4.0`.
  ///
  ///
  /// * [borderWidth] for specifying the width of the border around
  /// the trim area. By default it is set to `3`.
  ///
  ///
  /// * [scrubberWidth] for specifying the width of the video scrubber
  ///
  ///
  /// * [showScrubber] for specifying whether to show the scrubber
  ///
  ///
  /// * [borderPaintColor] for specifying a color to the border of
  /// the trim area. By default it is set to `Colors.white`.
  ///
  ///
  /// * [circlePaintColor] for specifying a color to the circle.
  /// By default it is set to `Colors.white`.
  ///
  ///
  /// * [scrubberPaintColor] for specifying a color to the video
  /// scrubber inside the trim area. By default it is set to
  /// `Colors.white`.
  ///
  TrimEditorPainter({
    required this.startPos,
    required this.endPos,
    required this.videoStartPos,
    required this.videoEndPos,
    this.durationStyle = DurationStyle.FORMAT_MM_SS_MS,
    required this.showTrimmerDetails,
    required this.scrubberAnimationDx,
    this.startCircleSize = 0.5,
    this.endCircleSize = 0.5,
    this.borderRadius = 4,
    this.borderWidth = 3,
    this.scrubberWidth = 1,
    this.showScrubber = true,
    this.borderPaintColor = Colors.white,
    this.circlePaintColor = Colors.white,
    this.scrubberPaintColor = Colors.white,
    this.isCenterPadding = false,
    this.textFontSize = 14,
    this.textColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.endAndStartPadding = 8,
    this.rectHorizontalPadding = 8,
    this.rectVerticalPadding = 4,
    this.textPosition = TextPosition.top,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var borderPaint = Paint()
      ..color = borderPaintColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    var circlePaint = Paint()
      ..color = circlePaintColor
      ..strokeWidth = 1
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    var scrubberPaint = Paint()
      ..color = scrubberPaintColor
      ..strokeWidth = scrubberWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromPoints(startPos, endPos);
    final roundedRect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    if (showScrubber) {
      if (scrubberAnimationDx.toInt() > startPos.dx.toInt()) {
        canvas.drawLine(
          Offset(scrubberAnimationDx, 0),
          Offset(scrubberAnimationDx, 0) + Offset(0, endPos.dy),
          scrubberPaint,
        );
      }
    }

    final vStartPos = Duration(milliseconds: videoStartPos.toInt()).format(durationStyle);
    final vEndPos = Duration(milliseconds: videoEndPos.toInt()).format(durationStyle);
    final vTotalPos = Duration(milliseconds: videoEndPos.toInt() - videoStartPos.toInt()).format(durationStyle);

    // Calculate the width and height of the text and background rectangle
    double rectWidth = durationStyle.charLength() * (textFontSize / 2) + rectHorizontalPadding;
    double rectHeight = textFontSize + rectVerticalPadding;
    double textYOffset = textFontSize / 2;
    double textXOffset = (rectWidth / 2) - (durationStyle.charLength() * (textFontSize / 4));
    double centerPadding = isCenterPadding ? endAndStartPadding + textFontSize : 0;
    double xOffSet = 0;
    double yOffSet = textPosition.value() * (26 + textFontSize);

    //-------------------------

    canvas.drawRRect(roundedRect, borderPaint);
    // Paint start holder
    canvas.drawCircle(startPos + Offset(0, endPos.dy / 2), startCircleSize, circlePaint);
    // Paint end holder
    canvas.drawCircle(endPos + Offset(0, -endPos.dy / 2), endCircleSize, circlePaint);

    if (showTrimmerDetails) {
      // Add a background for the text above the start holder
      RRect startTextBackgroundRect = RRect.fromRectAndRadius(
        Rect.fromLTWH((startPos.dx + xOffSet) + endAndStartPadding, (startPos.dy + yOffSet) + endPos.dy / 2 - rectHeight / 2, rectWidth, rectHeight),
        Radius.circular(4),
      );
      Paint startTextBackgroundPaint = Paint()..color = backgroundColor;
      canvas.drawRRect(startTextBackgroundRect, startTextBackgroundPaint);

      // Add a text above the start holder
      TextPainter tp = TextPainter(
        text: TextSpan(text: vStartPos, style: TextStyle(color: textColor, fontSize: textFontSize)),
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, startPos + Offset(0, endPos.dy / 2) + Offset(endAndStartPadding + xOffSet + textXOffset, -textYOffset + yOffSet));

      //-------------------------

      // Add a background for the text above the end holder

      RRect endTextBackgroundRect = RRect.fromRectAndRadius(
        Rect.fromLTWH((endPos.dx + xOffSet) - rectWidth - endAndStartPadding, (startPos.dy + yOffSet) + endPos.dy / 2 - rectHeight / 2, rectWidth, rectHeight),
        Radius.circular(4),
      );
      Paint endTextBackgroundPaint = Paint()..color = backgroundColor;
      canvas.drawRRect(endTextBackgroundRect, endTextBackgroundPaint);

      //add a text above the end holder
      tp = TextPainter(
        text: TextSpan(text: vEndPos, style: TextStyle(color: textColor, fontSize: textFontSize)),
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, endPos + Offset(0, -endPos.dy / 2) + Offset(-rectWidth - endAndStartPadding + xOffSet + textXOffset, -textYOffset + yOffSet));

      //-------------------------

      // Add a background for the text in the middle of the trim area

      RRect totalTextBackgroundRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          (startPos.dx + xOffSet) + (endPos.dx - startPos.dx) / 2 - rectWidth / 2 - centerPadding,
          (endPos.dy / 2 + yOffSet) - rectHeight / 2,
          rectWidth + 2 * centerPadding,
          rectHeight,
        ),
        Radius.circular(4),
      );
      Paint totalTextBackgroundPaint = Paint()..color = backgroundColor;
      canvas.drawRRect(totalTextBackgroundRect, totalTextBackgroundPaint);

      //paint in the middle of the trim area the time from start to end selected
      tp = TextPainter(
        text: TextSpan(text: vTotalPos, style: TextStyle(color: textColor, fontSize: textFontSize)),
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(
          canvas, startPos + Offset((endPos.dx - startPos.dx) / 2, endPos.dy / 2) + Offset(-rectWidth / 2 + xOffSet + textXOffset, -textYOffset + yOffSet));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
