import 'package:flutter/foundation.dart';

import '../util/dates.dart';

/// UI-only navigation state for the habits home screen (selected day, stats
/// panel open/closed) — kept separate from [MotivationController] since it's
/// purely a view concern, not app data. Owned by the shell so keyboard
/// shortcuts can drive it from anywhere.
class HomeNavState extends ChangeNotifier {
  DateTime _date = DateTime.now();
  bool _statsOpen = true;

  DateTime get date => dateOnly(_date);
  bool get statsOpen => _statsOpen;

  void shiftDay(int delta) {
    _date = dateOnly(_date).add(Duration(days: delta));
    notifyListeners();
  }

  void goToToday() {
    _date = DateTime.now();
    notifyListeners();
  }

  void setStatsOpen(bool value) {
    _statsOpen = value;
    notifyListeners();
  }
}
