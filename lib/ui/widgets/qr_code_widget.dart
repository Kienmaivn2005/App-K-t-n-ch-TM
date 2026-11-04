import 'dart:math';
import 'package:flutter/material.dart';

/// Widget vẽ mã QR mô phỏng chuẩn xác bằng CustomPainter (không phụ thuộc package ngoài)
class SimpleQrCodeWidget extends StatelessWidget {
  final String data;
  final double size;
  final Color darkColor;
  final Color lightColor;
  final String? centerLabel;

  const SimpleQrCodeWidget({
    super.key,
    required this.data,
    this.size = 180,
    this.darkColor = const Color(0xFF0F172A),
    this.lightColor = Colors.white,
    this.centerLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _SimpleQrPainter(
          data: data,
          darkColor: darkColor,
          lightColor: lightColor,
          centerLabel: centerLabel,
        ),
      ),
    );
  }
}

class _SimpleQrPainter extends CustomPainter {
  final String data;
  final Color darkColor;
  final Color lightColor;
  final String? centerLabel;

  _SimpleQrPainter({
    required this.data,
    required this.darkColor,
    required this.lightColor,
    this.centerLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final darkPaint = Paint()..color = darkColor..style = PaintingStyle.fill;

    const moduleCount = 25; // 25x25 grid
    final cellSize = size.width / moduleCount;

    // Pseudo-random deterministic grid generator based on data hash
    final seed = data.hashCode.abs();
    final random = Random(seed);

    // 1. Draw corner finder patterns (top-left, top-right, bottom-left)
    void drawFinderPattern(int startX, int startY) {
      // 7x7 outer square
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(startX * cellSize, startY * cellSize, 7 * cellSize, 7 * cellSize),
          const Radius.circular(4),
        ),
        darkPaint,
      );
      // 5x5 inner white
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH((startX + 1) * cellSize, (startY + 1) * cellSize, 5 * cellSize, 5 * cellSize),
          const Radius.circular(3),
        ),
        Paint()..color = lightColor,
      );
      // 3x3 solid core
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH((startX + 2) * cellSize, (startY + 2) * cellSize, 3 * cellSize, 3 * cellSize),
          const Radius.circular(2),
        ),
        darkPaint,
      );
    }

    drawFinderPattern(0, 0); // Top-left
    drawFinderPattern(moduleCount - 7, 0); // Top-right
    drawFinderPattern(0, moduleCount - 7); // Bottom-left

    // 2. Alignment pattern
    void drawAlignment(int cx, int cy) {
      canvas.drawRect(Rect.fromLTWH((cx - 2) * cellSize, (cy - 2) * cellSize, 5 * cellSize, 5 * cellSize), darkPaint);
      canvas.drawRect(Rect.fromLTWH((cx - 1) * cellSize, (cy - 1) * cellSize, 3 * cellSize, 3 * cellSize), Paint()..color = lightColor);
      canvas.drawRect(Rect.fromLTWH(cx * cellSize, cy * cellSize, cellSize, cellSize), darkPaint);
    }
    drawAlignment(moduleCount - 7, moduleCount - 7);

    // 3. Timing patterns
    for (int i = 8; i < moduleCount - 8; i++) {
      if (i % 2 == 0) {
        canvas.drawRect(Rect.fromLTWH(i * cellSize, 6 * cellSize, cellSize, cellSize), darkPaint);
        canvas.drawRect(Rect.fromLTWH(6 * cellSize, i * cellSize, cellSize, cellSize), darkPaint);
      }
    }

    // 4. Fill data modules
    for (int r = 0; r < moduleCount; r++) {
      for (int c = 0; c < moduleCount; c++) {
        // Skip finder patterns
        if (r < 8 && c < 8) continue;
        if (r < 8 && c >= moduleCount - 8) continue;
        if (r >= moduleCount - 8 && c < 8) continue;
        // Skip alignment
        if (r >= moduleCount - 9 && c >= moduleCount - 9) continue;
        // Skip timing
        if (r == 6 || c == 6) continue;

        // Deterministic dot based on character codes & position
        final charIndex = (r * moduleCount + c) % max(1, data.length).toInt();
        final charVal = data.codeUnitAt(charIndex);
        final isFilled = (charVal + r * 7 + c * 13 + random.nextInt(100)) % 2 == 0;

        if (isFilled) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(c * cellSize + 0.5, r * cellSize + 0.5, cellSize - 1, cellSize - 1),
              const Radius.circular(1.5),
            ),
            darkPaint,
          );
        }
      }
    }

    // 5. Center badge if provided
    if (centerLabel != null && centerLabel!.isNotEmpty) {
      final badgeSize = 6 * cellSize;
      final badgeRect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: badgeSize,
        height: badgeSize,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(6)), Paint()..color = lightColor);
      canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(6)), Paint()..color = darkColor..style = PaintingStyle.stroke..strokeWidth = 1.5);
      
      final textSpan = TextSpan(
        text: centerLabel,
        style: TextStyle(
          color: darkColor,
          fontSize: badgeSize * 0.35,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: badgeSize);
      textPainter.paint(
        canvas,
        Offset(
          badgeRect.center.dx - textPainter.width / 2,
          badgeRect.center.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SimpleQrPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.darkColor != darkColor;
  }
}
