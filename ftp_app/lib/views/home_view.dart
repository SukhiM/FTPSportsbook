import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_svg/flutter_svg.dart';

import 'package:ftp_app/models/game.dart';

import 'package:ftp_app/views/place_bet_view.dart';
import 'package:ftp_app/views/settings_view.dart';
import 'package:ftp_app/views/feed_view.dart';
import 'package:ftp_app/views/simulate_view.dart';

const String loadNBAGames = 'https://getnbagames-kca5bali4a-uc.a.run.app/';

Future<List<Game>> fetchGames([DateTime? date]) async {
  Map<String, String> requestBody = {
    "date": DateFormat('yyyy-MM-dd').format(date ?? DateTime.now())
  };

  print(jsonEncode(requestBody)); // Debugging print

  final response = await http.post(Uri.parse(loadNBAGames),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody));

  if (response.statusCode == 200) {
    Iterable gamesList = json.decode(response.body);
    return gamesList.map((game) => Game.fromJson(game)).toList();
  } else {
    throw Exception('Failed to load games');
  }
}

String formatGameTime(DateTime utcDateTime) {
  // Convert the UTC DateTime to the EST
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('America/New_York'));

  final estLocation = tz.getLocation('America/New_York');
  final estDateTime = tz.TZDateTime.from(utcDateTime, estLocation);

  return DateFormat('h:mm a').format(estDateTime);
}

Future<void> _showPlaceBetPopup(
    BuildContext context, Game selectedGame, String teamName) async {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (context) =>
        PlaceBetScreen(selectedGame: selectedGame, selectedTeam: teamName),
  ));
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
        title: Text('For the People Sportsbook'),
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
  DateTime _selectedDate = DateTime.now();
  Future<List<Game>> futureGames = fetchGames();

  void _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2024),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        futureGames = fetchGames(
            _selectedDate); // Refetch the games for the selected date
      });
    }
  }

  @override
  void initState() {
    super.initState();
    futureGames = fetchGames();
  }

  Widget _teamLogo(String teamName) {
    String assetName = 'assets/logos/$teamName.svg';
    return SvgPicture.asset(assetName,
        height: 24, width: 24); // Adjust the size as needed
  }

  Widget _teamRow(Game game, bool isHomeTeam) {
    String teamName = isHomeTeam ? game.team1 : game.team2;
    String gameStatus = game.status;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Padding(
                padding: const EdgeInsets.only(right: 5.0, left: 5.0, top: 10.0, bottom: 10.0),
                child: _teamLogo(teamName)),
            SizedBox(width: 20),
            Text(teamName)
          ],
        ),
        ElevatedButton(
          onPressed: (gameStatus == 'scheduled')
            ? () async {
              // Show the popup
              await _showPlaceBetPopup(context, game, teamName);
            }
            : null, // Disables the button if the status is null or closed
          child: Text('Place a Bet'),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.disabled)) {
                  return Colors.grey; // Disables color
                }
                return Colors.blue; // Themed color, different than text color
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('NBA Games')),
      body: Column(
        children: [
          ListTile(
            subtitle: InkWell(
              onTap: () => _selectDate(context),
              child: Text(
                DateFormat('MMMM d, y').format(_selectedDate),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: () => _selectDate(context),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Game>>(
              future: futureGames,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  List<Game> games = snapshot.data ?? [];

                  if (games.isEmpty) {
                    return Center(child: Text('No games scheduled'));
                  }

                  return ListView.builder(
                    itemCount: games.length,
                    itemBuilder: (context, index) {
                      return Container(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        margin: EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[300], // light grey
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Column(
                          children: [
                            _teamRow(games[index], true),
                            _teamRow(games[index], false),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  formatGameTime(games[index].time),
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          )
        ],
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
    return SocialFeed();
  }
}

class SimulatorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SimulatorView();
  }
}
