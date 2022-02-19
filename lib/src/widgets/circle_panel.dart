import 'package:flutter/material.dart';

class CirclePanel extends StatelessWidget {
  const CirclePanel({
    required this.img,
    required this.size,
    this.children = const [],
    this.opacity = 1,
    Key? key,
  }) : super(key: key);

  final DecorationImage img;
  final Size size;
  final List<Widget> children;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.all(8.0),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black, blurRadius: 5, spreadRadius: 5),
          ]
          //image: img,
          ),
      //width: size.width,
      //height: size.height,
      child: Stack(children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: AnimatedOpacity(
              opacity: opacity > 0.1 ? opacity : 0.1,
              duration: const Duration(milliseconds: 250),
              child: Container(
                decoration: BoxDecoration(
                  //color: Colors.grey[200],
                  image: img,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        ...children,
      ]),
    );
  }
}
