import 'package:flutter/services.dart';

/// En web no hay exit(); intenta cerrar la pestaña/vista.
void quitApp() {
  SystemNavigator.pop();
}
