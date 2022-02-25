import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smoove/src/models/slice.dart';
import 'package:smoove/src/widgets/app_drawer.dart';
import 'package:smoove/src/widgets/circle_panel.dart';
import 'package:smoove/src/widgets/menubutton.dart';
import 'package:smoove/src/widgets/smoove_logo.dart';
import 'package:smoove/src/widgets/tile_slice.dart';

class PuzzlePage extends StatefulWidget {
  const PuzzlePage({
    required this.puzzleImg,
    Key? key,
  }) : super(key: key);

  static const routeName = '/puzzle';

  final String puzzleImg;

  @override
  State<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends State<PuzzlePage> with TickerProviderStateMixin {
  double r = 0;
  List<double> a = [0, 0, 0];
  int slots = 4;
  List<Slice> slices = [];
  int bands = 0;
  AnimationController? controller;
  AnimationController? scorecontroller;
  double width = 80;
  double sliceOpacity = 0.1;
  bool playing = false;
  bool paused = false;
  bool completed = false;
  int level = 0;
  int score = 0;
  int moves = 0;
  int toScramble = 0;
  double turns = 0;
  Size? circleSize;
  String timeDisplay = "0:00:00.0";
  Timer? t;
  DateTime start = DateTime.now();
  DateTime pausedAt = DateTime.now();
  late SharedPreferences prefs;

  Future<void> getSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLevel = prefs.getInt("level") ?? 0;
    if (savedLevel > 0) {
      setState(() {
        level = savedLevel;
      });
    }
  }

  void saveProgress() {
    prefs.setInt("level", level);
  }

  @override
  void initState() {
    getSavedState();
    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    controller!.addListener(() {
      //print("Animation: ${controller!.value}");

      setState(() {
        for (var s in slices) {
          s.move(controller!.value);
        }
      });
      if (controller!.status == AnimationStatus.completed) {
        // check if there is another in the sequence
        if (toScramble > 0) {
          if ((slices.length <= 12 && outOfPosPerc() >= 80) ||
              outOfPosPerc() > 90) {
            //} toScramble == 1) {
            if (moveFromCenter()) {
              print("finished moving");
              toScramble = 0;
              start = DateTime.now();
              pausedAt = DateTime.now();
              playing = true;
            }
          } else {
            moveRandom();
          }
          setState(() {
            //--toScramble;
          });
        } else {
          if (playing && qtyOutOfPos() == 0) {
            setState(() {
              completed = true;
              playing = false;
              paused = false;
              addScore(5 * level);
              pausedAt = DateTime.now();
            });
          }
        }
      }
    });
    scorecontroller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    scorecontroller!.addListener(() {
      // scorecontroller!.value;
      if (scorecontroller!.status == AnimationStatus.completed) {
        scorecontroller!.reverse();
      }
    });
    t = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final now = DateTime.now();
      setState(() {
        // duration is time now - time started
        // if paused /// time is between time paused and time started
        final now = DateTime.now();
        final d = (paused || !playing)
            ? pausedAt.difference(start)
            : now.difference(start);

        String twoDigits(int n) => n.toString().padLeft(2, "0");
        String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
        String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
        final tm = "$twoDigitMinutes:$twoDigitSeconds";
        final ms = (d.inMilliseconds / 100).round();
        final m = ms % 10;

        //timeDisplay = "$ms.$m"; //DateFormat("h:mm:ss").format(DateTime.now());
        timeDisplay = "$tm.$m";
      });

      // every 5 minutes, save watchdog (5x12*5) = 60 5 sec intervals
    });
    super.initState();
  }

  @override
  void dispose() {
    t?.cancel();
    controller?.dispose();
    super.dispose();
  }

  void playNow(Size size) {
    setState(() {
      levelUp(size);
      start = DateTime.now();
      pausedAt = DateTime.now();
      //playing = true;
      paused = false;
      moves = 0;
    });
  }

  void pausePlay() {
    setState(() {
      paused = true;
      pausedAt = DateTime.now();
    });
  }

  void resumePlay() {
    setState(() {
      // calculate new start time
      final now = DateTime.now();
      final d = pausedAt.difference(start);
      start = now.subtract(d);
      paused = false;
    });
  }

  Future<void> setSize(Size size) async {
    if (circleSize == null) {
      await Future.delayed(const Duration(milliseconds: 10));
      setState(() {
        circleSize = size;
      });
    }
  }

  int qtyOutOfPos() {
    final outOfPos =
        slices.where((s) => s.band != s.posband || s.slot != s.posslot).length;
    return outOfPos;
  }

  int qtyInPos() {
    final inPos =
        slices.where((s) => s.band == s.posband || s.slot == s.posslot).length;
    return inPos;
  }

  int outOfPosPerc() {
    final outOfPos =
        slices.where((s) => s.band != s.posband || s.slot != s.posslot).length;

    return slices.isEmpty ? 100 : ((outOfPos * 100) / slices.length).round();
  }

  Slice getEmpty() {
    final List<Slice> cl = [];
    cl.add(Slice.v(band: 0, slot: 0));
    for (var b = 1; b <= bands; b++) {
      for (var s = 0; s < slots; s++) {
        cl.add(Slice.v(band: b, slot: s));
      }
    }

    for (var sl in slices) {
      cl.removeWhere((c) => sl.posband == c.band && sl.posslot == c.slot);
    }

    return cl.first;
  }

  Slice? getCenter() {
    final c = slices.where((s) => s.posband == 0);
    return c.isEmpty ? null : c.first;
  }

  bool moveFromCenter() {
    // while there is something in the middle
    if (getCenter() != null) {
      print("something in the center");
      // find the empty sppot and move the slice on the inside .. outwards
      final empty = getEmpty();
      final tm = slices.where((s) =>
          s.posband == empty.band - 1 &&
          (s.posslot == (empty.band == 1 ? 0 : empty.slot)));
      if (tm.isEmpty) return true;
      final tmx = tm.first;
      print(
          "to move ${tmx.posband}:${tmx.posslot} to ${empty.band}:${empty.slot}");
      tmx.targetband = empty.band;
      tmx.targetslot = empty.slot;

      controller!.reset();
      controller!.forward(); // .animateTo(1.0);

      print("animate");
      return false;
    } else {
      print("nothing in the center");
      controller!.duration = const Duration(milliseconds: 250);
      return true;
    }
  }

  void moveRandom() {
    // find the empty spot
    final empty = getEmpty();

    // find the adjacents
    final List<XY> adjacents = [];
    if (empty.band != 0) {
      adjacents.add(empty.slot == 0
          ? XY(empty.band, slots - 1)
          : XY(empty.band, empty.slot - 1));
      adjacents.add(empty.slot == slots - 1
          ? XY(empty.band, 0)
          : XY(empty.band, empty.slot + 1));
      adjacents
          .add(empty.band == 1 ? XY(0, 0) : XY(empty.band - 1, empty.slot));
      if (empty.band < bands) adjacents.add(XY(empty.band + 1, empty.slot));
    } else {
      adjacents.addAll(List<XY>.generate(slots, (index) => XY(1, index)));
    }

    final r = Random().nextInt(adjacents.length);
    // find the slice to move

    final toMove = slices
        .where(
            (s) => s.posband == adjacents[r].x && s.posslot == adjacents[r].y)
        .first;

    // pick any of the adjacents at random to move to the empty spot.
    toMove.targetband = empty.band;
    toMove.targetslot = empty.slot;
    //print(
    //    "moving ${toMove.posband}:${toMove.posslot} => ${toMove.targetband}:${toMove.targetslot}");

    controller!.reset();
    controller!.forward(); // animateTo(1.0);
  }

  void scramble() {
    toScramble = bands * slots * 5;
    controller!.duration = const Duration(milliseconds: 1);
    moveRandom();
  }

  void addScore(int v) {
    setState(() {
      score += v;
      scorecontroller!.reset();
      scorecontroller!.forward();
    });
  }

  void levelUp(Size size) {
    if (bands == 0) {
      bands = 1;
      slots = 4;
      //width = 80;
    } else {
      slots += 2;
      if (slots > 12) {
        slots = 4;
        ++bands;
      }
    }
    // caclulate width
    // 1/2 the size / bands+1
    width = ((size.width - 40) / 2) / (bands + 1);
    print("Level Up $bands x $slots => ${size.width}");
    final List<Slice> sl = [];
    for (var b = 1; b <= bands; b++) {
      sl.addAll(List<Slice>.generate(
        slots,
        (index) => Slice(
          band: b,
          posband: b,
          targetband: b,
          slot: index,
          posslot: index,
          targetslot: index,
          width: width,
          slots: slots,
        ),
      ));
    }
    setState(() {
      completed = false;
      ++level;
      slices = sl;
      sliceOpacity = 1;
      turns = (turns == 0) ? 4 : 0;
      start = DateTime.now();
    });

    scramble();
    saveProgress();
  }

  void getSliceFromPosition(Offset pos, Size size, int slots) {
    print("getSlice");
    try {
      final x = pos.dx - size.width / 2;
      final y = pos.dy - size.height / 2;
      final r = sqrt(x * x + y * y);
      final halfstep = (2 * pi / slots) / 2;
      double a = x == 0 ? pi / 2 : atan(y / x);
      //final steps = (a.abs() / halfstep).floor();
      //print("r:$r x:$x y:$y");
      final band = (r / width).floor();

      Slice? sel;
      //print("band: $band");
      final List<XY> adjacents = [];
      //print("atan: ${atan(y / x)}");
      int slot = 0;
      if (band != 0) {
        // calculate quadrant, then the angle from 0 and then add the starting slot offset ... then divide by number of slots
        //print("Pre-Angle $a");
        if (x > 0) {
          if (y < 0) {
            a = 2 * pi + a;
          }
        } else {
          a = pi + a;
        }

        final sweep = pi * 2 / slots;
        //final startangle = (slot * sweep) - sweep / 2;

        //print("Angle $a");

        a += sweep / 2;
        slot = (a / sweep).floor();
        if (slot >= slots) slot = 0;

        //print("band: $band slot: $slot");

        // get slots at
        final sl = slices
            .where((s) => s.posband == band && s.posslot == slot)
            .toList();
        //print("Matching slots: ${sl.length}");
        //if (sl.length > 0) {
        //  print(
        //      "Slice: ${sl[0].band} ${sl[0].slot} ${sl[0].posband} ${sl[0].posslot} ${sl[0].selected}");
        //}

        for (var s in slices) {
          s.selected = s.posband == band && s.posslot == slot;
          //print(
          //    "SliceX: ${s.band} ${s.slot} ${s.posband} ${s.posslot} ${s.selected}");
        }
        final ss = slices.where((s) => s.selected).toList();
        //print("Selected slots: ${ss.length}");
        if (ss.length > 0) {
          sel = ss[0];
          //print(
          //    "Slice: ${ss[0].band} ${ss[0].slot} ${ss[0].posband} ${ss[0].posslot} ${ss[0].selected}");
          // get adjacent slots
          adjacents.add(slot == 0 ? XY(band, slots - 1) : XY(band, slot - 1));
          adjacents.add(slot == slots - 1 ? XY(band, 0) : XY(band, slot + 1));
          /*
        if (band == 1) {
          adjacents.addAll(List<XY>.generate(slots, (index) => XY(0, index)));
        } else {
          adjacents.add(XY(band - 1, slot));
        }
        */
          adjacents.add(band == 1 ? XY(0, 0) : XY(band - 1, slot));
          if (band < bands) adjacents.add(XY(band + 1, slot));
        } else {
          //print("Nothing selected");
        }
      } else {
        // all of band 1 is adjacent!
        for (var s in slices) {
          s.selected = s.posband == 0 && s.posslot == 0;
          //print(
          //    "SliceX: ${s.band} ${s.slot} ${s.posband} ${s.posslot} ${s.selected}");
        }
        final ss = slices.where((s) => s.selected).toList();
        if (ss.length > 0) {
          sel = ss[0];
        }
        adjacents.addAll(List<XY>.generate(slots, (index) => XY(1, index)));
      }

      /*
    for (var s in slices) {
      print(
          "SliceX: ${s.band} ${s.slot} ${s.posband} ${s.posslot} ${s.selected}");
    }*/

      for (var v in adjacents) {
        //print("Adj: ${v.x}:${v.y}");
        final e =
            slices.where((s) => s.posband == v.x && s.posslot == v.y).toList();
        if (e.isEmpty) {
          //print("Empty!! moving");
          // move the selcted to this adjacent
          if (sel != null) {
            sel.targetband = v.x;
            sel.targetslot = sel.targetband == 0 ? sel.posslot : v.y;
            if (sel.posband == 0) sel.posslot = v.y;
            //print("POS: ${sel.posband} x ${sel.posslot}");
            //print("TRG: ${sel.targetband} x ${sel.targetslot}");
            moves++;
          }
        }
      }
      if (sel != null) {
        if (sel.targetband == sel.band && sel.targetslot == sel.slot) {
          addScore(1);
        }
        controller!.reset();
        controller!.forward(); // .animateTo(1.0);
      }

      // find the "empty" slot
      setState(() {});
      print(
          "x: ${x.toStringAsFixed(1)} y:${y.toStringAsFixed(1)} r:${r.toStringAsFixed(1)} a:${x.toStringAsFixed(3)} band:$band slot:$slot size:${size.width} dx:${pos.dx.toStringAsFixed(1)} dt:${pos.dy.toStringAsFixed(1)}");
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = DecorationImage(
        image: AssetImage("assets/images/${widget.puzzleImg}"),
        fit: BoxFit.cover);
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
          /*
          if (playing) {
            if (paused) {
              resumePlay();
            } else if (!controller!.isAnimating) {
              getSliceFromPosition(details.localPosition, size, slots);
            }
          } else {
            playNow(size);
          }
          */
          children: [
            if (!playing)
              MenuButton(
                onPressed: () {
                  Navigator.pop(context);
                  playNow(circleSize ?? const Size(300, 300));
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: "Play next level",
              ),
            if (playing)
              paused
                  ? MenuButton(
                      onPressed: () {
                        Navigator.pop(context);
                        resumePlay();
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: "Resume game",
                    )
                  : MenuButton(
                      onPressed: () {
                        Navigator.pop(context);
                        pausePlay();
                      },
                      icon: const Icon(Icons.pause_rounded),
                      label: "Pause game",
                    ),
            MenuButton(
              onPressed: () {
                Navigator.restorablePushReplacementNamed(context, "/");
              },
              icon: const Icon(Icons.restart_alt),
              label: "Choose another Image",
            ),
            if (playing)
              MenuButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (level > 0) --level;
                  playNow(circleSize ?? const Size(300, 300));
                },
                icon: const Icon(Icons.restore),
                label: "Restart Level",
              ),
            if (playing)
              MenuButton(
                onPressed: () {
                  Navigator.pop(context);
                  playNow(circleSize ?? const Size(300, 300));
                },
                icon: const Icon(Icons.upgrade_rounded),
                label: "Skip Level",
              ),
          ],
        ),
      ),
      body: Container(
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
          final aspect =
              ((constraints.maxWidth / constraints.maxHeight) * 20).round();

          /*
          final sizeFactor = (aspect > 35)
              ? 0.9
              : (aspect > 12)
                  ? 0.7
                  : 1;
          */
          final sizeFactor = (aspect > 35)
              ? 0.9
              : (aspect > 24)
                  ? 0.7
                  : (aspect > 17)
                      ? 0.6
                      : (aspect > 12)
                          ? 0.7
                          : 1;

          final sx = horizOrient
              ? constraints.maxHeight * sizeFactor
              : constraints.maxWidth * sizeFactor;

          //print("$sx");
          if (horizOrient) {
            final size = Size(sx - 20, sx - 20);
            //print("Size: ${size.width}");
            setSize(size);
            return Padding(
              padding: const EdgeInsets.only(
                  top: 80, left: 20.0, right: 20, bottom: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _gamePanel(size, img),
                  Container(
                    width: constraints.maxWidth - sx - 80,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _scorePanel(horizOrient),
                        _timerPanel(horizOrient),
                        _optionsPanel(size),
                        _tagLine(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          final size = Size(sx - 20, sx - 20);
          //print("Size: ${size.width}");
          setSize(size);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _scorePanel(horizOrient),
              _timerPanel(horizOrient),
              _gamePanel(size, img),
              _optionsPanel(size),
              _tagLine(),
            ],
          );
        }),
      ),
    );
  }

  Widget _tagLine() {
    return const Text(
      "Built with Flutter!",
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: 20,
      ),
    );
  }

  Widget _gamePanel(Size size, DecorationImage img) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: GestureDetector(
          onTapDown: (details) {
            //print("tap");
            //print(details.globalPosition.direction);
            //print(details.globalPosition.dx);
            //print(details.globalPosition.dy);
            /*
            if (playing) {
              if (paused) {
                resumePlay();
              } else if (!controller!.isAnimating) {
                //print(details.globalPosition.)
                getSliceFromPosition(details.localPosition, size, slots);
              }
            } else {
              playNow(size);
            }
            */
          },
          onVerticalDragDown: (details) {
            if (playing) {
              if (paused) {
                resumePlay();
              } else if (!controller!.isAnimating) {
                //print(details.globalPosition.)
                getSliceFromPosition(details.localPosition, size, slots);
              }
            } else {
              playNow(size);
            }
          },
          onHorizontalDragDown: (details) {
            //print("horz");
            //print(details.globalPosition.direction);
            //print(details.globalPosition.dx);
            //print(details.globalPosition.dy);
          },
          onHorizontalDragUpdate: (details) {
            //print(details.delta.dx);
            //print(details.delta.dy);
            //print(details.localPosition.dx);
            //print(details.localPosition.dy);
          },
          child: AnimatedRotation(
            turns: turns,
            duration: const Duration(milliseconds: 1000),
            onEnd: () {
              if (toScramble > 0) {
                setState(() {
                  turns = (turns == 0) ? 4 : 0;
                });
              }
            },
            child: Container(
              width: size.width,
              height: size.width,
              //color: Colors.red,
              child: CirclePanel(
                size: size,
                img: img,
                opacity: playing ? 0 : 1, //1 - sliceOpacity,
                children: playing
                    ? [
                        ...slices
                            .map((s) => AnimatedOpacity(
                                  opacity: sliceOpacity,
                                  duration: const Duration(milliseconds: 250),
                                  child: TileSlice(
                                    r: 0, //r,
                                    a: s.angle,
                                    band: s.band,
                                    slot: s.slot,
                                    slots: slots,
                                    bandOffset: s.bandOffset, // 0, //r,
                                    selected: s.selected,
                                    img: img,
                                    size: size,
                                    bandSize: width,
                                    posBand: s.posband,
                                    targetBand: s.targetband,
                                    progress: s.progress,
                                  ),
                                ))
                            .toList(),
                        ...slices
                            .map((s) => AnimatedOpacity(
                                  opacity: 1 - sliceOpacity,
                                  duration: const Duration(milliseconds: 250),
                                  child: TileSlice(
                                    r: 0, //r,
                                    a: 0, // 2 * pi / 8, //a[0], //a[1], //a[1],
                                    band: s.band, //s.band,
                                    slot: s.slot,
                                    slots: slots,
                                    bandOffset: 0, //s.bandOffset, //r,
                                    selected: s.selected,
                                    img: img,
                                    size: size,
                                    bandSize: width,
                                    posBand: s.band, //s.posband,
                                    targetBand: s.band, //s.targetband,
                                    progress: 0, //s.progress,
                                  ),
                                ))
                            .toList(),
                        if (paused)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                "Paused",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 0),
                                        blurRadius: 20.0,
                                        color: Colors.black,
                                      ),
                                    ],
                                    color: Colors.white,
                                    fontSize: 50,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Tap to resume",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 0),
                                        blurRadius: 20.0,
                                        color: Colors.black,
                                      ),
                                    ],
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          )
                      ]
                    : [
                        !completed
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (toScramble == 0)
                                      const Text(
                                        "Tap to",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            shadows: [
                                              Shadow(
                                                offset: Offset(0, 0),
                                                blurRadius: 20.0,
                                                color: Colors.black,
                                              ),
                                            ],
                                            color: Colors.white,
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    if (toScramble == 0)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.play_circle,
                                            size: 60,
                                            color: Colors.white,
                                          ),
                                          Text(
                                            "Play!",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                shadows: [
                                                  Shadow(
                                                    offset: Offset(0, 0),
                                                    blurRadius: 20.0,
                                                    color: Colors.black,
                                                  ),
                                                ],
                                                color: Colors.white,
                                                fontSize: 70,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Well Done!",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.baloo2(
                                        textStyle: const TextStyle(
                                            shadows: [
                                              Shadow(
                                                offset: Offset(0, 0),
                                                blurRadius: 20.0,
                                                color: Colors.black,
                                              ),
                                            ],
                                            color: Colors.white,
                                            fontSize: 50,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const Text(
                                      "Tap to Play\nthe next level!",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          shadows: [
                                            Shadow(
                                              offset: Offset(0, 0),
                                              blurRadius: 20.0,
                                              color: Colors.black,
                                            ),
                                          ],
                                          color: Colors.white,
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                      ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Padding _optionsPanel(Size size) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Opacity(
        opacity: playing ? 1 : 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            /*TextButton(
                            onPressed: () {
                              moveRandom();
                            },
                            child: Text("Move Random")),*/
            GestureDetector(
              onTapDown: (details) {
                //moveFromCenter();
                //moveRandom();
                setState(() {
                  sliceOpacity = 0;
                });
              },
              onTapUp: (details) {
                setState(() {
                  sliceOpacity = 1;
                });
              },
              child: const Center(
                child: Icon(
                  Icons.remove_red_eye_outlined,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ),
            if (playing)
              InkWell(
                onTap: () {
                  if (paused) {
                    resumePlay();
                  } else {
                    pausePlay();
                  }
                },
                child: Center(
                  child: Icon(
                    paused ? Icons.play_circle : Icons.pause_circle,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
            /*
            InkWell(
              onTap: () {
                setState(() {
                  levelUp(size);
                  start = DateTime.now();
                  pausedAt = DateTime.now();
                  //playing = true;
                  paused = false;
                  moves = 0;
                });
              },
              child: const Center(
                child: Icon(
                  Icons.upgrade_rounded,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ),*/
          ],

          /*Center(
                      child: TextButton(
                        onPressed: () {
                          levelUp(size);
                        },
                        child: const Text(
                          "Level Up",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );*/
        ),
      ),
    );
  }

  Padding _timerPanel(bool horz) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: horz
          ? Wrap(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer,
                      size: 30,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      timeDisplay,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$moves",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.swipe,
                      size: 30,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer,
                      size: 30,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      timeDisplay,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$moves",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.swipe,
                      size: 30,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Padding _scorePanel(bool horz) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: horz
          ? Wrap(
              children: [
                ScoreLabel(label: "Level:", value: "$level", scale: 1),
                const SizedBox(width: 20),
                ScoreLabel(
                    label: "Score:",
                    value: "$score",
                    scale: 1.0 + (scorecontroller?.value ?? 0)),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ScoreLabel(label: "Level:", value: "$level", scale: 1),
                ScoreLabel(
                    label: "Score:",
                    value: "$score",
                    scale: 1.0 + (scorecontroller?.value ?? 0)),
              ],
            ),
    );
  }
}

class ScoreLabel extends StatelessWidget {
  const ScoreLabel({
    Key? key,
    required this.label,
    required this.value,
    required this.scale,
  }) : super(key: key);

  final String label;
  final String value;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(shadows: [
            Shadow(
              offset: Offset(0, 0),
              blurRadius: 20.0,
              color: Colors.black,
            ),
          ], color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 10),
        Transform.scale(
          scale: scale,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(shadows: [
              Shadow(
                offset: Offset(0, 0),
                blurRadius: 10.0,
                color: Colors.black,
              ),
            ], color: Colors.yellow, fontSize: 40, fontWeight: FontWeight.bold),
          ),
        ),
        /*Text(
          "+1",
          textAlign: TextAlign.center,
          style: const TextStyle(shadows: [
            Shadow(
              offset: Offset(0, 0),
              blurRadius: 20.0,
              color: Colors.black,
            ),
          ], color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),*/
      ],

      /*Center(
        child: TextButton(
          onPressed: () {
            levelUp(size);
          },
          child: const Text(
            "Level Up",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );*/
    );
  }
}
