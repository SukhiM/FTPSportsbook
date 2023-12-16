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

import 'package:cloud_firestore/cloud_firestore.dart';

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
    BuildContext context, Game selectedGame, String teamName, num probability) async {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (context) =>
        PlaceBetScreen(selectedGame: selectedGame, selectedTeam: teamName, odds: probability),
  ));
}

// Function to return winning team and probability of said win between two given teams
// Future<Map<String, dynamic>?> fetchOdds(
//     String homeTeam, String awayTeam) async {
//   try {
//     // Assuming you have 'predictions' as a top-level collection
//     // and 'awayTeams' as a subcollection inside each home team document
//     DocumentSnapshot predictionSnapshot = await FirebaseFirestore.instance
//         .collection('predictions')
//         .doc(homeTeam)
//         .collection('AWAYTEAMS')
//         .doc(awayTeam)
//         .get();

//     if (predictionSnapshot.exists) {
//       return predictionSnapshot.data() as Map<String, dynamic>;
//     } else {
//       // Handle the case where there is no prediction
//       print("No prediction available for this matchup.");
//       return null;
//     }
//   } catch (e) {
//     // Handle any errors that occur during the Firestore query
//     print("Error simulating game: $e");
//     return null;
//   }
// }

Future<num> fetchOdds(String teamName) async {
  DateTime today = DateTime.now();
  String formattedDate = DateFormat('yyyy-MM-dd').format(today);
  QuerySnapshot predictionSnapshot = await FirebaseFirestore.instance
      .collection('nba_games')
      .doc(formattedDate)
      .collection('games')
      .get();

  for (var document in predictionSnapshot.docs) {
    String homeTeam = document.get('home');
    String awayTeam = document.get('away');

    if (teamName == homeTeam){
      return document.get('homeOdds');
    }
    if (teamName == awayTeam){
      return document.get('awayOdds');
    }
  }

  return 0; // Failed to fetch data
}



// Calculate odds 
// Future<double> calculateWinningProbability(
//     String homeTeam, String awayTeam) async {
//   final odds = await fetchOdds(homeTeam, awayTeam);

//   if (odds == null) {
//     return 0.0;
//   }

//   // Determine the winning team based on 'predictedWinner'
//   final winningTeam = odds["predictedWinner"];

//   // Extract the probability for home team and away team
//   final probability = winningTeam == homeTeam ? odds["probability"] : 100.00 - odds["probability"];
//   print("WInning team");
//   print(winningTeam);
//   print("Home Team: ");
//   print(homeTeam);
//   print("Probability:");
//   print(probability);
//   print(100.0 - probability);
//   return probability;
// }


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

    var odds = fetchOdds(teamName);
    //var homeProbabilityFuture = calculateWinningProbability(game.team1, game.team2);
    //var awayProbabilityFuture = calculateWinningProbability(game.team2, game.team1);
    //var winningTeam = isHomeTeam ? homeProbabilityFuture : awayProbabilityFuture; // Send correct team probability to PlaceBetPopup

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
              // num probability = await winningTeam;
              // Show the popup
              num probability = await odds;
              await _showPlaceBetPopup(context, game, teamName, probability);
            }
            : null, // Disables the button if the status is null or closed
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
          child: FutureBuilder<List<num>>(
            future: Future.wait([fetchOdds(game.team1), fetchOdds(game.team2)]),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final num team1 = snapshot.data![0];
                final num team2 = snapshot.data![1];
                return Text(
                  isHomeTeam
                      ? 'Odds: ${team1}'
                      : 'Odds: ${team2}',
                );
              } else {
                return Text('...'); // Loading indicator
              }
            },
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
