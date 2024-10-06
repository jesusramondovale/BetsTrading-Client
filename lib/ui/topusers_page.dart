import 'package:betrader/locale/localized_texts.dart';
import 'package:flutter/material.dart';
import 'package:betrader/services/TopService.dart';
import 'package:betrader/models/users.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helpers/common.dart';

class TopUsersPage extends StatefulWidget {
  @override
  _TopUsersPageState createState() => _TopUsersPageState();
}

class _TopUsersPageState extends State<TopUsersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String _userId = "none";
  String _userCountry = "none";

  Future<void> _loadUserIdAndData() async {
    final userId = await _storage.read(key: "sessionToken") ?? "none";
    final userCountry = await _storage.read(key: "country") ?? "none";

    setState(() {
      _userId = userId;
      _userCountry = userCountry;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserIdAndData();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void popUserDialog(BuildContext context, User user) {
    showGeneralDialog(
      context: context,
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return UserDialog(user: user);
      },
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            )),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Rankings',
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.w400,
            )),
        bottom: TabBar(
          labelStyle: GoogleFonts.comfortaa(
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
          controller: _tabController,
          tabs: [
            Tab(text: strings!.worldwide ?? 'Worldide'),
            Tab(text: strings.yourCountry ?? 'Your Country'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTopUsersView(),
          _buildTopUsersByCountryView(),
        ],
      ),
    );
  }

  Widget _buildTopUsersView() {
    return FutureBuilder<List<User>>(
      future: TopService().fetchTopUsers(_userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Icon(Icons.no_accounts, size: 180));
        } else {
          List<User> users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              User user = users[index];
              return InkWell(
                onTap: () {
                  popUserDialog(context, user);
                },
                child: Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  elevation: 5,
                  child: ListTile(
                    contentPadding: EdgeInsets.all(10.0),
                    leading: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: Common().getProfileImage(user.profilePic),
                        ),
                        if (index == 0)
                          Positioned(
                            top: 0,
                            left: 0,
                            child: _buildTopBadge(
                                Icons.emoji_events, Colors.amber),
                          )
                        else if (index == 1)
                          Positioned(
                            top: 0,
                            left: 0,
                            child:
                                _buildTopBadge(Icons.emoji_events, Colors.grey),
                          )
                        else if (index == 2)
                          Positioned(
                            top: 0,
                            left: 0,
                            child: _buildTopBadge(
                                Icons.emoji_events, Colors.brown),
                          ),
                      ],
                    ),
                    title: Text(
                      user.username,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${user.points}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 4),
                        Container(
                            margin: EdgeInsets.fromLTRB(0, 5, 0, 10),
                            child: Text(
                              '\u0e3f',
                              style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w100,
                                  color: Colors.yellowAccent),
                            )
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildTopUsersByCountryView() {
    return FutureBuilder<List<User>>(
      future: TopService().fetchTopUsersByCountry(_userCountry),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Icon(Icons.no_accounts, size: 180));
        } else {
          List<User> users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              User user = users[index];
              return InkWell(
                onTap: () {
                  popUserDialog(context, user);
                },
                child: Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  elevation: 5,
                  child: ListTile(
                    contentPadding: EdgeInsets.all(10.0),
                    leading: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: Common().getProfileImage(user.profilePic),
                        ),
                        if (index == 0)
                          Positioned(
                            top: 0,
                            left: 0,
                            child: _buildTopBadge(
                                Icons.emoji_events, Colors.amber),
                          )
                        else if (index == 1)
                          Positioned(
                            top: 0,
                            left: 0,
                            child:
                            _buildTopBadge(Icons.emoji_events, Colors.grey),
                          )
                        else if (index == 2)
                            Positioned(
                              top: 0,
                              left: 0,
                              child: _buildTopBadge(
                                  Icons.emoji_events, Colors.brown),
                            ),
                      ],
                    ),
                    title: Text(
                      user.username,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${user.points}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 4),
                        Container(
                            margin: EdgeInsets.fromLTRB(0, 5, 0, 10),
                            child: Text(
                              '\u0e3f',
                              style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w100,
                                  color: Colors.yellowAccent),
                            )
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildTopBadge(IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 16.0,
      ),
    );
  }
}
