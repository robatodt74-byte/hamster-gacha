import 'dart:math';
import 'package:flutter/material.dart';

const _ink = Color(0xFF251731);
const _cream = Color(0xFFFFF4DA);
const _coral = Color(0xFFFF685B);
const _mint = Color(0xFFBCE9D6);
const _gold = Color(0xFFFFD35C);

class HamsterPainter extends CustomPainter {
  const HamsterPainter({
    this.tone = const Color(0xFFE5B777),
    this.happy = false,
  });
  final Color tone;
  final bool happy;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final scale = min(size.width, size.height) / 100;
    canvas.translate(
      (size.width - 100 * scale) / 2,
      (size.height - 100 * scale) / 2,
    );
    canvas.scale(scale);
    final p = Paint();
    canvas.drawOval(
      const Rect.fromLTWH(14, 86, 72, 10),
      p..color = _ink.withValues(alpha: .15),
    );
    // Ears, body and full cheek pouches form one original character silhouette.
    for (final x in [27.0, 73.0]) {
      canvas.drawCircle(Offset(x, 23), 16, p..color = tone);
      canvas.drawCircle(Offset(x, 23), 10, p..color = const Color(0xFFECA99F));
      canvas.drawCircle(
        Offset(x - 2, 20),
        3,
        p..color = _cream.withValues(alpha: .5),
      );
    }
    final body = const Rect.fromLTWH(12, 20, 76, 72);
    p.shader = RadialGradient(
      center: const Alignment(-.3, -.6),
      colors: [_cream, tone],
      stops: const [0, 1],
    ).createShader(body);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(34)),
      p,
    );
    p.shader = null;
    canvas.drawOval(const Rect.fromLTWH(22, 49, 56, 39), p..color = _cream);
    for (final x in [23.0, 77.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 62), width: 30, height: 28),
        p..color = tone,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 64), width: 15, height: 7),
        p..color = const Color(0xFFF39F98).withValues(alpha: .8),
      );
    }
    for (final x in [34.0, 66.0]) {
      if (happy) {
        p
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCenter(center: Offset(x, 48), width: 10, height: 9),
          pi,
          pi,
          false,
          p,
        );
        p.style = PaintingStyle.fill;
      } else {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, 48), width: 7, height: 9),
          p..color = _ink,
        );
        canvas.drawCircle(Offset(x - 1, 46), 1.5, p..color = Colors.white);
      }
    }
    canvas.drawOval(
      const Rect.fromLTWH(46, 56, 8, 5),
      p..color = const Color(0xFF99585D),
    );
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = _ink;
    canvas.drawArc(const Rect.fromLTWH(41, 57, 9, 10), 0, pi * .8, false, p);
    canvas.drawArc(
      const Rect.fromLTWH(50, 57, 9, 10),
      pi * .2,
      pi * .8,
      false,
      p,
    );
    p.style = PaintingStyle.fill;
    canvas.drawOval(
      const Rect.fromLTWH(28, 82, 18, 10),
      p..color = const Color(0xFFECA99F),
    );
    canvas.drawOval(const Rect.fromLTWH(54, 82, 18, 10), p);
    canvas.save();
    canvas.translate(50, 76);
    canvas.rotate(-.2);
    canvas.drawOval(const Rect.fromLTWH(-6, -10, 12, 21), p..color = _ink);
    p
      ..color = _cream
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(-1, -7), const Offset(-1, 8), p);
    p.style = PaintingStyle.fill;
    canvas.restore();
    canvas.drawOval(const Rect.fromLTWH(34, 68, 12, 8), p..color = _cream);
    canvas.drawOval(const Rect.fromLTWH(55, 69, 12, 8), p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(HamsterPainter old) =>
      tone != old.tone || happy != old.happy;
}

class TheatrePainter extends CustomPainter {
  const TheatrePainter({
    required this.time,
    required this.celebrating,
    required this.reduced,
  });
  final double time;
  final bool celebrating, reduced;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    final rect = Offset.zero & size;
    p.shader = const RadialGradient(
      center: Alignment(.1, -.2),
      radius: 1.2,
      colors: [Color(0xFF4C2B4C), _ink],
    ).createShader(rect);
    canvas.drawRect(rect, p);
    p.shader = null;
    final rng = Random(42);
    for (var i = 0; i < 44; i++) {
      final x = rng.nextDouble() * size.width;
      final y =
          (rng.nextDouble() * size.height + time * size.height * .15) %
          size.height;
      final r = 1 + rng.nextDouble() * 2;
      canvas.drawCircle(
        Offset(x, y),
        r,
        p..color = _cream.withValues(alpha: .06 + rng.nextDouble() * .1),
      );
    }
    for (var i = 0; i < 8; i++) {
      final x = size.width * (i / 7), y = size.height * (.16 + (i % 3) * .27);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(i * .8 + time * 2);
      canvas.drawOval(
        const Rect.fromLTWH(-5, -10, 10, 20),
        p..color = _gold.withValues(alpha: .08),
      );
      canvas.restore();
    }
    if (celebrating && !reduced) {
      for (var i = 0; i < 45; i++) {
        final x = rng.nextDouble() * size.width;
        final y = ((time * 4 + i / 45) % 1) * (size.height + 40) - 20;
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(time * 20 + i);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: 4 + i % 4, height: 9),
          p
            ..color = [
              _coral,
              _gold,
              _mint,
              _cream,
            ][i % 4].withValues(alpha: .55),
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(TheatrePainter old) =>
      old.time != time ||
      old.celebrating != celebrating ||
      old.reduced != reduced;
}

class MachinePainter extends CustomPainter {
  const MachinePainter({
    required this.time,
    required this.energy,
    required this.reduced,
  });
  final double time, energy;
  final bool reduced;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, p = Paint();
    p.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF9ECABD), _mint, Color(0xFFE0F3D7)],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, p);
    p.shader = null;
    // Quiet grid floor and spotlight create depth without a 3D dependency.
    final floor = h * .79;
    canvas.drawRect(
      Rect.fromLTWH(0, floor, w, h - floor),
      p..color = const Color(0xFF83B9AB),
    );
    p
      ..color = const Color(0xFF679E92).withValues(alpha: .5)
      ..strokeWidth = 1;
    for (var i = -4; i <= 8; i++) {
      canvas.drawLine(Offset(w / 2, floor - 35), Offset(i * w / 6, h), p);
    }
    for (var i = 1; i <= 3; i++) {
      canvas.drawLine(
        Offset(0, floor + i * (h - floor) / 3),
        Offset(w, floor + i * (h - floor) / 3),
        p,
      );
    }
    final beam = Path()
      ..moveTo(w * .42, 0)
      ..lineTo(w * .14, floor)
      ..lineTo(w * .86, floor)
      ..lineTo(w * .58, 0)
      ..close();
    canvas.drawPath(beam, p..color = _cream.withValues(alpha: .16));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h * .88),
        width: w * .56,
        height: h * .09,
      ),
      p..color = _ink.withValues(alpha: .14),
    );
    final glass = Rect.fromLTWH(w * .22, h * .16, w * .56, h * .65);
    canvas.drawRRect(
      RRect.fromRectAndRadius(glass, Radius.circular(w * .25)),
      p..color = _cream.withValues(alpha: .24),
    );
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _cream.withValues(alpha: .85);
    canvas.drawRRect(
      RRect.fromRectAndRadius(glass, Radius.circular(w * .25)),
      p,
    );
    p
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: .36);
    canvas.drawLine(Offset(w * .29, h * .32), Offset(w * .29, h * .45), p);
    p.style = PaintingStyle.fill;
    final pedestal = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .25, h * .78, w * .5, h * .075),
      const Radius.circular(9),
    );
    canvas.drawRRect(pedestal, p..color = _ink);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .29, h * .795, w * .42, 3),
        const Radius.circular(2),
      ),
      p..color = _gold,
    );
    for (var i = 0; i < 8; i++) {
      final angle = i * pi / 4 + (reduced ? 0 : time * pi * 2);
      final x = w / 2 + cos(angle) * w * .38;
      final y = h * .48 + sin(angle) * h * .24;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle * .25);
      final capsule = Rect.fromCenter(
        center: Offset.zero,
        width: 21,
        height: 24,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(capsule, const Radius.circular(10)),
        p..color = [_gold, _coral, _cream, const Color(0xFF9B91BA)][i % 4],
      );
      canvas.drawLine(
        const Offset(-10, 0),
        const Offset(10, 0),
        p
          ..color = _ink.withValues(alpha: .22)
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(
        const Offset(-4, -5),
        3,
        p..color = Colors.white.withValues(alpha: .65),
      );
      canvas.restore();
    }
    if (energy > 0) {
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = _coral;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(w / 2, h * .5),
          width: w * .64,
          height: h * .72,
        ),
        -pi / 2,
        pi * 2 * energy,
        false,
        p,
      );
      p.style = PaintingStyle.fill;
    }
    // Markers along the stage wall are independent from the main controls.
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(w * .15 + i * w * .175, h * .955),
        3,
        p..color = energy > i / 5 ? _coral : _cream,
      );
    }
  }

  @override
  bool shouldRepaint(MachinePainter old) =>
      old.time != time || old.energy != energy || old.reduced != reduced;
}

class RevealPainter extends CustomPainter {
  const RevealPainter({
    required this.progress,
    required this.color,
    required this.rare,
  });
  final double progress;
  final Color color;
  final bool rare;
  @override
  void paint(Canvas canvas, Size size) {
    final fade = (1 - progress).clamp(0.0, 1.0);
    final center = Offset(size.width / 2, size.height * .48);
    final p = Paint()..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final r = (progress - i * .08) * size.longestSide;
      if (r > 0) {
        canvas.drawCircle(
          center,
          r,
          p
            ..color = color.withValues(alpha: fade * .65)
            ..strokeWidth = 4 + 8 * fade,
        );
      }
    }
    for (var i = 0; i < 28; i++) {
      final a = i * pi / 14;
      final start = size.shortestSide * .36 + progress * size.longestSide;
      canvas.drawLine(
        center + Offset(cos(a), sin(a)) * start,
        center + Offset(cos(a), sin(a)) * (start + 75),
        p
          ..color = _gold.withValues(alpha: fade)
          ..strokeWidth = 3,
      );
    }
    if (progress < .8) {
      final opacity = min(1.0, progress * 8) * min(1.0, (.8 - progress) * 6);
      final text = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        text: TextSpan(
          text: rare ? '伝説のもふ神、降臨。' : 'もふもふ、お迎え！',
          style: TextStyle(
            fontSize: min(42, size.width / 13),
            fontWeight: FontWeight.w900,
            color: _cream.withValues(alpha: opacity),
            shadows: [
              Shadow(
                color: _coral.withValues(alpha: opacity),
                offset: const Offset(2, 3),
              ),
            ],
          ),
        ),
      )..layout(maxWidth: size.width - 24);
      canvas.save();
      canvas.translate((size.width - text.width) / 2, size.height * .12);
      canvas.rotate(-.035);
      text.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(RevealPainter old) =>
      old.progress != progress || old.color != color || old.rare != rare;
}
