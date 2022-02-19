import 'package:flutter/material.dart';
import 'package:smoove/src/pages/puzzle.dart';
import 'package:smoove/src/widgets/app_drawer.dart';
import 'package:smoove/src/widgets/circle_panel.dart';
import 'package:smoove/src/widgets/smoove_logo.dart';

class ImageSelectorPage extends StatefulWidget {
  ImageSelectorPage({Key? key}) : super(key: key);

  @override
  State<ImageSelectorPage> createState() => _ImageSelectorPageState();
}

class _ImageSelectorPageState extends State<ImageSelectorPage> {
  PageController _pageController = PageController(
    initialPage: 0,
    keepPage: true,
  );
  int _page = 0;

  final List<String> images = [
    "puzzle1.jpeg",
    "puzzle2.jpeg",
    "puzzle3.jpeg",
    "puzzle4.jpeg",
    "puzzle5.jpeg",
  ];

  @override
  Widget build(BuildContext context) {
    const img = DecorationImage(
        image: AssetImage("assets/images/puzzle5.jpeg"), fit: BoxFit.cover);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const SmooveLogo(),
        centerTitle: true,
        /*titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 30,
        ),*/
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: Drawer(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: AppDrawer(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.restorablePushReplacementNamed(
                    context, PuzzlePage.routeName,
                    arguments: images[_page]);
              },
              icon: const Icon(Icons.restart_alt),
              label: const Text("Play"),
            ),
          ],
        ),
      ),
      body: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue,
                Colors.black,
              ],
            ),
          ),
          child: LayoutBuilder(builder: (context, constraints) {
            final horizOrient = constraints.maxWidth > constraints.maxHeight;
            final sx = horizOrient
                ? constraints.maxHeight * 0.9
                : constraints.maxWidth;
            final size = Size(sx, sx);
            if (horizOrient) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  _selector(size),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _headingText(),
                      _playButton(context),
                    ],
                  ),
                  const Spacer(),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _headingText(),
                _selector(size),
                _playButton(context),
              ],
            );
          })),
    );
  }

  Center _headingText() {
    return const Center(
      child: Text(
        "Choose your image!",
        textAlign: TextAlign.center,
        style: TextStyle(shadows: [
          Shadow(
            offset: Offset(0, 0),
            blurRadius: 20.0,
            color: Colors.black,
          ),
        ], color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
      ),
    );
  }

  ElevatedButton _playButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        //Navigator.of(context)
        //    .pushReplacementNamed(PuzzlePage.routeName);
        Navigator.restorablePushReplacementNamed(context, PuzzlePage.routeName,
            arguments: images[_page]);
      },
      child: const Text(
        "PLAY!",
        textAlign: TextAlign.center,
        style: TextStyle(
            color: Colors.black, fontSize: 50, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        primary: Colors.yellow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Stack _selector(Size size) {
    return Stack(
      children: [
        Container(
          width: size.width,
          height: size.width,
          padding: const EdgeInsets.all(15),
          child: PageView(
            onPageChanged: (pg) {
              setState(() {
                _page = pg;
              });
            },
            controller: _pageController,
            children: List<Widget>.generate(
              images.length,
              (index) => CirclePanel(
                size: size,
                img: DecorationImage(
                    image: AssetImage("assets/images/${images[index]}"),
                    fit: BoxFit.cover),
              ),
            ).toList(),
          ),
        ),
        Container(
          width: size.width,
          height: size.width,
          child: const Padding(
            padding: EdgeInsets.all(30.0),
            child: Icon(
              Icons.swipe,
              size: 80,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
