import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_date_pickers/flutter_date_pickers.dart';

import 'package:flutter_svg/flutter_svg.dart';

import 'package:ftp_app/views/settings_view.dart';

const String loadNBAGames = 'https://getnbagames-kca5bali4a-uc.a.run.app/';
Future<List<Game>> fetchGames([DateTime? date]) async {
  Map<String, String> requestBody = {
    "date": DateFormat('yyyy-MM-dd').format(date ?? DateTime.now())
  };

  print(jsonEncode(requestBody));

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

String formatGameTime(DateTime date) {
  return DateFormat('h:mm a').format(date);
}

void _placeBet(String team, double amount) async {
  // Your logic to make the HTTP request goes here.
  // For example:
  //
  // final response = await http.post(
  //   Uri.parse('YOUR_API_ENDPOINT'),
  //   body: {'team': team, 'amount': amount.toString()},
  // );
  //
  // Check response, handle errors, etc.
  print('Placing bet of $amount on $team');
}

Future<void> _showBetAmountDialog(BuildContext context, String team) async {
  TextEditingController _amountController = TextEditingController();

  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text('Place bet on $team'),
        content: TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: "Enter amount",
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
          TextButton(
            child: Text('Confirm'),
            onPressed: () {
              // Handle bet confirmation
              _placeBet(team, double.tryParse(_amountController.text) ?? 0.0);
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      );
    },
  );
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
    String assetName =
        'assets/logos/$teamName.svg'; // Construct the asset name dynamically
    return SvgPicture.asset(assetName,
        height: 24, width: 24); // Adjust the size as needed
  }

  Widget _teamRow(Game game, bool isHomeTeam) {
    String teamName = isHomeTeam ? game.team1 : game.team2;
    String assetName =
        'assets/logos/$teamName.svg'; // Assuming team name matches the SVG filename

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          // Use nested row for logo and team name side by side
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0), // Adjust this value for more/less padding
              child: SvgPicture.asset(
                assetName,
                width: 24, // You can adjust these values
                height: 24, // You can adjust these values
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(width: 8), // Some spacing between logo and team name
            Text(teamName),
          ],
        ),
        ElevatedButton(
          onPressed: () => _showBetAmountDialog(context, teamName),
          child: Text("Bet"),
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              DateFormat('MMMM d, y').format(_selectedDate),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

                  // This is the updated ListView.builder
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
                                  formatGameTime(games[index].date),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _selectDate(context),
        child: Icon(Icons.calendar_today),
        tooltip: 'Select Date',
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
