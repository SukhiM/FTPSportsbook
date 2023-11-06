import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

String formatTimestamp(Timestamp timestamp) {
  DateTime dateTime = timestamp.toDate(); // Convert to DateTime object

  // Optionally, adjust the dateTime to the EST timezone
  // DateTime estDateTime = dateTime.subtract(const Duration(hours: 5)); // EST is UTC-5

  // For accurate timezone conversion considering Daylight Saving Time
  // you might need to use a third-party package like 'timezone' to handle this properly
  // For example:
  // final easternTimeZone = getLocation('America/New_York');
  // final estDateTime = TZDateTime.from(dateTime, easternTimeZone);

  // Create a new DateFormat object and use it to format the DateTime object
  DateFormat formatter = DateFormat('MM-dd-yyyy HH:mm');
  return formatter.format(dateTime); // Format it to MM-dd-yyyy HH:mm
}

Future<String> createMatchupString(String gameID) async {
  // This will perform a collection group query across all 'games' subcollections
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collectionGroup('games')
      .where(FieldPath.documentId, isEqualTo: gameID)
      .get();

  if (querySnapshot.docs.isNotEmpty) {
    // Assuming the game document has 'team1' and 'team2' fields
    Map<String, dynamic> gameData =
        querySnapshot.docs.first.data() as Map<String, dynamic>;
    String team1 = gameData['team1'];
    String team2 = gameData['team2'];

    // Create the matchup string
    String matchup = "$team1 @ $team2";

    return matchup;
  } else {
    // Handle the case where the game document does not exist
    throw Exception('Game not found');
  }
}

class BetHistoryCard extends StatelessWidget {
  final String teamBetOn;
  final double amount;
  final String matchup;
  final DateTime betPlacedDate;

  BetHistoryCard({
    required this.teamBetOn,
    required this.amount,
    required this.matchup,
    required this.betPlacedDate,
  });

  @override
  Widget build(BuildContext context) {
    // For formatting date and time in a readable format
    final DateFormat dateFormat = DateFormat('MM-dd-yyyy');
    final DateFormat timeFormat = DateFormat('hh:mm a');

    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$teamBetOn to Win',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              'Amount Wagered: \$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              '$matchup',
              style: TextStyle(
                fontSize: 16.0,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              '${dateFormat.format(betPlacedDate)} ${timeFormat.format(betPlacedDate)}',
              style: TextStyle(
                fontSize: 16.0,
              ),
            ),
            SizedBox(height: 8.0),
          ],
        ),
      ),
    );
  }
}

class BetHistoryView extends StatefulWidget {
  @override
  _BetHistoryViewState createState() => _BetHistoryViewState();
}

class _BetHistoryViewState extends State<BetHistoryView> {
  final _auth = FirebaseAuth.instance;
  List<DocumentSnapshot> betList = [];

  @override
  void initState() {
    super.initState();
    _fetchBets();
  }

  Future<void> _fetchBets() async {
    try {
      // Reference to the current user's betHistory subcollection
      QuerySnapshot betQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('bet_history')
          .get();

      setState(() {
        betList = betQuery.docs;
      });
    } catch (e) {
      print("Error fetching bets: $e");
      // Show a message or handle the error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Bet History"),
        ),
        body: betList.isEmpty
            ? Center(child: CircularProgressIndicator())
            // : ListView.builder(
            //     itemCount: betList.length,
            //     itemBuilder: (context, index) {
            //       var bet = betList[index].data() as Map<String, dynamic>;
            //       return Card(
            //         margin: EdgeInsets.all(8.0),
            //         child: ListTile(
            //           title: Text('Match ID: ${bet['gameID']}'),
            //           subtitle: Text('Amount: ${bet['amount']}'),
            //           // trailing: Text('Status: ${bet['status']}'),
            //           trailing: Text('${formatTimestamp(bet['placedAt'])}'),
            //           // You can add more details or formatting as needed
            //         ),
            //       );
            //     },
            //   ),
            : ListView.builder(
                itemCount: betList
                    .length, // Assume this is the length of your bet history list
                itemBuilder: (context, index) {
                  final bet =
                      betList[index]; // Assuming this is a list of bet objects
                  return BetHistoryCard(
                    teamBetOn: bet['team'],
                    amount: bet['amount'].toDouble(),
                    matchup: bet['matchup'],
                    betPlacedDate: bet['placedAt']
                        .toDate(), // Make sure this is a DateTime object
                  );
                },
              ));
  }
}
