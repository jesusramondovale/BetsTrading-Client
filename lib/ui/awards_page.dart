import 'dart:math';
import 'package:betrader/locale/localized_texts.dart';
import 'package:flutter/material.dart';
import 'package:betrader/services/TopService.dart';
import 'package:betrader/models/users.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../helpers/common.dart';
import '../models/raffle_items.dart';

class AwardsPage extends StatefulWidget {
  const AwardsPage({super.key});

  @override
  State<AwardsPage> createState() => _AwardsPageState();
}

class _AwardsPageState extends State<AwardsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _userId;
  String _userCountry = "none";
  List<Map<String, dynamic>> _raffleItems = [];
  static const double _ROW_EXTENT = 45;
  static const double _ROW_GAP = 8;
  static const double _TABS_BLOCK = kTextTabBarHeight + 8;
  static const double _LABEL_HEIGHT = 5;
  static const double _VERTICAL_PADDING = 6;
  static const int _VISIBLE_ITEMS = 5;
  static const List<String> _REWARDS = [
    r'+$2,500', r'+$1,500', r'$+1,000', r'+$750', r'+$500'
  ];

  double _adaptiveAwardsHeight(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final desired = _VERTICAL_PADDING
        + _LABEL_HEIGHT
        + _TABS_BLOCK
        + (_ROW_EXTENT * _VISIBLE_ITEMS)
        + (_ROW_GAP * (_VISIBLE_ITEMS - 1));
    return desired.clamp(0, screenH * 0.9);
  }

  Future<void> _loadUserIdAndData() async {
    final userId = await _storage.read(key: "sessionToken") ?? "none";
    final userCountry = await _storage.read(key: "country") ?? "none";
    final raffleItemsResponse = await Common().postRequestWrapper(
      'Info',
      'RiffleItems',
      {'user_id': userId},
    );
    if (!mounted) return;
    setState(() {
      _userId = userId;
      _userCountry = userCountry;
      _raffleItems = List<Map<String, dynamic>>.from(raffleItemsResponse['body'] as Iterable);
    });
  }

  Widget _buildUserRow(User user, int index) {
    final rank = index + 1;
    final prize = (rank <= _REWARDS.length) ? _REWARDS[rank - 1] : '';

    final borderRadius = BorderRadius.circular(14);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: () {
          Common().vibrate();
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 45,
                child: Row(
                  children: [
                    if (rank <= 3) ...[
                      MedalBadge(rank: rank, size: 30),
                    ] else ...[
                      Text(
                        '$rank',
                        style: GoogleFonts.syncopate(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha:0.9),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Centro: username
              Expanded(
                child: Text(
                  user.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha:0.95),
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.white.withValues(alpha:0.12),
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    NumberFormat.compact().format(user.points),
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha:0.95),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Image.asset('assets/coin.png', width: 18, height: 18),
                  Container(
                    width: 1,
                    height: 24,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: Colors.white.withValues(alpha:0.12),
                  ),
                  if (prize.isNotEmpty) ...[
                    Text(
                      prize,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha:0.95),
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

  Widget _buildTopUsersView({userCountry = null}) {
    return _userId == null
        ? const Center(child: CircularProgressIndicator(color: Colors.grey))
        : FutureBuilder<List<User>>(
      future: (userCountry != null ? TopService().fetchTopUsersByCountry(userCountry) : TopService().fetchTopUsers(_userId ?? "none")),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Icon(Icons.no_accounts, size: 120));
        } else {
          final users = snapshot.data!;
          final count = min(_VISIBLE_ITEMS, users.length);

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: count,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            separatorBuilder: (_, __) => SizedBox(height: _ROW_GAP),
            itemBuilder: (_, i) => SizedBox(
              height: _ROW_EXTENT,
              child: _buildUserRow(users[i], i),
            ),
          );
        }
      },
    );
  }

  void popUserDialog(BuildContext context, User user) {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, a, b) => UserDialog(user: user),
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserIdAndData();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    final topHeight = _adaptiveAwardsHeight(context);

    return SizedBox(
      height: topHeight,
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsetsGeometry.fromLTRB(6,0,6,0),
              child:  Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _FolderTabs(
                      controller: _tabController,
                      tabs: [
                        strings?.get('worldwide') ?? 'Worldwide',
                        strings?.get('yourCountry') ?? 'Your Region',
                      ],
                      leadingLabel: strings?.get('awards') ?? 'Awards',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: _ROW_EXTENT * _VISIBLE_ITEMS
                        + _ROW_GAP * (_VISIBLE_ITEMS - 1),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTopUsersView(),
                        _buildTopUsersView(userCountry: _userCountry),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  // ---------------------
                  Row(
                    children: [
                      Text(
                        strings?.get('awards') ?? 'Awards',
                        style: GoogleFonts.syncopate(
                            fontSize: 18, fontWeight: FontWeight.w200),
                      ),
                      Spacer(),
                    ],
                  ),
                  Divider(color: Colors.white, thickness: 0.5, height: 0.5),
                  //TODO: RafflesBuilder(),
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
    super.dispose();
  }
}

//TODO
class RafflesBuilder { }

class _FolderTabs extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;
  final String leadingLabel;

  const _FolderTabs({
    required this.controller,
    required this.tabs,
    required this.leadingLabel,
  });

  @override
  Widget build(BuildContext context) {
    const double barHeight = kTextTabBarHeight;
    const double horizontalPadding = 12;

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
                  padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Text(
                    'Top-5',
                    style: GoogleFonts.syncopate(
                      fontSize: 26,
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
                    labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                    indicatorSize: TabBarIndicatorSize.tab,
                    overlayColor: WidgetStatePropertyAll(
                      Colors.white.withValues(alpha: 0.02),
                    ),
                    labelStyle: GoogleFonts.comfortaa(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: GoogleFonts.comfortaa(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicator: const _FolderIndicator(),
                    tabs: tabs
                        .map(
                          (t) => Tab(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 2),
                          child: Text(t),
                        ),
                      ),
                    )
                        .toList(),
                  ),
                  const SizedBox(width: horizontalPadding),
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
      ..color = const Color(0x33000000)   // más tenue
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

