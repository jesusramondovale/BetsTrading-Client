import 'dart:convert';

import 'package:betrader/locale/localized_texts.dart';
import 'package:flutter/material.dart';
import 'package:betrader/services/TopService.dart';
import 'package:betrader/models/users.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class TopUsersPage extends StatefulWidget {

  @override
  _TopUsersPageState createState() => _TopUsersPageState();
}

class _TopUsersPageState extends State<TopUsersPage> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Rankings',
            style : GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.w400,
            )
        ),
        bottom: TabBar(
          labelStyle:
          GoogleFonts.comfortaa(
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
          return Center(child: Icon(Icons.no_accounts , size: 180));
        } else {
          List<User> users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              User user = users[index];
              return Card(
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
                        backgroundImage: _getProfileImage(user.profilePic),
                      ),
                      if (index == 0)
                        Positioned(
                          top: 0,
                          left: 0,
                          child: _buildTopBadge(Icons.emoji_events, Colors.amber),
                        )
                      else if (index == 1)
                        Positioned(
                          top: 0,
                          left: 0,
                          child: _buildTopBadge(Icons.emoji_events, Colors.grey),
                        )
                      else if (index == 2)
                          Positioned(
                            top: 0,
                            left: 0,
                            child: _buildTopBadge(Icons.emoji_events, Colors.brown),
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
                      Icon(Icons.monetization_on, color: Colors.yellowAccent),
                    ],
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
          return Center(child: Icon(Icons.no_accounts , size: 180));
        } else {
          List<User> users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              User user = users[index];
              return Card(
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
                        backgroundImage: _getProfileImage(user.profilePic),
                      ),
                      if (index == 0)
                        Positioned(
                          top: 0,
                          left: 0,
                          child: _buildTopBadge(Icons.emoji_events, Colors.amber),
                        )
                      else if (index == 1)
                        Positioned(
                          top: 0,
                          left: 0,
                          child: _buildTopBadge(Icons.emoji_events, Colors.grey),
                        )
                      else if (index == 2)
                          Positioned(
                            top: 0,
                            left: 0,
                            child: _buildTopBadge(Icons.emoji_events, Colors.brown),
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
                      Icon(Icons.monetization_on, color: Colors.yellowAccent),
                    ],
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

  ImageProvider _getProfileImage(String? profilePic) {
    if (profilePic != null) {
      if (profilePic.startsWith('https')) {
        return NetworkImage(profilePic);
      } else {
        return MemoryImage(base64Decode(profilePic));
      }
    } else {
      return MemoryImage(base64Decode('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TU0AKgAAABBFeGlmTWV0YQAEARoABQAAAAEAAABGARsABQAAAAEAAABOASgAAwAAAAEAAgAAAhMAAwAAAAEAAQAAAAAAAAAAASwAAAABAAABLAAAAAFYTVAg1wMAADw/eHBhY2tldCBiZWdpbj0n77u/JyBpZD0nVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkJz8+Cjx4OnhtcG1ldGEgeG1sbnM6eD0nYWRvYmU6bnM6bWV0YS8nIHg6eG1wdGs9J0ltYWdlOjpFeGlmVG9vbCAxMS44OCc+CjxyZGY6UkRGIHhtbG5zOnJkZj0naHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyc+CgogPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9JycKICB4bWxuczp0aWZmPSdodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyc+CiAgPHRpZmY6UmVzb2x1dGlvblVuaXQ+MjwvdGlmZjpSZXNvbHV0aW9uVW5pdD4KICA8dGlmZjpYUmVzb2x1dGlvbj4zMDAvMTwvdGlmZjpYUmVzb2x1dGlvbj4KICA8dGlmZjpZUmVzb2x1dGlvbj4zMDAvMTwvdGlmZjpZUmVzb2x1dGlvbj4KIDwvcmRmOkRlc2NyaXB0aW9uPgoKIDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PScnCiAgeG1sbnM6eG1wPSdodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvJz4KICA8eG1wOkNyZWF0b3JUb29sPkFkb2JlIFN0b2NrIFBsYXRmb3JtPC94bXA6Q3JlYXRvclRvb2w+CiA8L3JkZjpEZXNjcmlwdGlvbj4KCiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0nJwogIHhtbG5zOnhtcE1NPSdodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vJz4KICA8eG1wTU06RG9jdW1lbnRJRD54bXAuaWlkOjJhY2VhNDcxLTRjOWMtNGNjNC05YzhmLThlOTM4OWY5NjA0MDwveG1wTU06RG9jdW1lbnRJRD4KICA8eG1wTU06SW5zdGFuY2VJRD5hZG9iZTpkb2NpZDpzdG9jazphNzdmMDNlYi01YTJjLTQ1MWItODJjOS0wOTZkODU5YjJiNzM8L3htcE1NOkluc3RhbmNlSUQ+CiAgPHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD5hZG9iZTpkb2NpZDpzdG9jazo1ODk5MzI3ODI8L3htcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD4KIDwvcmRmOkRlc2NyaXB0aW9uPgo8L3JkZjpSREY+CjwveDp4bXBtZXRhPgo8P3hwYWNrZXQgZW5kPSd3Jz8+AA=='));
    }
  }

}
