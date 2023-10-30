import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_date_pickers/flutter_date_pickers.dart';

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
        futureGames = fetchGames(); // Refetch the games for the selected date
      });
    }
  }

  @override
  void initState() {
    super.initState();
    futureGames = fetchGames();
  }

  Widget _teamRow(BuildContext context, String team, DateTime gameDate) {
    return ListTile(
      title: Text(team),
      subtitle:
          Text(DateFormat('hh:mm a').format(gameDate)), // Display the game time
      trailing: ElevatedButton(
        onPressed: () => _showBetAmountDialog(context, team),
        child: Text('Bet'),
      ),
    );
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
                return Card(
                  // Using Card to give it a distinct look. You can use Container or any other widget.
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  color: Color(0xFFE5E5DC),
                  child: Column(
                    children: [
                      _teamRow(context, games[index].team1, games[index].date),
                      Divider(), // visually separate the teams
                      _teamRow(context, games[index].team2, games[index].date),
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
