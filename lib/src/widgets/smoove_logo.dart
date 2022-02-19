import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SmooveLogo extends StatelessWidget {
  const SmooveLogo({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Smoove",
          style: GoogleFonts.baloo2(
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 50,
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: Offset(0, 0),
                  blurRadius: 20.0,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ),
        Text(
          "!",
          style: GoogleFonts.baloo2(
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 50,
              color: Colors.yellow,
              shadows: [
                Shadow(
                  offset: Offset(0, 0),
                  blurRadius: 20.0,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
