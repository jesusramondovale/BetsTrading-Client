// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:client_0_0_1/locale/localized_texts.dart';
import 'package:client_0_0_1/services/BetsService.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/common.dart';
import '../services/AuthService.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'login_page.dart';

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Uint8List? _profilePicBytes;
  bool isDark = true;
  @override
  void initState() {
    super.initState();
    _loadThemePreference();
    _loadProfilePic();
  }

  Future<Map<String, String>> _readUserInfo(context) async {
    final strings = LocalizedStrings.of(context);
    Map<String, String> userInfo = {};

    List<String> keys = [
      'fullname', 'username', 'email', 'birthday', 'address', 'country', 'lastsession'
    ];

    for (String key in keys) {
      String? value = await _storage.read(key: key);
      if (value != null && key == 'birthday') {
        DateTime date = DateTime.parse(value);
        value = DateFormat('d MMMM yyyy').format(date);
      }
      if (value != null && key == 'lastsession') {
        DateTime utcDate = DateTime.parse(value);
        DateTime localDate = utcDate.toLocal();
        value = DateFormat("HH'h'mm (dd-MM-yyyy)").format(localDate);
      }
      userInfo[key] = value ?? strings?.notAvailable ?? 'Not available';
    }
    return userInfo;
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    bool darkTheme = prefs.getBool('darkTheme') ?? true;
    setState(() {
      isDark = darkTheme;
    });
  }

  Future<void> _saveThemePreference(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkTheme', isDark);
  }
  Future<void> _loadProfilePic() async {
    String? profilePicString = await _storage.read(key: 'profilepic');
    if (profilePicString != null && profilePicString.isNotEmpty) {
      Uint8List imageBytes;
      if (profilePicString.startsWith('http')) {
        final response = await http.get(Uri.parse(profilePicString));
        if (response.statusCode == 200) {
          imageBytes = response.bodyBytes;
        } else {
          print('Error al cargar la imagen de la red');
          return;
        }
      } else {
        imageBytes = base64Decode(profilePicString);
      }
      setState(() {
        _profilePicBytes = imageBytes;
      });
    }
  }


  @override
  Widget build(BuildContext context) {

    final strings = LocalizedStrings.of(context);
    return FutureBuilder<Map<String, String>>(
      future: _readUserInfo(context),
      builder: (BuildContext context, AsyncSnapshot<Map<String, String>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          List<Widget> listItems = [];

          listItems.addAll(snapshot.data!.entries.map((entry) {
            String title = '';
            switch (entry.key) {
              case "lastsession":
                title = strings?.lastSession ?? 'Last Session';
                break;
              case "fullname":
                title = strings?.fullName ?? 'Full Name';
                break;
              case "username":
                title = strings?.username ??'User Name';
                break;
              case "email":
                title = strings?.email ?? 'E-mail';
                break;
              case "country":
                title = strings?.country ?? 'Country';
                break;
              case "address":
                title = strings?.address ?? 'Address';
                break;
              case "birthday":
                title = strings?.birthday ?? 'Birthday';
                break;

              default:
                title = Common().capitalizeFirstLetter(entry.key.toString());
            }

            Widget subtitle;
            if (entry.key == 'country') {
              subtitle = Row(
                children: [
                  Text(entry.value),
                  const SizedBox(width: 8),

                  CountryFlag.fromCountryCode(
                    Common().getCountryCode(entry.value).toString(),
                    height: 18,
                    width: 25,
                    borderRadius: 5,
                  ),
                ],
              );
            } else {
              subtitle = Text(entry.value);
            }
            if (entry.key == 'fullname' && _profilePicBytes != null) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: MemoryImage(_profilePicBytes!),
                ),
                title: Text(title),
                subtitle: subtitle,
                trailing: IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () async {
                    //Common().unimplementedAction("UploadImage()", context);
                    String? sessionToken = await _storage.read(key: 'sessionToken');
                    bool result = await BetsService().uploadProfilePic(sessionToken, await Common().pickImageFromGallery());
                    if (result){
                      _loadProfilePic();
                      setState(() {
                        Common().popDialog(strings?.success ?? "Success!", strings?.profilePictureUploadedSuccessfully ?? "Profile picture uploaded successfully", context);
                      });

                    }
                    else{
                      setState(() {
                        Common().popDialog("Oops!", strings?.errorUploadingProfilePic ?? "An error has occurred while uploading the profile pic", context);
                      });

                    }
                  },
                ),
              );
            } else {
              return ListTile(
                leading: Common().getIconForUserInfo(entry.key),
                title: Text(title),
                subtitle: subtitle,
              );
            }
          }).toList());

          listItems.add(
            SwitchListTile(
              title: Text(strings?.darkMode ?? "Dark mode"),
              value: isDark,
              onChanged: (bool value) async {
                await _saveThemePreference(value);
                setState(() {
                  isDark = value;
                  Common().exitPopDialog(strings?.attention ?? "Attention!" , strings?.needToRestart ?? "App must restart", context);
                });
              },
            ),
          );
          listItems.add(

            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(strings?.logOut ??'Log Out'),
              onTap: () async {
                String? id = await _storage.read(key: 'sessionToken');
                final response = await AuthService().logOut(id.toString());
                if (response['success'])
                {
                  await _storage.deleteAll();
                  setState(() {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                          (Route<dynamic> route) => false,
                    );
                  });
                } else
                {
                  setState(() {
                    Common().popDialog("Oops...", "${response['message']}" , context);
                  });

                }

              },
            ),
          );

          return ListView(children: listItems);
        } else {
          return Center(child: Text(strings?.noInfoAvailable ?? 'No info available!'));
        }
      },
    );
  }

}