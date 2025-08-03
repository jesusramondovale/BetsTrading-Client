import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../locale/localized_texts.dart'; // Asegúrate de importar la clase LocalizedStrings

class ConsentPage {
  static Future<void> showConsentDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasConsented = prefs.getBool('hasConsented') ?? false;

    // Si el usuario ya aceptó, no mostramos el diálogo
    if (hasConsented) return;

    // Accede a las traducciones antes de mostrar el diálogo

    await showDialog(
      context: context,
      barrierDismissible: false, // Evita cerrar el diálogo tocando fuera
      builder: (BuildContext dialogContext) {
        return Stack(
          children : [
            Positioned.fill(
              child: Image.asset(
                'assets/backgn.png',
                fit: BoxFit.cover,
              ),
            ),
            Center(
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                title: Text(
                  LocalizedStrings.of(context)!.get('consent_required') ?? "Consent Required",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      LocalizedStrings.of(context)!.get('consent_message') ??
                          "We need your consent to process your data for the following purposes:",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      leading: const Icon(Icons.person, color: Colors.blue),
                      title: Text(
                        LocalizedStrings.of(context)!.get('advertising_content') ??
                            "Personalised advertising and content",
                      ),
                      subtitle: Text(
                        LocalizedStrings.of(context)!.get('advertising_details') ??
                            "Advertising and content measurement, audience insights.",
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.storage, color: Colors.blue),
                      title: Text(
                        LocalizedStrings.of(context)?.get('data_storage') ??
                            "Store and access information",
                      ),
                      subtitle: Text(
                        LocalizedStrings.of(context)?.get('data_storage_details') ??
                            "Cookies and device data usage.",
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      LocalizedStrings.of(context)?.get('withdraw_consent') ??
                          "By accepting, you agree to the terms of data processing. You can withdraw your consent anytime.",
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () async {
                      await prefs.setBool('hasConsented', true);
                      Navigator.of(dialogContext).pop();
                    },
                    child: Text(
                      LocalizedStrings.of(context)?.get('i_consent') ?? "I Consent",
                    ),
                  ),
                ],
              )
            )
          ]
        );
      },
    );
  }
}

