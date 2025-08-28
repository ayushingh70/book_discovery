import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  bool loggedIn = false;

  void logIn() {
    loggedIn = true;
    notifyListeners();
  }

  void logOut() {
    loggedIn = false;
    notifyListeners();
  }
}
