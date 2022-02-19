import 'dart:math';

class XY {
  XY(this.x, this.y);
  final int x;
  final int y;
}

class Slice {
  Slice({
    required this.band,
    required this.slot,
    required this.posband,
    required this.posslot,
    required this.targetband,
    required this.targetslot,
    required this.width,
    required this.slots,
    this.selected = false,
  });

  factory Slice.v({required int band, required int slot}) {
    return Slice(
      band: band,
      slot: slot,
      posband: band,
      posslot: slot,
      targetband: band,
      targetslot: slot,
      width: 10,
      slots: 32,
    );
  }

  final int band;
  final int slot;
  int posband;
  int posslot;
  int targetband;
  int targetslot;
  int centreslot = 0;
  int slots;
  double width;
  double _a = 0;
  double _o = 0;
  bool selected;
  double get bandOffset => (posband - band) * width + _o;
  double get angle => (posslot - slot) * (2 * pi / slots) + _a;
  double get progress => _o;

  void move(double v) {
    final tband = targetband - posband;
    int tslot = targetslot - posslot;
    if (tband > 0) {
      //print("?: $band x $slot");
      //print("1POS: $posband x $posslot");
      //print("1TRG: $targetband x $targetslot");
      _o = width * v;
      if (v >= 1) {
        //++_o >= width) {
        //print("band move $_o");
        _o = 0;
        posband = targetband;
      }
    }
    if (tband < 0) {
      //print("?: $band x $slot");
      //print("2POS: $posband x $posslot");
      //print("2TRG: $targetband x $targetslot");
      _o = -width * v;
      if (v >= 1) {
        //if ((--_o).abs() >= width) {
        //print("band move $_o");
        _o = 0;
        posband = targetband;
        if (posband == 0) {
          centreslot = targetslot;
          targetslot = 0;
          posslot = targetslot;
        }
      }
    }
    if (tslot.abs() >= slots - 1) {
      tslot = tslot * -1;
    }
    if (tslot > 0) {
      //print("?: $band x $slot");
      //print("3POS: $posband x $posslot");
      //print("3TRG: $targetband x $targetslot");
      //_a += (2 * pi / 8) / 50;
      _a = (2 * pi / slots) * v;
      if (v >= 1) {
        // _a >= (2 * pi / 8)) {
        //print("slot move $_a");
        _a = 0;
        posslot = targetslot;
      }
    }
    if (tslot < 0) {
      //print("?: $band x $slot");
      //print("4POS: $posband x $posslot");
      //print("4TRG: $targetband x $targetslot");
      //_a += (2 * pi / 8) / 50;
      _a = -(2 * pi / slots) * v;
      if (v >= 1) {
        // _a >= (2 * pi / 8)) {
        //print("slot move $_a");
        _a = 0;
        posslot = targetslot;
      }
    }
  }
}
