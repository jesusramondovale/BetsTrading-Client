import 'dart:convert';

import 'package:client_0_0_1/locale/localized_texts.dart';

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

  @override
  void initState() {
    super.initState();
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

  Future<void> _loadProfilePic() async {
    String? profilePicBase64 = await _storage.read(key: 'profilepic');
    if (profilePicBase64 != null && profilePicBase64.isNotEmpty) {
      setState(() {
        _profilePicBytes = base64Decode(profilePicBase64);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    return Container(
      color: Colors.white,
      child: FutureBuilder<Map<String, String>>(
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
                      bool result = await AuthService().uploadProfilePic(sessionToken, await Common().pickImageFromGallery());
                      if (result){
                        _loadProfilePic();
                        setState(() {

                        });
                        Common().popDialog(strings?.success ?? "Success!", strings?.profilePictureUploadedSuccessfully ?? "Profile picture uploaded successfully", context);
                      }
                      else{
                        Common().popDialog("Oops!", strings?.errorUploadingProfilePic ?? "An error has occurred while uploading the profile pic", context);
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
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(strings?.logOut ??'Log Out'),
                onTap: () async {
                  String? id = await _storage.read(key: 'sessionToken');
                  final response = await AuthService().logOut(id.toString());
                  if (response['success'])
                  {
                    await _storage.deleteAll();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                          (Route<dynamic> route) => false,
                    );
                  } else
                  {
                    Common().popDialog("Oops...", "${response['message']}" , context);
                  }

                },
              ),
            );

            return ListView(children: listItems);
          } else {
            return Center(child: Text(strings?.noInfoAvailable ?? 'No info available!'));
          }
        },
      ),
    );
  }

}