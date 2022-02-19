import 'dart:math';

import 'package:flutter/material.dart';

class SlicePainter extends CustomPainter {
  SlicePainter({
    required this.radius,
    required this.sweep,
    required this.angle,
    required this.width,
    required this.color,
    this.strokeWidth = 4,
  });
  final double radius;
  final double angle;
  final double sweep;
  final double width;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    var fillBrush = Paint()..color = Colors.grey.shade200;

    //canvas.drawCircle(c, cx, fillBrush);

    var outlineBrush = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      //..strokeMiterLimit = 50
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    /*
    canvas.drawCircle(c, cx - 20, outlineBrush);

    canvas.drawArc(Rect.fromCenter(center: c, width: cx, height: cy), 0, 2,
        false, outlineBrush);*/

    //Path path = Path();
    /*
    Paint paint = Paint();
    path.moveTo(150, 100);
    path.lineTo(200, 100);
    //path.lineTo(100, 100);
    //path.lineTo(0, 100);
    path.addArc(Rect.fromLTWH(0, 0, 200, 200), 0, pi / 2);
    path.lineTo(100, 150);
    path.lineTo(150, 100);
    //path.moveTo(150, 100);

    path.close();

    paint.color = Colors.blue;
    */

    //Paint paint = Paint()
    final path = tilePath(
        size: size, radius: radius, width: width, angle: angle, sweep: sweep);

    canvas.drawPath(path, outlineBrush);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class SliceClipper extends CustomClipper<Path> {
  SliceClipper({
    required this.radius,
    required this.sweep,
    required this.angle,
    required this.width,
  });
  final double radius;
  final double angle;
  final double sweep;
  final double width;
  @override
  Path getClip(Size size) {
    //var cx = size.width / 2;
    //var cy = size.height / 2;
    //var c = Offset(cx, cy);
    final path = tilePath(
        size: size, radius: radius, width: width, angle: angle, sweep: sweep);
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    // TODO: implement shouldReclip
    return true;
  }
}

Path tilePath({
  required Size size,
  required double radius,
  required double width,
  required double angle,
  required double sweep,
}) {
  final cx = size.width / 2;
  final cy = size.height / 2;
  //final c = Offset(cx, cy);
  final ax = cos(angle);
  final ay = sin(angle);
  final sx = cos(angle + sweep);
  final sy = sin(angle + sweep);
  final tx = cos(angle + sweep * 2);
  final ty = sin(angle + sweep * 2);
  //print(radius);

  if (radius < width) {
    return Path()
      ..moveTo(cx + width * ax, cy + width * ay)
      ..lineTo(cx + (radius + width) * ax, cy + (radius + width) * ay)
      ..arcToPoint(
          Offset(cx + (radius + width) * sx, cy + (radius + width) * sy),
          radius: Radius.circular(radius + width))
      ..lineTo(cx + width * sx, cy + width * sy)
      ..arcToPoint(Offset(cx + width * ax, cy + width * ay),
          radius: Radius.circular(width - radius / 2), largeArc: true)
      ..close();
  }

  return Path()
    ..moveTo(cx + radius * ax, cy + radius * ay)
    ..lineTo(cx + (radius + width) * ax, cy + (radius + width) * ay)
    ..arcToPoint(Offset(cx + (radius + width) * sx, cy + (radius + width) * sy),
        radius: Radius.circular(radius + width))
    ..lineTo(cx + radius * sx, cy + radius * sy)
    ..arcToPoint(Offset(cx + radius * ax, cy + radius * ay),
        radius: Radius.circular(radius), clockwise: false)
    ..close();

  /*
  return Path()
    ..moveTo(cx + radius * ax, cy + radius * ay)
    ..lineTo(cx + (radius + width) * ax, cy + (radius + width) * ay)
    ..arcToPoint(Offset(cx - (radius + width) * ay, cy + (radius + width) * ax),
        radius: Radius.circular(radius + width))
    ..lineTo(cx - radius * ay, cy + radius * ax)
    ..arcToPoint(Offset(cx + radius * ax, cy + radius * ay),
        radius: Radius.circular(radius), clockwise: false)
    ..close();
    */
}

Offset origin({
  required Size size,
  required double radius,
  required double width,
  required double angle,
  required double sweep,
}) {
  //final c = Offset(cx, cy);
  final sx = cos(angle + sweep / 2);
  final sy = sin(angle + sweep / 2);
  final r = radius + width / 2;

  final dx = (size.width / 2) + r * sx;
  final dy = (size.height / 2) + r * sy;

  return Offset(dx, dy);
}

class TileSlice extends StatelessWidget {
  const TileSlice({
    required this.r,
    required this.a,
    required this.band,
    required this.posBand,
    required this.targetBand,
    required this.bandOffset,
    required this.slot,
    required this.slots,
    required this.selected,
    required this.img,
    required this.size,
    required this.bandSize,
    required this.progress,
    Key? key,
  }) : super(key: key);

  final double r;
  final double a;
  final int band;
  final int posBand;
  final int targetBand;
  final int slot;
  final int slots;
  final double bandSize;
  final double bandOffset;
  final double progress;
  final bool selected;
  final DecorationImage img;
  final Size size;

  static const _expandFactor = 0;

  double cposx(int band, double bandSize, double offset, double angle,
      int posBand, int targetBand, double progress) {
    final radius = band * bandSize;
    final er = offset; //radius + offset; // + width / 2;
    final ax = cos(angle);
    //final ay = sin(angle + pi / 4);
    //print(er);
    if (posBand == 0 || targetBand == 0) {
      //if (band * bandSize + bandOffset < bandSize) {
      //(offset <= 0) {
      if (posBand == 0 && targetBand == 0) {
        return (1 + _expandFactor) * er * ax;
      }
      final cx = targetBand == 0
          ? _expandFactor * (progress.abs() / bandSize)
          : _expandFactor * ((bandSize - progress.abs()) / bandSize);
      //print("$progress -> $cx");
      return targetBand == 0
          ? er * ax + _expandFactor * (progress.abs() / bandSize) * er * ax
          : er * ax +
              _expandFactor *
                  ((bandSize - progress.abs()) / bandSize) *
                  er *
                  ax; // offset = (posband - band) * width + _o => _o  = offset + band*bandSize
      //return (/*radius +*/ offset * 1.5) * ax;
    }
    return er * ax;
    //return sqrt(er * er / 2) * ax * 2;
    //return sqrt(rx * rx) / 2;
  }

  double cposy(int band, double bandSize, double offset, double angle,
      int posBand, int targetBand, double progress) {
    final radius = band * bandSize;
    final er = offset; //radius + offset; // + width / 2;
    //final ax = cos(angle + pi / 4);
    final ay = sin(angle);
    if (posBand == 0 || targetBand == 0) {
      //band * bandSize + bandOffset < bandSize) {
      //(offset <= 0) {
      //print("a");
      if (posBand == 0 && targetBand == 0) {
        return (1 + _expandFactor) * er * ay;
      }
      return targetBand == 0
          ? er * ay + _expandFactor * (progress.abs() / bandSize) * er * ay
          : er * ay +
              _expandFactor *
                  ((bandSize - progress.abs()) / bandSize) *
                  er *
                  ay; // offset = (posband - band) * width + _o => _o  = offset + band*bandSize
      //return er * ay + 0.5 * er * ay * (offset + band * bandSize);
      //return (/*radius +*/ offset * 1.5) * ay;
    }
    // print("b");
    return er * ay;
    //return sqrt(er * er / 2) * ay * 2;
    //return sqrt(rx * rx) / 2;
  }

  double imgSize(double bs, double os, double v) {
    //prit
    return v;
    //os >= 0 ? v : v - (v * os / bs).abs();
  }

  @override
  Widget build(BuildContext context) {
    final sweep = pi * 2 / slots;
    final startangle = (slot * sweep) - sweep / 2;

    /*final imgloc = origin(
        size: const Size(300, 300),
        radius: bandSize * band,
        width: bandSize,
        angle: startangle,
        sweep: sweep);*/
    final ioy = cposy(band, bandSize, bandOffset, startangle + sweep / 2,
        posBand, targetBand, progress);
    final iox = cposx(band, bandSize, bandOffset, startangle + sweep / 2,
        posBand, targetBand, progress);
    //final double imgAngle = posBand == 0 ? 0 : a;
    /*final imgAngle = (band * bandSize + bandOffset < bandSize) // bandOffset < 0
        ? (a <= pi / 2
            ? a * (bandSize + bandOffset) / bandSize
            : a + (2 * pi - a) * bandOffset / bandSize)
        : a;*/

    // print("ImgAngle: $imgAngle : ${bandOffset < 0}");

    double imgAngle = a;
    if (posBand == 0 || targetBand == 0) {
      if (posBand == 0 && targetBand == 0) {
        imgAngle = 0;
      } else {
        if (a.abs() < pi / 2) {
          //print("<pi");
          imgAngle = targetBand == 0
              ? a *
                  ((bandSize - progress.abs()) /
                      bandSize) // * (progress.abs() / bandSize)
              : a *
                  (progress.abs() /
                      bandSize); // * ((bandSize - progress.abs()) / bandSize);*/
        } else {
          //print(">pi $targetBand");
          final diff = (2 * pi - a.abs());
          if (a >= 0) {
            imgAngle = targetBand == 0
                ? a + diff * (progress.abs() / bandSize)
                : a + diff * ((bandSize - progress.abs()) / bandSize);
          } else {
            imgAngle = targetBand == 0
                ? a - diff * (progress.abs() / bandSize)
                : a - diff * ((bandSize - progress.abs()) / bandSize);
          }
        }
      }
      //print("$a -> $imgAngle $progress");
    }

    return ClipPath(
      clipper: SliceClipper(
        radius: band * bandSize + bandOffset,
        angle: startangle + a,
        width: bandSize,
        sweep: sweep,
      ),
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            Positioned.fill(
              child: Transform.rotate(
                angle: imgAngle,
                child: Stack(
                  children: [
                    Positioned.fill(
                      top: imgSize(bandSize, bandOffset, ioy),
                      left: imgSize(bandSize, bandOffset, iox),
                      bottom: imgSize(bandSize, bandOffset, -ioy),
                      right: imgSize(bandSize, bandOffset, -iox),
                      //top: bandOffset >= 0 ? ioy : ioy - ioy.abs(),
                      //left: bandOffset >= 0 ? iox : iox - iox.abs(),
                      //bottom: bandOffset >= 0 ? -ioy : -ioy - ioy.abs(),
                      //right: bandOffset >= 0 ? -iox : -iox - iox.abs(),
                      child: Container(
                        decoration: BoxDecoration(
                          image: img,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            /*Transform.rotate(
            angle: a,
            child: Image.asset(
              "assets/images/coffee.jpg",
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),*/
            CustomPaint(
                painter: SlicePainter(
                  radius: bandSize * band + bandOffset,
                  angle: startangle + a,
                  sweep: sweep,
                  width: bandSize,
                  color: Colors.white, //selected ? Colors.red : Colors.white,
                  strokeWidth: 1, //selected ? 10 : 1,
                ),
                child: Container()),
            /*CustomPaint(
                                painter: ClockPainter(radius: r + 50, angle: a),
                                child: Container()),*/

            /*
          Positioned.fill(
            top: cposy(band * bandSize + bandOffset, startangle + sweep / 2),
            left: cposx(band * bandSize + bandOffset, startangle + sweep / 2),
            bottom:
                -cposy(band * bandSize + bandOffset, startangle + sweep / 2),
            right: -cposx(band * bandSize + bandOffset, startangle + sweep / 2),
            child: Transform.rotate(
              angle: a,
              child: Image.asset(
                "assets/images/coffee.jpg",
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          */
          ],
        ),
      ),
    );
  }
}
