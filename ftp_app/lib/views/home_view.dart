import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:ftp_app/views/settings_view.dart';

const String loadNBAGames = 'https://getnbagames-kca5bali4a-uc.a.run.app';

Future<List<Game>> fetchGames() async {
  final response = await http.get(Uri.parse(loadNBAGames));

  if (response.statusCode == 200) {
    Iterable gamesList = json.decode(response.body);
    return gamesList.map((game) => Game.fromJson(game)).toList();
  } else {
    throw Exception('Failed to load games');
  }
}

class Game {
  final String team1;
  final String team2;
  final DateTime date;

  Game({required this.team1, required this.team2, required this.date});

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      team1: json['home'],
      team2: json['away'],
      date: DateTime.parse(json['date']),
    );
  }
}

class SportsbookHomeScreen extends StatefulWidget {
  @override
  _SportsbookHomeScreenState createState() => _SportsbookHomeScreenState();
}

class _SportsbookHomeScreenState extends State<SportsbookHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomeView(),
    SettingsScreen(),
    SocialFeedScreen(),
    SimulatorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sportsbook App'),
        backgroundColor: Colors.blue,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rss_feed),
            label: 'Social Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports),
            label: 'Simulator',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  Future<List<Game>> futureGames = fetchGames();

  @override
  void initState() {
    super.initState();
    futureGames = fetchGames();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('NBA Games')),
      body: FutureBuilder<List<Game>>(
        future: futureGames,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            List<Game> games = snapshot.data ?? [];
            return ListView.builder(
              itemCount: games.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('${games[index].team1} vs ${games[index].team2}'),
                  subtitle: Text(games[index].date.toIso8601String()),
                );
              },
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SettingsView();
  }
}

class SocialFeedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Social Feed Screen'),
    );
  }
}

class SimulatorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Simulator Screen'),
    );
  }
}
