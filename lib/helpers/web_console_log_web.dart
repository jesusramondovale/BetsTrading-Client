import 'dart:html' as html;

/// Log a la consola del navegador (visible en release).
void webConsoleLog(String message) {
  html.window.console.log(message);
}
