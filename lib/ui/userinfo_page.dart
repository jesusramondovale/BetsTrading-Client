import 'dart:convert';
import 'package:betrader/ui/paymenthistory_page.dart';
import 'package:betrader/ui/verify_account_page.dart';
import 'package:betrader/ui/withdrawalhistory_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/services/BetsService.dart';
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
  bool userVerified = false;
  late String countryCode = '';
  late String _userId = '';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Uint8List? _profilePicBytes;
  bool isDark = true;

  Future<void> _loadProfilePic() async {
    String? profilePicString = await _storage.read(key: 'profilepic');
    String userId = await _storage.read(key: 'sessionToken') ?? '';
    if (profilePicString != null && profilePicString.isNotEmpty) {
      Uint8List imageBytes;
      if (profilePicString.startsWith('http')) {
        final response = await http.get(Uri.parse(profilePicString));
        if (response.statusCode == 200) {
          imageBytes = response.bodyBytes;
        } else {
          print('Error loading image from web');
          return;
        }
      } else {
        imageBytes = base64Decode(profilePicString);
      }
      setState(() {
        _userId = userId;
        _profilePicBytes = imageBytes;
      });
    }
  }

  Future<Map<String, String>> _readUserInfo(context) async {
    final strings = LocalizedStrings.of(context);
    Map<String, String> userInfo = {};

    List<String> keys = [
      'fullname',
      'username',
      'isverified',
      'email',
      'birthday',
      'country',
      'lastsession'
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
      if (value != null && key == 'country') {
        countryCode = value;
      }
      userInfo[key] = value ?? strings?.get('notAvailable') ?? 'Not available';
    }
    return userInfo;
  }

  @override
  void initState() {
    super.initState();
    _loadProfilePic();
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    return FutureBuilder<Map<String, String>>(
      future: _readUserInfo(context),
      builder:
          (BuildContext context, AsyncSnapshot<Map<String, String>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          userVerified = snapshot.data?['isverified'] == 'true' ? true : false;
          List<Widget> listItems = [];
          listItems.addAll(snapshot.data!.entries.where((entry) => entry.key != 'isverified').map((entry) {
            String title = '';
            switch (entry.key) {
              case "lastsession":
                title = strings?.get('lastSession') ?? 'Last Session';
                break;
              case "fullname":
                title = strings?.get('fullName') ?? 'Full Name';
                break;
              case "username":
                title = strings?.get('username') ?? 'User Name';
                break;
              case "email":
                title = strings?.get('email') ?? 'E-mail';
                break;
              case "country":
                title = strings?.get('country') ?? 'Country';
                break;
              case "address":
                title = strings?.get('address') ?? 'Address';
                break;
              case "birthday":
                title = strings?.get('birthday') ?? 'Birthday';
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
                    entry.value,
                    shape: RoundedRectangle(5),
                    height: 18,
                    width: 25,
                  ),
                  if (!userVerified)... [
                    SizedBox(width: 10, height: 1),
                    Text(strings!.get('pendingVerification') ?? '(Pending verification)',
                      style: TextStyle(color: Colors.redAccent),)
                  ]
                  else ... [
                    SizedBox(width: 5, height: 1),
                    Icon(Icons.verified, size: 18)
                  ]
                ],
              );
            }
            else if (entry.key == 'fullname') {
              if (!userVerified){
                subtitle = Column (
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.value, textAlign: TextAlign.start),
                    SizedBox(width: 10, height: 1),
                    Text(strings!.get('pendingVerification') ?? '(Pending verification)',
                        style: TextStyle(color: Colors.redAccent),)
                  ],
                );
              }
              else {
                subtitle = Row (
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(entry.value, textAlign: TextAlign.start),
                    SizedBox(width: 5, height: 1),
                    Icon(Icons.verified, size: 20)
                  ],
                );
              }

            }
            else if (entry.key == 'birthday') {
              Locale locale = Localizations.localeOf(context);
              String localeCode = "${locale.languageCode}_${locale.countryCode}";
              final parsed = DateFormat("d MMMM yyyy", "en_US").parse(entry.value);
              String localizedDate = DateFormat("d MMMM yyyy", localeCode).format(parsed);
              subtitle = Row (
                children: [
                  Text(localizedDate),
                  if (!userVerified)... [
                    SizedBox(width: 8, height: 1),
                    Text(strings!.get('pendingVerification') ?? '(Pending verification)',
                      style: TextStyle(color: Colors.redAccent),)
                  ]
                  else ... [
                    SizedBox(width: 5, height: 1),
                    Icon(Icons.verified, size: 16)
                  ]
                ],
              );
            }
            else {
              subtitle = Text(entry.value);
            }
            if (entry.key == 'fullname') {
              return TouchableTile(child:
                ListTile(
                  leading: (_profilePicBytes != null ? CircleAvatar(
                    radius: 28,
                      backgroundImage: MemoryImage(_profilePicBytes!)) :
                  Common().getIconForUserInfo(entry.key)),
                  title: Text(title,
                      style: GoogleFonts.syncopate(fontSize: 12, fontWeight: FontWeight.w500)),
                  subtitle: subtitle,
                  trailing: IconButton(
                    icon: const Icon(FontAwesomeIcons.camera),
                    onPressed: () async {
                      String? sessionToken =
                      await _storage.read(key: 'sessionToken');
                      bool result = await BetsService().uploadProfilePic(
                          sessionToken, await Common().pickImageFromGallery());
                      if (result) {
                        _loadProfilePic();
                        setState(() {
                          Common().popDialog(
                              strings?.get('success') ?? "Success!",
                              strings?.get('profilePictureUploadedSuccessfully') ??
                                  "Profile picture uploaded successfully",
                              context);
                        });
                      }
                    },
                  ),
                  onTap: () => Common().vibrate(),
                )
              );
            } else {
              return TouchableTile(child:
              ListTile(
                leading: Common().getIconForUserInfo(entry.key),
                title: Text(title, style: GoogleFonts.syncopate(fontSize: 15, fontWeight: FontWeight.w500)),
                subtitle: subtitle,
                onTap: () => Common().vibrate(),
              ));
            }
          }).toList());

          if (userVerified) {
            listItems.add(TouchableTile(child:
                ListTile(
                  leading: const Icon(Icons.verified),
                  title: Text(strings?.get('verified') ?? 'Account verified!',
                    style: GoogleFonts.syncopate(fontSize: 15, fontWeight: FontWeight.w500)),
                  onTap: () => Common().vibrate(),
                ),
              )
            );
          } else {
            listItems.add(TouchableTile(child:
              ListTile(
                leading: const Icon(Icons.verified_outlined, color: Colors.redAccent,),
                title: Text(strings?.get('verify') ?? 'Verify Account',
                    style: GoogleFonts.syncopate(fontSize: 15, fontWeight: FontWeight.w500,),
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          VerifyAccountPage(userId: _userId,),
                    ),
                  );
                },
              )),
            );
          }
          listItems.add(TouchableTile(child: ListTile(
              leading: const Icon(FontAwesomeIcons.creditCard),
              title: Text(strings?.get('paymentHistory') ?? 'Payment History', style: GoogleFonts.syncopate(fontSize: 15, fontWeight: FontWeight.w500)),
              onTap: () {
                Common().vibrate();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PaymentHistoryPage()
                  ),
                );

              },
            )
          )

          );

          listItems.add(TouchableTile(child: ListTile(
              leading: const Icon(FontAwesomeIcons.moneyBillTransfer),
              title: Text(strings?.get('withdrawalHistory') ?? 'Withdrawal History', style: GoogleFonts.syncopate(fontSize: 15, fontWeight: FontWeight.w500)),
              onTap: () {
                Common().vibrate();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => WithdrawalHistoryPage()
                  ),
                );

              },
            ))
          );
          listItems.add(
            TouchableTile(child: ListTile(
              leading: const Icon(FontAwesomeIcons.arrowRightFromBracket),
              title: Text(strings?.get('logOut') ?? 'Log Out', style: GoogleFonts.syncopate(fontSize: 15, fontWeight: FontWeight.w500)),
              onTap: () async {
                final response = await AuthService().logOut();
                if (response['success']) {
                  await _storage.deleteAll();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const LoginPage()),
                        (Route<dynamic> route) => false,
                  );
                } else {
                  setState(() {
                    Common().popDialog(
                        "Oops...", "${response['message']}", context);
                  });
                }
              },
            ))

          );

          return ListView(children: listItems);
        } else {
          return Center(
              child: Text(strings?.get('noInfoAvailable') ?? 'No info available!'));
        }
      },
    );
  }
}

class TouchableTile extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry margin;

  const TouchableTile({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 20.0,
    this.margin = const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
  });

  @override
  State<TouchableTile> createState() => _TouchableTileState();
}

class _TouchableTileState extends State<TouchableTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      margin: widget.margin,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: _pressed
            ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: .45),
            blurRadius: 20,
            spreadRadius: 1.5,
            offset: const Offset(0, 6),
          )
        ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            splashColor: Colors.white.withValues(alpha: .05),
            highlightColor: Colors.white.withValues(alpha: .03),
            onTap: widget.onTap,
            onHighlightChanged: (pressed) {
              setState(() => _pressed = pressed);
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}


