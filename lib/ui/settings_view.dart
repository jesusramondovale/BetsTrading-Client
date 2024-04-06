import 'package:client_0_0_1/locale/localized_texts.dart';
import 'package:flutter/material.dart';
import '../helpers/common.dart';

import '../main.dart';

class SettingsView extends StatelessWidget {
  final VoidCallback onPersonalInfoTap;
  const SettingsView({super.key, required this.onPersonalInfoTap});

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings?.settings ?? "Settings"),
        backgroundColor:
        Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
      ),
      body: ListView(
        children: ListTile.divideTiles(
          context: context,
          tiles: [
            ListTile(
              title: Text(strings?.personalInfo ?? 'Personal info'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onPersonalInfoTap
            ),
            ListTile(
              title: Text(strings?.changePassword ?? "Change password"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Common().unimplementedAction(context),
            ),
            ListTile(
              title: Text(strings?.notifications ?? 'Notifications'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Common().unimplementedAction(context),
            ),
            ListTile(
              title: Text(strings?.contentSettings ?? 'Content settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Common().unimplementedAction(context),
            ),
            ListTile(
              title:  Text(strings?.paymentHistory ?? 'Payment history'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Common().unimplementedAction(context),
            ),
            ListTile(
              title: Text(strings?.aboutUs ?? 'About us'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Common().unimplementedAction(context),
            ),
          ],
        ).toList(),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16.0),
        child: Text(
            (strings?.versionCode ?? 'Version code: ') + CODE_VERSION,
            textAlign: TextAlign.center),
      ),
    );
  }
}