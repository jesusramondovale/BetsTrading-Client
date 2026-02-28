import 'dart:convert';
import 'dart:ui';

import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/ui/markets_page.dart';
import 'package:betrader/ui/awards_page.dart';
import 'package:betrader/ui/userinfo_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/common.dart';
import '../helpers/preload_cache.dart';
import 'daily_reward_dialog.dart';
import 'exchange_page.dart';
import 'home_page.dart';
import 'login_page.dart';
import '../services/bets_service.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'notifications_page.dart';

final GlobalKey<HomeScreenState> homeScreenKey = GlobalKey<HomeScreenState>();
final GlobalKey<AwardsPageState> awardsScreenKey = GlobalKey<AwardsPageState>();
final GlobalKey<MarketsViewState> marketsPageKey = GlobalKey<MarketsViewState>();
final GlobalKey<ExchangePageState> exchangePageKey= GlobalKey<ExchangePageState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      initialRoute: '/login',
      home: LoginPage(),
    );
  }
}

/// The main menu page containing bottom navigation and tab management.
///
/// Manages navigation between Home, Awards, Markets, Exchange, and User Info tabs.
/// Handles Firebase messaging and app lifecycle events.
class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  MainMenuPageState createState() => MainMenuPageState();
}

/// Controller for managing the main menu page navigation state.
///
/// Provides methods to update the selected tab index and manage navigation.
class MainMenuPageController {
  /// Notifier for the currently selected tab index.
  final ValueNotifier<int> selectedIndexNotifier = ValueNotifier<int>(0);

  /// Updates the selected tab index.
  ///
  /// [index] The new tab index to select.
  void updateIndex(int index) {
    Common().vibrate();
    selectedIndexNotifier.value = index;
  }
}

class MainMenuPageState extends State<MainMenuPage> {
  Uint8List? _profilePicBytes;
  late List<Widget> _pages;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final MainMenuPageController _controller = MainMenuPageController();
  String _username = '';
  bool _showNotificationsPage = false;

  Future<void> _loadProfilePic() async {
    try {
      // Usar foto precargada durante "Cargando..." si existe
      final cached = PreloadCache.takeProfilePic();
      if (cached != null && mounted) {
        setState(() => _profilePicBytes = cached);
        if (kDebugMode) {
          print('[MainMenuPage] Profile pic from PreloadCache. Bytes: ${cached.length}');
        }
        return;
      }

      String? profilePicString = await _storage.read(key: 'profilepic');
      if (kDebugMode) {
        print('[MainMenuPage] Loading profile pic. Value from storage: ${profilePicString != null ? (profilePicString.isEmpty ? "empty" : "${profilePicString.substring(0, profilePicString.length > 50 ? 50 : profilePicString.length)}...") : "null"}');
      }
      
      if (profilePicString != null && 
          profilePicString.isNotEmpty && 
          profilePicString != 'null' && 
          profilePicString.toLowerCase() != 'null') {
        Uint8List imageBytes;
        if (profilePicString.startsWith('http')) {
          final response = await http.get(Uri.parse(profilePicString));
          if (response.statusCode == 200) {
            imageBytes = response.bodyBytes;
          } else {
            if (kDebugMode) {
              print('[MainMenuPage] Error loading profile pic from URL! Status code: ${response.statusCode}');
            }
            if (mounted) {
              setState(() {
                _profilePicBytes = null;
              });
            }
            return;
          }
        } else {
          try {
            imageBytes = base64Decode(profilePicString);
            if (kDebugMode) {
              print('[MainMenuPage] Successfully decoded base64 profile pic. Size: ${imageBytes.length} bytes');
            }
          } catch (e) {
            if (kDebugMode) {
              print('[MainMenuPage] Error decoding base64 profile pic: $e');
            }
            if (mounted) {
              setState(() {
                _profilePicBytes = null;
              });
            }
            return;
          }
        }
        if (mounted) {
          setState(() {
            _profilePicBytes = imageBytes;
          });
          if (kDebugMode) {
            print('[MainMenuPage] Profile pic loaded successfully. Image bytes: ${imageBytes.length}');
          }
        }
      } else {
        if (kDebugMode) {
          print('[MainMenuPage] Profile pic is null, empty, or "null" string. Clearing image.');
        }
        if (mounted) {
          setState(() {
            _profilePicBytes = null;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[MainMenuPage] Error loading profile pic: $e');
      }
      if (mounted) {
        setState(() {
          _profilePicBytes = null;
        });
      }
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      String? username = await _storage.read(key: 'username');
      if (username != null && mounted) {
        setState(() {
          _username = username;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user info: $e');
      }
    }
  }

  Future<void> _initializeData() async {
    // Cargar datos de forma asíncrona sin bloquear la UI
    await _loadUserInfo();
    await _loadProfilePic();
  }

  Future<void> _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool('first_run') ?? true;

    if (isFirstRun) {
      Permission.notification.request();
      setState(() {});
      await prefs.setBool('first_run', false);
    }
  }

  Future<void> _checkDailyReward() async {
    debugPrint('[DAILY_REWARD] _checkDailyReward START');
    if (!mounted) return;
    final userId = await _storage.read(key: 'sessionToken');
    debugPrint('[DAILY_REWARD] userId from storage: ${userId ?? "NULL"} (isEmpty: ${userId?.isEmpty ?? true})');
    if (userId == null || userId.isEmpty) {
      debugPrint('[DAILY_REWARD] ABORT: no userId');
      return;
    }
    debugPrint('[DAILY_REWARD] calling getDailyRewardStatus(userId)...');
    final status = await BetsService().getDailyRewardStatus(userId);
    debugPrint('[DAILY_REWARD] getDailyRewardStatus returned: $status');
    if (!mounted) return;
    final showDialog = status?['showDialog'] == true;
    final canClaim = status?['canClaim'] == true;
    debugPrint('[DAILY_REWARD] showDialog=$showDialog canClaim=$canClaim -> showIfNeeded? ${showDialog && canClaim}');
    await DailyRewardDialog.showIfNeeded(
      context,
      status: status,
      userId: userId,
      onClaimSuccess: () async {
        debugPrint('[DAILY_REWARD] onClaimSuccess CALLED - about to claimDailyReward(userId)');
        final ok = await BetsService().claimDailyReward(userId);
        debugPrint('[DAILY_REWARD] claimDailyReward returned: $ok (success=${ok['success']})');
        if (ok['success'] == true && mounted) {
          debugPrint('[DAILY_REWARD] success=true -> calling getUserInfo(userId) to refresh points');
          await BetsService().getUserInfo(userId);
          debugPrint('[DAILY_REWARD] getUserInfo done');
          homeScreenKey.currentState?.refreshUserPoints();
        } else {
          debugPrint('[DAILY_REWARD] success=false or !mounted, NOT calling getUserInfo');
        }
      },
    );
    debugPrint('[DAILY_REWARD] showIfNeeded returned (dialog closed)');
  }

  @override
  void initState() {
    super.initState();
    _checkFirstRun();
    _initializeData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyReward();
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Common().showLocalNotification(
          message.data['type'],
          message.notification!.title!,
          message.notification!.body!,
          message.data);
    });
  }

  @override
  Widget build(BuildContext context) {

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ));

    final strings = LocalizedStrings.of(context);
    final List<String> titles = [
      strings?.get('home') ?? 'Home',
      strings?.get('ranking') ?? 'Ranking',
      strings?.get('liveMarkets') ?? 'Live Markets',
      strings?.get('settings') ?? 'Settings',
      strings?.get('profile') ?? 'Profile'
    ];
    titles[3] = "Info  |  $_username";

    _pages = [
      // HOME
      HomeScreen(
        key: homeScreenKey,
        controller: _controller,
      ),
      // TOP USERS
      AwardsPage(
          key: awardsScreenKey,
          controller: _controller),
      // MARKETS
      MarketsView(
        key: marketsPageKey,
        controller: _controller,
      ),
      ExchangePage(key: exchangePageKey, controller: _controller),
      // PERSONAL INFO
      UserInfoPage(controller: _controller)
    ];

    return Scaffold(
        extendBody: true,
        body: Stack(children: [
          Positioned.fill(
            child: Image.asset(
              'assets/android12splash.png',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withValues(alpha: 0.2),
              ),
            ),
          ),

          Positioned.fill(
            child: SafeArea(
                child: Column(
                      children: [
                        Container(
                          height: 1.0,
                          color: Colors.black45,
                        ),
                        Expanded(
                          child: _showNotificationsPage
                              ? NotificationsPage(
                                  onBack: () {
                                    setState(() {
                                      _showNotificationsPage = false;
                                    });
                                  },
                                )
                              : ValueListenableBuilder<int>(
                                  valueListenable:
                                      _controller.selectedIndexNotifier,
                                  builder: (context, index, _) {
                                    return IndexedStack(
                                      index: _controller
                                          .selectedIndexNotifier.value,
                                      children: _pages,
                                    );
                                  },
                                ),
                        ),
                      ],
                    )),
          )
        ]),

        bottomNavigationBar:
            ValueListenableBuilder<int>(
                valueListenable: _controller.selectedIndexNotifier,
                builder: (context, index, _) {
                  return Container(
                    height: 70,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.transparent.withValues(alpha: 0.1),
                          spreadRadius: 10,
                          blurRadius: 10,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                    child: BottomNavigationBar(
                      backgroundColor: Colors.transparent.withValues(alpha: 0.1),
                      selectedItemColor: Colors.white,
                      unselectedItemColor: Colors.white30,
                      showUnselectedLabels: false,
                      showSelectedLabels: true,
                      iconSize: 28,
                      selectedLabelStyle: TextStyle(fontSize: 11),
                      unselectedLabelStyle: TextStyle(fontSize: 11),
                      items: <BottomNavigationBarItem>[
                        BottomNavigationBarItem(
                          icon: Icon(FontAwesomeIcons.house),
                          label: strings?.get('home') ?? "Home",
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(FontAwesomeIcons.trophy),
                          label: strings!.get('awards') ?? "Awards",
                        ),
                        BottomNavigationBarItem(
                          icon: SizedBox(
                            width: 40,
                            child: Image.asset('assets/new_icon.png'),
                          ),
                          activeIcon: SizedBox(
                            width: 34,
                            child: Image.asset('assets/new_icon.png'),
                          ),
                          label: strings.get('liveMarkets') ?? 'Live Markets',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(FontAwesomeIcons.landmark),
                          label: 'Exchange',
                        ),
                        BottomNavigationBarItem(
                          icon: (_profilePicBytes != null
                              ? CircleAvatar(
                                  backgroundImage:
                                      MemoryImage(_profilePicBytes!),
                                  radius: 20,
                                )
                              : Icon(Icons.account_circle_outlined)),
                          activeIcon: (_profilePicBytes != null
                              ? CircleAvatar(
                            backgroundImage:
                            MemoryImage(_profilePicBytes!),
                            radius: 15,
                          )
                              : Icon(Icons.account_circle_outlined)),
                          label: strings.get('profileTitle') ?? "Your profile",
                        ),
                      ],
                      currentIndex: _controller.selectedIndexNotifier.value,
                      onTap: (index) {
                        if (_showNotificationsPage) {
                          setState(() {
                            _showNotificationsPage = false;
                            _controller.updateIndex(index);
                          });
                        } else {
                          _controller.updateIndex(index);
                        }
                        // Recargar la imagen de perfil cuando se selecciona el tab de perfil
                        if (index == 4) {
                          _loadProfilePic();
                        }
                      },
                      type: BottomNavigationBarType.fixed,
                    ),
                  );
                },
              ),
      );
  }
}
