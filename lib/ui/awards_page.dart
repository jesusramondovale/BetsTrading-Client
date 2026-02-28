import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:betrader/locale/localized_texts.dart';
import 'package:betrader/models/raffle_items.dart';
import 'package:betrader/ui/layout_page.dart';
import 'package:flutter/material.dart';
import 'package:betrader/services/top_service.dart';
import 'package:betrader/models/users.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../services/bets_service.dart';
import '../config/config.dart';
import '../helpers/common.dart';
import '../helpers/slider.dart';
import 'home_page.dart';

/// A page displaying leaderboards, top users, and raffle items.
///
/// Shows rankings with medals for top 3 positions, user points, and
/// available raffle prizes. Supports tab navigation between different views.
class AwardsPage extends StatefulWidget {
  /// Controller for managing the main menu navigation.
  final MainMenuPageController controller;
  const AwardsPage({super.key, required this.controller});


  @override
  State<AwardsPage> createState() => AwardsPageState();
}

class AwardsPageState extends State<AwardsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final _kTopList = GlobalKey();
  final _kRaffles  = GlobalKey();
  String? _userId;
  double _userPoints = 0;
  String _userCountry = "none";
  List<RaffleItem> _raffleItems = [];
  static const double _rowExtent = 45;
  static const double _rowGap = 8;
  static const int _visibleItems = 5;
  Timer? _refreshTimer;
  TutorialCoachMark? _coach;
  static const String _pendingFlag  = '__tutorial_pending__awards_v1';
  static const String _seenFlag     = '__tutorial_seen__awards_v1';
  late final VoidCallback _tabListener;

  /// Loads user ID and initializes awards page data.
  ///
  /// Fetches user information, points, country, currency preference,
  /// and available raffle items from the server.
  Future<void> loadUserIdAndData() async {
    final userId = await _storage.read(key: "sessionToken") ?? "none";
    await BetsService().getUserInfo(userId);
    final userCountry = await _storage.read(key: "country") ?? "none";
    final points = await _storage.read(key: 'points') ?? '0';
    final raffleItemsResponse = await Common().postRequestWrapper(
      'Info',
      'RaffleItems',
      {'userId': userId},
    );
    final body = raffleItemsResponse['body'];

    List<RaffleItem> parsedRaffleItems = [];
    if (body is List) {
      parsedRaffleItems = body
          .whereType<Map<String, dynamic>>()
          .map(RaffleItem.fromJson)
          .toList();
    } else if (body is Map && body['items'] is List) {
      parsedRaffleItems = (body['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(RaffleItem.fromJson)
          .toList();
    }

    if(mounted) {
      setState(() {
      _userId = userId;
      _userCountry = userCountry;
       _raffleItems = parsedRaffleItems;
      _userPoints = double.tryParse(points) ?? 0;
    });
    }
  }

  Widget _buildUserRow(User user, int rank, String prize, {double? rowExtent}) {
    final scaleFactor = rowExtent != null ? (rowExtent / _rowExtent).clamp(0.75, 1.2) : 1.0;
    final borderRadius = BorderRadius.circular((14 * scaleFactor).clamp(10.0, 18.0));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: () {
          Common().vibrate();
          Common().applyImmersive();
          popUserDialog(context, user);
        },
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.06),
            borderRadius: borderRadius,
            border: Border.all(color: Colors.white.withValues(alpha:0.10), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.18),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: (10 * scaleFactor).clamp(6.0, 14.0),
            vertical: (6 * scaleFactor).clamp(4.0, 8.0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: (45 * scaleFactor).clamp(35.0, 55.0),
                child: Row(
                  children: [
                    if (rank <= 3) ...[
                      MedalBadge(rank: rank, size: (30 * scaleFactor).clamp(24.0, 36.0)),
                    ] else ...[
                      Text(
                        '$rank',
                        style: GoogleFonts.syncopate(
                          fontSize: (16 * scaleFactor).clamp(12.0, 20.0),
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha:0.9),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              Expanded(
                child: Text(
                  user.fullname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: (17 * scaleFactor).clamp(14.0, 20.0),
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha:0.95),
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              Container(
                width: 1,
                height: (24 * scaleFactor).clamp(18.0, 30.0),
                margin: EdgeInsets.symmetric(horizontal: (8 * scaleFactor).clamp(6.0, 10.0)),
                color: Colors.white.withValues(alpha:0.12),
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    NumberFormat.compact().format(user.points),
                    style: GoogleFonts.montserrat(
                      fontSize: (18 * scaleFactor).clamp(14.0, 22.0),
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha:0.95),
                    ),
                  ),
                  SizedBox(width: (4 * scaleFactor).clamp(2.0, 6.0)),
                  Image.asset(
                    'assets/coin.png',
                    width: (18 * scaleFactor).clamp(14.0, 22.0),
                    height: (18 * scaleFactor).clamp(14.0, 22.0),
                  ),
                  Container(
                    width: 1,
                    height: (24 * scaleFactor).clamp(18.0, 30.0),
                    margin: EdgeInsets.symmetric(horizontal: (8 * scaleFactor).clamp(6.0, 10.0)),
                    color: Colors.white.withValues(alpha:0.12),
                  ),
                  if (prize.isNotEmpty) ...[
                    Text(
                      prize,
                      style: GoogleFonts.montserrat(
                        fontSize: (16 * scaleFactor).clamp(12.0, 20.0),
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopUsersView(List<String> rewards, {userCountry, double? rowExtent, double? rowGap}) {
    final effectiveRowExtent = rowExtent ?? _rowExtent;
    final effectiveRowGap = rowGap ?? _rowGap;
    final double blockHeight = effectiveRowExtent * _visibleItems + effectiveRowGap * (_visibleItems - 1);

    if (_userId == null) {
      return SizedBox(
        height: blockHeight,
        child: _TopUsersSkeleton(count: _visibleItems, rowExtent: effectiveRowExtent, gap: effectiveRowGap),
      );
    }

    return FutureBuilder<List<User>>(
      future: (userCountry != null
          ? TopService().fetchTopUsersByCountry(userCountry)
          : TopService().fetchTopUsers(_userId ?? "none")),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: blockHeight,
            child: _TopUsersSkeleton(count: _visibleItems, rowExtent: effectiveRowExtent, gap: effectiveRowGap),
          );
        } else if (snapshot.hasError) {
          return SizedBox(
            height: blockHeight,
            child: Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: GoogleFonts.montserrat(color: Colors.white70),
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox(
            height: blockHeight,
            child: const Center(child: Icon(Icons.no_accounts, size: 120, color: Colors.white54)),
          );
        } else {
          final users = snapshot.data!;
          final count = min(_visibleItems, users.length);

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: count,
            padding: EdgeInsets.symmetric(horizontal: (10 * (rowExtent != null ? rowExtent / _rowExtent : 1.0)).clamp(6.0, 14.0)),
            separatorBuilder: (_, __) => SizedBox(height: effectiveRowGap),
            itemBuilder: (_, i) => SizedBox(
              height: effectiveRowExtent,
              child: _buildUserRow(users[i], i+1 , rewards.elementAt(i), rowExtent: rowExtent),
            ),
          );
        }
      },
    );
  }

  void popUserDialog(BuildContext context, User user) {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, a, b) {
        final topOffset = MediaQuery.of(context).size.height * 0.25;
        final horizontalMargin = 20.0;
        return SizedBox.expand(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(horizontalMargin, topOffset, horizontalMargin, 0),
              child: UserDialog(user: user),
            ),
          ),
        );
      },
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.elasticOut),
            ),
            child: child,
          ),
        );
      },
    );
  }

  // -------- T U T O R I A L      M E T H O D S ---------
  Future<void> _markSeen() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_seenFlag, true);
  }

  Future<void> _clearPending() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_pendingFlag);
  }

  Future<void> _waitForTargetsReady() async {
    for (int i = 0; i < 30; i++) {
      if (!mounted) return;
      final ready =
              _kTopList.currentContext != null &&
              _kRaffles.currentContext != null;
      if (ready) break;
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  List<TargetFocus> _buildAwardsTargets() {
    LocalizedStrings? strings = LocalizedStrings.of(context);
    return [
      TargetFocus(
        identify: 'aw_toplist',
        keyTarget: _kTopList,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (_, __) => Common().bubble(
                strings!.get('aw_toplist_title') ?? 'Ranking',
                strings.get('aw_toplist_body') ??
                    'See the top 5 users and their prizes. Switch between the worldwide board or your country to compare positions and rewards.'),
          ),
        ],
      ),
      TargetFocus(
        identify: 'aw_raffles',
        keyTarget: _kRaffles,
        shape: ShapeLightFocus.RRect,
        radius: 14,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (_, __) => Common().bubble(
                strings!.get('aw_raffles_title') ?? 'Raffles',
                strings.get('aw_raffles_body') ??
                    'Pick a prize and join using your coins. Check cost and remaining time; entries are summed as participants update live.'),
          ),
        ],
      ),
    ];
  }

  Future<void> _tryStartAwardsTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool(_pendingFlag) ?? false;

    if (!pending) return;

    await _waitForTargetsReady();

    if (widget.controller.selectedIndexNotifier.value != 1) return;

    await _startAwardsTutorial();
  }

  Future<void> _startAwardsTutorial() async {
    LocalizedStrings? strings = LocalizedStrings.of(context);

    if (!mounted) return;

    final targets = _buildAwardsTargets()
        .where((t) => t.keyTarget?.currentContext != null)
        .toList();

    if (targets.isEmpty) {
      await _clearPending();
      return;
    }

    _coach = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.75,
      textSkip: strings!.get('tutorial_skip') ?? 'Skip tutorial',
      textStyleSkip: const TextStyle(fontWeight: FontWeight.w500 , fontSize: 20),
      hideSkip: false,
      useSafeArea: true,
      pulseEnable: true,
      alignSkip: Alignment.bottomRight,
      initialFocus: 0,
      disableBackButton: true,
      onSkip: () {
        _clearPending();
        _markSeen();
        Common().markAllTutorialsSeen();
        return true;
      },
      onFinish: () async {
        await _clearPending();
        await _markSeen();

        final p = await SharedPreferences.getInstance();
        await p.setBool('__tutorial_pending__markets_v1', true);

        if (!mounted) return;
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!mounted) return;
          widget.controller.updateIndex(2);
        });

      },
    );

    _coach!.show(context: context);
  }

  @override
  void initState() {
    super.initState();
    loadUserIdAndData();
    _tabController = TabController(length: 2, vsync: this);
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) loadUserIdAndData(); Common().applyImmersive();
    });

    _tabListener = () {
      if (widget.controller.selectedIndexNotifier.value == 1) {
        _tryStartAwardsTutorial();
      }
    };

    widget.controller.selectedIndexNotifier.addListener(_tabListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.selectedIndexNotifier.value == 1) {
        _tryStartAwardsTutorial();
      }
    });


  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;

    // Calcular valores responsivos
    final scaleFactor = (screenHeight / 800.0).clamp(0.75, 1.2);
    final rowExtent = (45 * scaleFactor).clamp(35.0, 55.0);
    final rowGap = (8 * scaleFactor).clamp(6.0, 10.0);
    final visibleItems = _visibleItems;

    // Obtener la altura del bottomNavigationBar (70 píxeles según layout_page.dart)
    // y agregar padding adicional para evitar que los elementos queden ocultos
    final bottomNavBarHeight = 70.0;
    final additionalPadding = (16 * scaleFactor).clamp(12.0, 20.0);
    final totalBottomPadding = bottomNavBarHeight + additionalPadding;
    
    return SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: totalBottomPadding),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            SizedBox(height: (10 * scaleFactor).clamp(6.0, 14.0)),
            Padding(
                padding: EdgeInsetsGeometry.fromLTRB(
                  (6 * scaleFactor).clamp(4.0, 8.0),
                  0,
                  (6 * scaleFactor).clamp(4.0, 8.0),
                  0
                ),
                child:  Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Container(
                      key: _kTopList,
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: (12 * scaleFactor).clamp(8.0, 16.0)),
                            child: _FolderTabs(
                              controller: _tabController,
                              tabs: [
                                strings?.get('worldwide') ?? 'Worldwide',
                                strings?.get('yourCountry') ?? 'Your Region',
                              ],
                              leadingLabel: strings?.get('raffles') ?? 'Raffles',
                              scaleFactor: scaleFactor,
                            ),
                          ),
                          SizedBox(height: (8 * scaleFactor).clamp(6.0, 10.0)),
                          SizedBox(
                            height: rowExtent * visibleItems + rowGap * (visibleItems - 1),
                            child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildTopUsersView(
                                    Config.top5Rewards,
                                    rowExtent: rowExtent,
                                    rowGap: rowGap,
                                  ),
                                  _buildTopUsersView(
                                    Config.top5Rewards,
                                    userCountry: _userCountry,
                                    rowExtent: rowExtent,
                                    rowGap: rowGap,
                                  ),
                                ],
                            ),
                          ),
                          SizedBox(height: (16 * scaleFactor).clamp(12.0, 20.0)),

                          ]
                      ),
                    ),

                    // RAFFLES
                    Column(
                      key: _kRaffles,
                      children: [
                        Row(
                          children: [
                            Text(
                              strings?.get('raffles') ?? 'Raffles',
                              style: GoogleFonts.syncopate(
                                  fontSize: (18 * scaleFactor).clamp(14.0, 22.0),
                                  fontWeight: FontWeight.w200),
                            ),
                            Spacer(),
                            DaysToMinutesCountDown(scaleFactor: scaleFactor)
                          ],
                        ),
                        Divider(color: Colors.white, thickness: 0.5, height: 0.5),
                        RafflesBuilder(
                            raffleItems: _raffleItems,
                            userPoints: _userPoints,
                            userId: _userId ?? '0',
                            scaleFactor: scaleFactor,
                            onRaffleSuccess: () async => {
                              loadUserIdAndData(),
                              homeScreenKey.currentState?.loadUserIdAndData()
                            }
                        )
                      ],
                    ),
                  ],
                )
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }
}

class _FolderTabs extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;
  final String leadingLabel;
  final double scaleFactor;

  const _FolderTabs({
    required this.controller,
    required this.tabs,
    required this.leadingLabel,
    this.scaleFactor = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final double barHeight = kTextTabBarHeight;
    final double horizontalPadding = (12 * scaleFactor).clamp(8.0, 16.0);

    return SizedBox(
      height: barHeight + 1,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -horizontalPadding,
            right: -horizontalPadding,
            bottom: 0,
            child: Container(
              height: 1,
              color: Colors.white,
            ),
          ),

          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: IgnorePointer(
                ignoring: true,
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: Text(
                    'Top-5',
                    style: GoogleFonts.syncopate(
                      fontSize: (28 * scaleFactor).clamp(22.0, 34.0),
                      fontWeight: FontWeight.w300,
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: barHeight,
              width: double.infinity,
              child: Row(
                children: [
                  const Spacer(),
                  TabBar(
                    dividerColor: Colors.transparent,
                    controller: controller,
                    isScrollable: true,
                    labelPadding: EdgeInsets.symmetric(horizontal: (14 * scaleFactor).clamp(10.0, 18.0)),
                    indicatorSize: TabBarIndicatorSize.tab,
                    overlayColor: WidgetStatePropertyAll(
                      Colors.white.withValues(alpha: 0.02),
                    ),
                    labelStyle: GoogleFonts.comfortaa(
                      fontSize: (18 * scaleFactor).clamp(14.0, 22.0),
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: GoogleFonts.comfortaa(
                      fontSize: (18 * scaleFactor).clamp(14.0, 22.0),
                      fontWeight: FontWeight.w400,
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicator: const _FolderIndicator(),
                    tabs: tabs
                        .map(
                          (t) => Tab(
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: (6 * scaleFactor).clamp(4.0, 8.0),
                            bottom: (2 * scaleFactor).clamp(1.0, 3.0),
                          ),
                          child: Text(t),
                        ),
                      ),
                    )
                        .toList(),
                  ),
                  SizedBox(width: horizontalPadding),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _FolderIndicator extends Decoration {
  const _FolderIndicator();
  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _FolderPainter();
}
class _FolderPainter extends BoxPainter {
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    if (cfg.size == null) return;
    final rect = offset & cfg.size!;
    const baseGap = 1.0;
    final tabRect = Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width,
      rect.height - baseGap,
    );

    const r = 12.0;
    final path = Path()
      ..moveTo(tabRect.left, tabRect.bottom)
      ..lineTo(tabRect.left, tabRect.top + r)
      ..quadraticBezierTo(tabRect.left, tabRect.top, tabRect.left + r, tabRect.top)
      ..lineTo(tabRect.right - r, tabRect.top)
      ..quadraticBezierTo(tabRect.right, tabRect.top, tabRect.right, tabRect.top + r)
      ..lineTo(tabRect.right, tabRect.bottom)
      ..close();

    final shadowPaint = Paint()
      ..color = const Color(0x33000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(path, shadowPaint);

    final fillPaint = Paint()..color = Colors.white.withValues(alpha: 0.10);
    canvas.drawPath(path, fillPaint);

    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, strokePaint);
  }
}
class MedalBadge extends StatelessWidget {
  final int rank;
  final double size;
  const MedalBadge({super.key, required this.rank, this.size = 28});

  @override
  Widget build(BuildContext context) {
    Color base;
    switch (rank) {
      case 1: base = const Color(0xFFFFC107); break;
      case 2: base = const Color(0xFFB0BEC5); break;
      default: base = const Color(0xFFB87333);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base.withValues(alpha:0.95), base.withValues(alpha:0.75)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha:0.6), width: 1),
        boxShadow: [BoxShadow(color: base.withValues(alpha:0.25), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: GoogleFonts.montserrat(
          fontSize: size * 0.5,
          fontWeight: FontWeight.w800,
          color: Colors.black.withValues(alpha:0.80),
        ),
      ),
    );
  }
}
class DaysToMinutesCountDown extends StatefulWidget {
  const DaysToMinutesCountDown({super.key, this.showLabel = true, this.scaleFactor = 1.0});
  final bool showLabel;
  final double scaleFactor;

  @override
  State<DaysToMinutesCountDown> createState() => _DaysToMinutesCountDownState();
}
class _DaysToMinutesCountDownState extends State<DaysToMinutesCountDown> {
  late Timer _timer;
  late String formattedRemaining;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _updateTime());
  }

  void _updateTime() {

    final now = DateTime.now().toUtc();
    final nextFirstOfMonth = DateTime(now.year, now.month + 1, 1);
    final diff = nextFirstOfMonth.difference(now);

    final remainingDays = diff.inDays;
    final remainingHours = diff.inHours % 24;

    setState(() {
      formattedRemaining = '${remainingDays}D ${remainingHours}h';
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    String labelText = '';
    if (widget.showLabel) {
      labelText = '${strings!.get('next') ?? "Next"}: $formattedRemaining';
    }
    else {
      labelText = formattedRemaining;
    }
    return Row(
      children: [
        Text(
          labelText,
          textAlign: TextAlign.right,
          style: GoogleFonts.montserrat(
            fontSize: (14 * widget.scaleFactor).clamp(11.0, 17.0),
            fontWeight: FontWeight.w300,
            color: Colors.white,
          ),
        ),
        SizedBox(width: (4 * widget.scaleFactor).clamp(2.0, 6.0)),
        Icon(
          FontAwesomeIcons.clock,
          size: (16 * widget.scaleFactor).clamp(12.0, 20.0),
          color: Colors.white
        )
      ],
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

class RafflesBuilder extends StatelessWidget {
  final List<RaffleItem> raffleItems;
  final double userPoints;
  final String userId;
  final double scaleFactor;
  final GlobalKey<HomeScreenState> homeScreenKey = GlobalKey<HomeScreenState>();
  final Future<void> Function()? onRaffleSuccess;

  RafflesBuilder({super.key,
    required this.raffleItems,
    required this.userPoints,
    required this.userId,
    this.scaleFactor = 1.0,
    this.onRaffleSuccess,});

  Future<bool?> _showConfirmRaffleDialog(
      BuildContext aContext, RaffleItem raffleItem, double userPoints) async {
    final betraderIcon = await rootBundle.load('assets/new_icon.png');
    final betraderIconBase64 = base64Encode(betraderIcon.buffer.asUint8List());
    return await showDialog<bool>(
      context: aContext,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              Navigator.of(context).pop(false);
            }
          },
          child:
          Dialog(
            elevation: 0,
            backgroundColor: Colors.transparent.withValues(alpha: .15),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white70.withValues(alpha: 0.12), width: 1.2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 14, offset: Offset(0, 4)),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (raffleItem.icon.isNotEmpty)
                        Image.memory(base64Decode(raffleItem.icon), height: 140, fit: BoxFit.fill),
                      const SizedBox(height: 6),
                      Text(
                        raffleItem.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        LocalizedStrings.of(context)!.get('nextRaffleIn') ?? "The next raffle will take place in",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(fontSize: 16, color: Colors.white70),
                      ),
                      StreamBuilder<DateTime>(
                        initialData: DateTime.now().toUtc(),
                        stream: Stream<DateTime>.periodic(const Duration(minutes: 1), (_) => DateTime.now().toUtc()),
                        builder: (context, snapshot) {
                          final now = snapshot.data ?? DateTime.now().toUtc();
                          final target = raffleItem.raffleDate.toUtc();
                          var diff = target.difference(now);
                          if (diff.isNegative) diff = Duration.zero;
                          final d = diff.inDays;
                          final h = diff.inHours % 24;
                          final m = diff.inMinutes % 60;
                          return Text('${d}D ${h}h ${m}m',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white70.withValues(alpha: 0.12), width: 1.0),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 10, offset: Offset(0, 3))],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              (LocalizedStrings.of(context)?.get('participants') ?? "Participants:"),
                              style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              NumberFormat.compact().format(raffleItem.participants),
                              style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            const Icon(FontAwesomeIcons.user, size: 20, color: Colors.white),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(thickness: 1.0, color: Colors.white24, height: 0.2),
                      const SizedBox(height: 8),
                      Text(
                        LocalizedStrings.of(context)?.get('slideToParticipate') ?? 'Slide to participate',
                        maxLines: 1,
                        style: GoogleFonts.syncopate(fontSize: 16, color: Colors.white60, fontWeight: FontWeight.w500),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: SlideToConfirm(
                          disabled: raffleItem.coins > userPoints,
                          icon: betraderIconBase64,
                          betAmount: raffleItem.coins.toDouble(),
                          onSlideComplete: () async {
                            final response = await Common().postRequestWrapper('Info','NewRaffle', {
                              'userId': userId,
                              'itemToken': raffleItem.id.toString(),
                            });
                            if (response['statusCode'] == 200) {
                              Common().vibrate(100,100);
                              await BetsService().getUserInfo(userId);
                              if (onRaffleSuccess != null) await onRaffleSuccess!();
                              Common().showFloatingSnack(context,
                                  LocalizedStrings.of(context)!.get('raffleParticipated') ?? "Raffle participated successfully!"
                              );
                              Navigator.pop(context);
                            } else {
                              Common().vibrate(100,100);
                              Common().showFloatingSnack(context, "Oops... error", backgroundColor: Colors.red);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (raffleItems.isEmpty) {
      return _RafflesSkeletonGrid(scaleFactor: scaleFactor);
    }
    
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final screenAspectRatio = screenWidth / screenHeight;
    final horizontalPadding = (10 * scaleFactor).clamp(6.0, 14.0);
    final crossAxisSpacing = (8 * scaleFactor).clamp(6.0, 10.0);
    final mainAxisSpacing = (8 * scaleFactor).clamp(6.0, 10.0);
    final crossAxisCount = 2;
    
    // Calcular ancho disponible para cada elemento
    final availableWidth = screenWidth - (horizontalPadding * 2) - (crossAxisSpacing * (crossAxisCount - 1));
    final itemWidth = availableWidth / crossAxisCount;
    
    // Calcular altura estimada del contenido del elemento
    final imageHeight = screenHeight * 0.09 * scaleFactor;
    final internalPadding = (8.0 * scaleFactor).clamp(6.0, 10.0) * 2;
    final textHeight = (17 * scaleFactor).clamp(14.0, 20.0) * 1.8;
    final spacingBetweenElements = (3 * scaleFactor).clamp(2.0, 4.0);
    final estimatedItemHeight = imageHeight + internalPadding + textHeight + spacingBetweenElements;
    
    // Calcular childAspectRatio dinámicamente
    // Para pantallas 9:16 (más estrechas), usar aspect ratio más alto para evitar solapamiento
    final baseAspectRatio = itemWidth / estimatedItemHeight;
    // Ajustar según la relación de aspecto de la pantalla
    // Pantallas más altas (9:16) necesitan aspect ratio más alto
    final aspectRatioAdjustment = screenAspectRatio < 0.6 ? 1.15 : 1.0; // 9:16 ≈ 0.5625
    final dynamicAspectRatio = (baseAspectRatio * aspectRatioAdjustment).clamp(1.2, 2.0);
    
    // Calcular padding inferior adicional para evitar que los elementos queden ocultos
    final bottomNavBarHeight = 100.0;
    final extraBottomPadding = bottomNavBarHeight + (12 * scaleFactor).clamp(8.0, 16.0);
    
    // Obtener SafeArea para calcular el espacio disponible
    final safeAreaTop = mediaQuery.padding.top;
    final safeAreaBottom = mediaQuery.padding.bottom;
    
    // Calcular rowExtent y rowGap (mismos valores que en AwardsPage)
    final calculatedRowExtent = (45 * scaleFactor).clamp(35.0, 55.0);
    final calculatedRowGap = (8 * scaleFactor).clamp(6.0, 10.0);
    final visibleItems = 5; // _VISIBLE_ITEMS
    
    // Calcular altura aproximada de los elementos superiores (Top-5 list)
    // Esto incluye: padding superior, tabs, lista de top users, spacing, título de raffles, divider
    final topSectionHeight = (10 * scaleFactor).clamp(6.0, 14.0) + // padding superior
                             48 + // altura aproximada de tabs
                             (calculatedRowExtent * visibleItems + calculatedRowGap * (visibleItems - 1)) + // top users list
                             (16 * scaleFactor).clamp(12.0, 20.0) + // spacing
                             30 + // título "Raffles"
                             1; // divider
    
    // Calcular altura máxima disponible para el GridView
    final maxAvailableHeight = screenHeight - 
                                safeAreaTop - 
                                safeAreaBottom - 
                                topSectionHeight - 
                                extraBottomPadding;
    
    // Calcular número de filas necesarias
    final rowCount = (raffleItems.length / crossAxisCount).ceil();
    final itemHeight = itemWidth / dynamicAspectRatio;
    final topPadding = (8 * scaleFactor).clamp(4.0, 12.0);
    final bottomPadding = (8 * scaleFactor).clamp(4.0, 12.0);
    final totalGridHeight = (itemHeight * rowCount) + (mainAxisSpacing * (rowCount - 1));
    final totalContentHeight = totalGridHeight + topPadding + bottomPadding;
    
    // Si el contenido es más grande que el espacio disponible, ajustar el aspect ratio
    double adjustedAspectRatio = dynamicAspectRatio;
    if (totalContentHeight > maxAvailableHeight && maxAvailableHeight > 0) {
      // Calcular nuevo aspect ratio para que quepa en el espacio disponible
      final availableContentHeight = maxAvailableHeight - topPadding - bottomPadding;
      final maxItemHeight = (availableContentHeight - (mainAxisSpacing * (rowCount - 1))) / rowCount;
      if (maxItemHeight > 0) {
        adjustedAspectRatio = itemWidth / maxItemHeight;
        adjustedAspectRatio = adjustedAspectRatio.clamp(1.2, 2.5);
      }
    }
    
    // Usar la altura mínima entre la calculada y la máxima disponible
    final gridHeight = totalContentHeight > maxAvailableHeight 
        ? maxAvailableHeight 
        : totalContentHeight;
    
    return SizedBox(
      height: gridHeight.clamp(0.0, maxAvailableHeight),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: horizontalPadding,
          right: horizontalPadding,
          top: topPadding,
          bottom: bottomPadding,
        ),
        itemCount: raffleItems.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: adjustedAspectRatio,
        ),
      itemBuilder: (context, index) {
        RaffleItem raffleItem = raffleItems[index];
        final name =  raffleItem.name;
        final shortName = raffleItem.shortName;
        final coins = raffleItem.coins;
        final image = raffleItem.icon;
        final borderRadius = BorderRadius.circular(14);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: () async {
              Common().vibrate();
              Common().applyImmersive();
              _showConfirmRaffleDialog(context, raffleItem, userPoints);
            },
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: borderRadius,
                border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all((8.0 * scaleFactor).clamp(6.0, 10.0)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (image.isNotEmpty)
                    Image.memory(
                      base64Decode(image),
                      height: MediaQuery.of(context).size.height * 0.09 * scaleFactor,
                      fit: BoxFit.fill,
                    ),
                  if (name.isNotEmpty) ...[
                    SizedBox(height: (3 * scaleFactor).clamp(2.0, 4.0)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          shortName,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: (17 * scaleFactor).clamp(14.0, 20.0),
                            fontWeight: FontWeight.w300,
                            color: Colors.white.withValues(alpha: 0.95),
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: " ("),
                              TextSpan(text: NumberFormat.compact().format(coins)),
                              const TextSpan(text: ""),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,

                                child: Padding(
                                  padding: EdgeInsets.zero,
                                  child: Image.asset(
                                    'assets/coin.png',
                                    width: (16 * scaleFactor).clamp(12.0, 20.0),
                                    height: (16 * scaleFactor).clamp(12.0, 20.0),
                                  ),
                                ),
                              ),
                              const TextSpan(text: ")"),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: (17 * scaleFactor).clamp(14.0, 20.0),
                            fontWeight: FontWeight.w300,
                            color: Colors.white.withValues(alpha: 0.95),
                            letterSpacing: 0.2,
                          ),
                        ),

                      ],
                    )
                  ],
                ],
              ),
            ),
          ),
        );

      },
        ),
      );
  }
}

//-------------------------- S K E L E T O N S --------------------------

class _TopUsersSkeleton extends StatelessWidget {
  final int count;
  final double rowExtent;
  final double gap;

  const _TopUsersSkeleton({
    required this.count,
    required this.rowExtent,
    required this.gap,
  });

  static const _pool = <String>[
    'donsuso','estacionvictoria','Ovu','rokusso','pepe',
    'cryptogato','lunaTrader','moriarty','neonbyte','alfaWolf',
    'pixelito','kiwix','zenith','solanito','nox','bitmaria',
    'ramenking','asturcoin','pampamon','quarky'
  ];



  String _nameFor(int i) {
    final r = Random(i + 13);
    final base = _pool[i % _pool.length];
    if (r.nextBool() && base.length > 10) {
      return '${base.substring(0, 12)}...';
    }
    return base;
  }

  String _coinsFor(int i) {
    final r = Random(1000 + i);
    final value = r.nextInt(900000) + 8000;
    return NumberFormat.compact().format(value);
  }

  @override
  Widget build(BuildContext context) {
    const double sigmaName = 3;
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: count,
      separatorBuilder: (_, __) => SizedBox(height: gap),
      itemBuilder: (_, index) {
        final rank = index + 1;
        final prize = rank <= Config.top5Rewards.length ? Config.top5Rewards[rank - 1] : '';

        return Container(
          height: rowExtent,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 45,
                child: (rank <= 3)
                    ? MedalBadge(rank: rank, size: 30)
                    : Text(
                  '$rank',
                  style: GoogleFonts.syncopate(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),

              Expanded(
                child: ClipRect(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: sigmaName, sigmaY: sigmaName),
                    child: Text(
                      _nameFor(index),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.95),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),

              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.white.withValues(alpha: 0.12),
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _coinsFor(index),
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Image.asset('assets/coin.png', width: 18, height: 18),
                  Container(
                    width: 1,
                    height: 24,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  if (prize.isNotEmpty)
                    Text(
                      prize,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RafflesSkeletonGrid extends StatelessWidget {
  final double scaleFactor;
  const _RafflesSkeletonGrid({this.scaleFactor = 1.0});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final screenAspectRatio = screenWidth / screenHeight;
    final horizontalPadding = (10 * scaleFactor).clamp(6.0, 14.0);
    final crossAxisSpacing = (8 * scaleFactor).clamp(6.0, 10.0);
    final mainAxisSpacing = (8 * scaleFactor).clamp(6.0, 10.0);
    final crossAxisCount = 2;
    
    // Calcular ancho disponible para cada elemento
    final availableWidth = screenWidth - (horizontalPadding * 2) - (crossAxisSpacing * (crossAxisCount - 1));
    final itemWidth = availableWidth / crossAxisCount;
    
    // Calcular altura estimada del contenido del elemento
    final imageHeight = screenHeight * 0.09 * scaleFactor;
    final internalPadding = (8.0 * scaleFactor).clamp(6.0, 10.0) * 2;
    final textHeight = (17 * scaleFactor).clamp(14.0, 20.0) * 1.8;
    final spacingBetweenElements = (6 * scaleFactor).clamp(4.0, 8.0);
    final estimatedItemHeight = imageHeight + internalPadding + textHeight + spacingBetweenElements;
    
    // Calcular childAspectRatio dinámicamente
    // Para pantallas 9:16 (más estrechas), usar aspect ratio más alto para evitar solapamiento
    final baseAspectRatio = itemWidth / estimatedItemHeight;
    // Ajustar según la relación de aspecto de la pantalla
    // Pantallas más altas (9:16) necesitan aspect ratio más alto
    final aspectRatioAdjustment = screenAspectRatio < 0.6 ? 1.15 : 1.0; // 9:16 ≈ 0.5625
    final dynamicAspectRatio = (baseAspectRatio * aspectRatioAdjustment).clamp(1.2, 2.0);
    
    // Calcular padding inferior adicional para evitar que los elementos queden ocultos
    final bottomNavBarHeight = 100.0;
    final extraBottomPadding = bottomNavBarHeight + (12 * scaleFactor).clamp(8.0, 16.0);
    
    // Usar MediaQuery para obtener la altura real de la pantalla
    final safeAreaTop = mediaQuery.padding.top;
    final safeAreaBottom = mediaQuery.padding.bottom;
    
    // Calcular rowExtent y rowGap (mismos valores que en AwardsPage)
    final calculatedRowExtent = (45 * scaleFactor).clamp(35.0, 55.0);
    final calculatedRowGap = (8 * scaleFactor).clamp(6.0, 10.0);
    final visibleItems = 5; // _VISIBLE_ITEMS
    
    // Calcular altura aproximada de los elementos superiores (Top-5 list)
    final topSectionHeight = (10 * scaleFactor).clamp(6.0, 14.0) + // padding superior
                             48 + // altura aproximada de tabs
                             (calculatedRowExtent * visibleItems + calculatedRowGap * (visibleItems - 1)) + // top users list
                             (16 * scaleFactor).clamp(12.0, 20.0) + // spacing
                             30 + // título "Raffles"
                             1; // divider
    
    // Calcular altura máxima disponible para el GridView
    final maxAvailableHeight = screenHeight - 
                                safeAreaTop - 
                                safeAreaBottom - 
                                topSectionHeight - 
                                extraBottomPadding;
    
    // Calcular número de filas necesarias (4 items = 2x2)
    final rowCount = 2;
    final itemHeight = itemWidth / dynamicAspectRatio;
    final topPadding = (8 * scaleFactor).clamp(4.0, 12.0);
    final bottomPadding = (8 * scaleFactor).clamp(4.0, 12.0);
    final totalGridHeight = (itemHeight * rowCount) + (mainAxisSpacing * (rowCount - 1));
    final totalContentHeight = totalGridHeight + topPadding + bottomPadding;
    
    // Si el contenido es más grande que el espacio disponible, ajustar el aspect ratio
    double adjustedAspectRatio = dynamicAspectRatio;
    if (totalContentHeight > maxAvailableHeight && maxAvailableHeight > 0) {
      // Calcular nuevo aspect ratio para que quepa en el espacio disponible
      final availableContentHeight = maxAvailableHeight - topPadding - bottomPadding;
      final maxItemHeight = (availableContentHeight - (mainAxisSpacing * (rowCount - 1))) / rowCount;
      if (maxItemHeight > 0) {
        adjustedAspectRatio = itemWidth / maxItemHeight;
        adjustedAspectRatio = adjustedAspectRatio.clamp(1.2, 2.5);
      }
    }
    
    // Usar la altura mínima entre la calculada y la máxima disponible
    final gridHeight = totalContentHeight > maxAvailableHeight 
        ? maxAvailableHeight 
        : totalContentHeight;
    
    return SizedBox(
      height: gridHeight.clamp(0.0, maxAvailableHeight),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: horizontalPadding,
          right: horizontalPadding,
          top: topPadding,
          bottom: bottomPadding,
        ),
        itemCount: 4, // 2x2 placeholder
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: adjustedAspectRatio,
        ),
      itemBuilder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular((14 * scaleFactor).clamp(10.0, 18.0)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all((8 * scaleFactor).clamp(6.0, 10.0)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.09 * scaleFactor,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              SizedBox(height: (6 * scaleFactor).clamp(4.0, 8.0)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: (80 * scaleFactor).clamp(60.0, 100.0),
                    height: (14 * scaleFactor).clamp(11.0, 17.0),
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  SizedBox(width: (6 * scaleFactor).clamp(4.0, 8.0)),
                  Container(
                    width: (50 * scaleFactor).clamp(40.0, 60.0),
                    height: (14 * scaleFactor).clamp(11.0, 17.0),
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ],
              ),
            ],
          ),
        );
      },
        ),
      );
  }
}