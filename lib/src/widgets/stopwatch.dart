import 'package:flutter/material.dart';

class StopWatch extends StatelessWidget {
  const StopWatch({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      "0:00:00.0",
      textAlign: TextAlign.center,
      style: const TextStyle(
          color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
    );
  }
}
