import 'dart:async';
import 'dart:convert';
import 'package:betrader/ui/paymenthistory_page.dart';
import 'package:betrader/ui/verify_account_page.dart';
import 'package:betrader/ui/withdrawalhistory_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/services/BetsService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../helpers/common.dart';
import '../services/AuthService.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'layout_page.dart';
import 'login_page.dart';

class UserInfoPage extends StatefulWidget {
  final MainMenuPageController controller;
  const UserInfoPage({super.key, required this.controller});

  @override
  UserInfoPageState createState() => UserInfoPageState();
}

class UserInfoPageState extends State<UserInfoPage> {
  final GlobalKey _kFirstSixTiles = GlobalKey();
  final GlobalKey _kProfileCamera = GlobalKey();
  final GlobalKey _kVerifyAccount = GlobalKey();
  final GlobalKey _kPaymentHistory = GlobalKey();
  final GlobalKey _kWithdrawalHistory = GlobalKey();
  final Completer<void> _builtOnce = Completer<void>();
  final GlobalKey _kLogout = GlobalKey();
  static const String _seenKey = '__tutorial_seen__userinfo_v1';
  static const String _pendingKey = '__tutorial_pending__userinfo_v1';
  bool userVerified = false;
  late String countryCode = '';
  late String _userId = '';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Uint8List? _profilePicBytes;
  bool isDark = true;
  TutorialCoachMark? _coach;
  bool _tutorialQueued = false;


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

  Future<Map<String, String>> _readUserInfo(BuildContext context) async {
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

  void _onIndexChange() {
    if (widget.controller.selectedIndexNotifier.value == 4) {
      scheduleMicrotask(() async {
        await _builtOnce.future;
        startUserInfoTutorial();
        widget.controller.selectedIndexNotifier.removeListener(_onIndexChange);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfilePic();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final pending = p.getBool(_pendingKey) ?? false;
      final seen = await _hasSeen();

      if (!(pending || !seen)) return;

      if (widget.controller.selectedIndexNotifier.value == 4) {
        await _builtOnce.future;
        startUserInfoTutorial();
      } else {
        widget.controller.selectedIndexNotifier.addListener(_onIndexChange);
      }
    });
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
          userVerified = snapshot.data?['isverified'] == 'true' ? true : false;

          final baseTiles = snapshot.data!.entries
              .where((entry) => entry.key != 'isverified')
              .map((entry) {
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
                  Text(entry.value != "null" ? entry.value : "-" ),
                  const SizedBox(width: 8),
                  CountryFlag.fromCountryCode(
                    entry.value,
                    shape: RoundedRectangle(5),
                    height: 18,
                    width: 25,
                  ),
                  if (!userVerified) ...[
                    const SizedBox(width: 10, height: 1),
                    Text(strings!.get('pendingVerification') ?? '(Pending verification)', style: const TextStyle(color: Colors.redAccent)),
                  ] else ...[
                    const SizedBox(width: 5, height: 1),
                    const Icon(Icons.verified, size: 18),
                  ]
                ],
              );
            } else if (entry.key == 'fullname') {
              if (!userVerified) {
                subtitle = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.value, textAlign: TextAlign.start),
                    const SizedBox(width: 10, height: 1),
                    Text(strings!.get('pendingVerification') ?? '(Pending verification)', style: const TextStyle(color: Colors.redAccent)),
                  ],
                );
              } else {
                subtitle = Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(entry.value, textAlign: TextAlign.start),
                    const SizedBox(width: 5, height: 1),
                    const Icon(Icons.verified, size: 20),
                  ],
                );
              }
            } else if (entry.key == 'birthday') {
              Locale locale = Localizations.localeOf(context);
              String localeCode = "${locale.languageCode}_${locale.countryCode}";
              final parsed = DateFormat("d MMMM yyyy", "en_US").parse(entry.value);
              String localizedDate = DateFormat("d MMMM yyyy", localeCode).format(parsed);
              subtitle = Row(
                children: [
                  Text(localizedDate),
                  if (!userVerified) ...[
                    const SizedBox(width: 8, height: 1),
                    Text(strings!.get('pendingVerification') ?? '(Pending verification)', style: const TextStyle(color: Colors.redAccent)),
                  ] else ...[
                    const SizedBox(width: 5, height: 1),
                    const Icon(Icons.verified, size: 16),
                  ]
                ],
              );
            } else {
              subtitle = Text(entry.value);
            }

            if (entry.key == 'fullname') {
              return TouchableTile(
                child: ListTile(
                  leading: (_profilePicBytes != null
                      ? CircleAvatar(radius: 28, backgroundImage: MemoryImage(_profilePicBytes!))
                      : Common().getIconForUserInfo(entry.key)),
                  title: Text(title, style: GoogleFonts.syncopate(fontSize: 12, fontWeight: FontWeight.w500)),
                  subtitle: subtitle,
                  trailing: IconButton(
                    padding: EdgeInsets.zero,
                    key: _kProfileCamera,
                    icon: const Icon(FontAwesomeIcons.cameraRotate),
                    onPressed: () async {
                      String? sessionToken = await _storage.read(key: 'sessionToken');
                      bool result = await BetsService().uploadProfilePic(
                          sessionToken, await Common().pickImageFromGallery());
                      if (result) {
                        _loadProfilePic();
                        setState(() {
                          Common().popDialog(
                            strings?.get('success') ?? "Success!",
                            strings?.get('profilePictureUploadedSuccessfully') ?? "Profile picture uploaded successfully",
                            context,
                          );
                        });
                      }
                    },
                  ),
                  onTap: () => {
                    Common().vibrate(),
                    Common().applyImmersive()
                  }
                ),
              );
            } else {
              return TouchableTile(
                child: ListTile(
                  leading: Common().getIconForUserInfo(entry.key),
                  title: Text(title, style: GoogleFonts.syncopate(fontSize: 15, fontWeight: FontWeight.w500)),
                  subtitle: subtitle,
                  onTap: () => {
                    Common().vibrate(),
                    Common().applyImmersive()
                  },
                ),
              );
            }
          }).toList();

          final firstSix = baseTiles.take(6).toList();
          final restAfterSix = baseTiles.skip(6).toList();

          final List<Widget> listItems = [
            KeyedSubtree(
              key: _kFirstSixTiles,
              child: Column(children: firstSix),
            ),
            ...restAfterSix,
          ];

          if (userVerified) {
            listItems.add(
              TouchableTile(
                child: ListTile(
                  leading: const Icon(Icons.verified),
                  title: Text(strings?.get('verified') ?? 'Account verified!', style: GoogleFonts.syncopate(fontSize: 15, fontWeight: FontWeight.w500)),
                  onTap: () => {
                    Common().vibrate(),
                    Common().applyImmersive()
                  }
                ),
              ),
            );
          } else {
            listItems.add(
              TouchableTile(
                child: ListTile(
                  key: _kVerifyAccount,
                  leading: const Icon(Icons.verified_outlined, color: Colors.redAccent),
                  title: Text(strings?.get('verify') ?? 'Verify Account', style: GoogleFonts.syncopate(fontSize: 15, fontWeight: FontWeight.w500)),
                  onTap: () async {
                    Common().applyImmersive();
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => VerifyAccountPage(userId: _userId)));
                  },
                ),
              ),
            );
          }

          listItems.add(
            TouchableTile(
              child: ListTile(
                key: _kPaymentHistory,
                leading: const Icon(FontAwesomeIcons.creditCard),
                title: Text(strings?.get('paymentHistory') ?? 'Payment History', style: GoogleFonts.syncopate(fontSize: 15, fontWeight: FontWeight.w500)),
                onTap: () {
                  Common().vibrate();
                  Common().applyImmersive();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => PaymentHistoryPage()));
                },
              ),
            ),
          );

          listItems.add(
            TouchableTile(
              child: ListTile(
                key: _kWithdrawalHistory,
                leading: const Icon(FontAwesomeIcons.moneyBillTransfer),
                title: Text(strings?.get('withdrawalHistory') ?? 'Withdrawal History', style: GoogleFonts.syncopate(fontSize: 15, fontWeight: FontWeight.w500)),
                onTap: () {
                  Common().vibrate();
                  Common().applyImmersive();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => WithdrawalHistoryPage()));
                },
              ),
            ),
          );

          listItems.add(
            TouchableTile(
              child: ListTile(
                key: _kLogout,
                leading: const Icon(FontAwesomeIcons.arrowRightFromBracket),
                title: Text(strings?.get('logOut') ?? 'Log Out', style: GoogleFonts.syncopate(fontSize: 15, fontWeight: FontWeight.w500)),
                onTap: () async {
                  Common().applyImmersive();
                  final response = await AuthService().logOut();
                  if (response['success']) {
                    await _storage.deleteAll();
                    LoginPage.navigateToLogin(context);
                  } else {
                    if (mounted) {
                      setState(() {
                        Common().popDialog("Oops...", "${response['message']}", context);
                      });
                    }
                  }
                },
              ),
            ),
          );

          if (!_tutorialQueued) {
            _tutorialQueued = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_builtOnce.isCompleted) _builtOnce.complete();
            });
          }

          return ListView(children: listItems);
        } else {
          return Center(child: Text(strings?.get('noInfoAvailable') ?? 'No info available!'));
        }
      },
    );
  }

  @override
  void dispose() {
    widget.controller.selectedIndexNotifier.removeListener(_onIndexChange);
    super.dispose();
  }

  //-----   T U T O R I A L      M E T H O D S ------

  List<TargetFocus> _buildUserInfoTargets() {
    LocalizedStrings? strings = LocalizedStrings.of(context);
    final targets = <TargetFocus>[
      TargetFocus(
        identify: 'first_six',
        keyTarget: _kFirstSixTiles,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [TargetContent(align: ContentAlign.bottom, builder: (_, __) => Common().bubble(
            strings!.get('pf_profile_title') ?? 'Your profile',
            strings.get('pf_profile_body') ?? 'These are your personal details. Until your identity is verified, some fields may appear highlighted in red as pending.'))],
      ),
      TargetFocus(
        identify: 'camera',
        keyTarget: _kProfileCamera,
        shape: ShapeLightFocus.Circle,
        contents: [TargetContent(align: ContentAlign.bottom, builder: (_, __) => Common().bubble(
            strings!.get('pf_camera_title') ?? 'Photo',
            strings.get('pf_camera_body') ?? 'Upload a new profile picture here. Make sure it meets content and privacy guidelines.'))],
      ),
      TargetFocus(
        identify: 'verify',
        keyTarget: _kVerifyAccount,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [TargetContent(align: ContentAlign.top, builder: (_, __) => Common().bubble(
            strings!.get('pf_verify_title') ?? 'Verify your account',
            strings.get('pf_verify_body') ?? 'Complete the KYC verification to unlock withdrawals and monthly prize features.'))],
      ),
      TargetFocus(
        identify: 'payments',
        keyTarget: _kPaymentHistory,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [TargetContent(align: ContentAlign.top, builder: (_, __) => Common().bubble(
            strings!.get('pf_payments_title') ?? 'Payments',
            strings.get('pf_payments_body') ?? 'Review your coin purchase history here.'))],
      ),
      TargetFocus(
        identify: 'withdrawals',
        keyTarget: _kWithdrawalHistory,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [TargetContent(align: ContentAlign.top, builder: (_, __) => Common().bubble(
            strings!.get('pf_withdrawals_title') ?? 'Withdrawals',
            strings.get('pf_withdrawals_body') ?? 'Review your coin withdrawal history here.'))],
      ),
      TargetFocus(
        identify: 'logout',
        keyTarget: _kLogout,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [TargetContent(align: ContentAlign.top, builder: (_, __) => Common().bubble(
            strings!.get('pf_logout_title') ?? 'Sign out',
            strings.get('pf_logout_body') ?? 'Sign out of the app. If you will stop using this device, clear the app’s stored data in system settings and remove any linked sessions.'))],
      ),
    ];
    return targets.where((t) => t.keyTarget?.currentContext != null).toList();
  }

  Future<void> startUserInfoTutorial() async {
    LocalizedStrings? strings = LocalizedStrings.of(context);

    for (int i = 0; i < 50; i++) {
      final ready = _kFirstSixTiles.currentContext != null &&
          _kProfileCamera.currentContext != null &&
          _kPaymentHistory.currentContext != null &&
          _kWithdrawalHistory.currentContext != null &&
          _kLogout.currentContext != null;
      if (ready) break;
    }
    final targets = _buildUserInfoTargets();
    if (targets.isEmpty) return;
    _coach = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.75,
      textSkip: strings!.get('tutorial_skip') ?? 'Skip tutorial',
      textStyleSkip: const TextStyle(fontWeight: FontWeight.w500 , fontSize: 20),
      hideSkip: false,
      useSafeArea: true,
      pulseEnable: true,
      disableBackButton: true,
      onSkip: () {
        _markSeen();
        _clearPending();
        Common().markAllTutorialsSeen();
        return true;
        },
      onFinish: () async {
        await _markSeen();
        await _clearPending(); },
    );
    _coach!.show(context: context);
  }

  Future<void> _clearPending() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_pendingKey);
  }

  Future<void> _markSeen() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_seenKey, true);
  }

  Future<bool> _hasSeen() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_seenKey) ?? false;
  }

  //-----   T U T O R I A L      M E T H O D S ------

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


