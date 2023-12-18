import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const shareEndpoint = "https://sharebetslip-kca5bali4a-uc.a.run.app";

String formatTimestamp(Timestamp timestamp) {
  DateTime dateTime = timestamp.toDate();
  DateFormat formatter = DateFormat('MM-dd-yyyy HH:mm');
  return formatter.format(dateTime);
}

class BetHistoryCard extends StatelessWidget {
  final String teamBetOn;
  final String betID;
  final String status;
  final double amount;
  final String matchup;
  final DateTime betPlacedDate;
  final double? payout;

  BetHistoryCard(
      {required this.teamBetOn,
      required this.betID,
      required this.status,
      required this.amount,
      required this.matchup,
      required this.betPlacedDate,
      this.payout});

  void _showShareDialog(BuildContext context, String betID) {
    TextEditingController _messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Share Bet Slip'),
          content: TextField(
            controller: _messageController,
            decoration: InputDecoration(hintText: "Type your message here"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Share'),
              onPressed: () {
                String message = _messageController.text;
                _shareBetSlipToGlobal(context, betID, message);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _shareBetSlipToGlobal(
      BuildContext context, String betID, String message) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final response = await http.post(
        Uri.parse(shareEndpoint),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'uid': uid,
          'betID': betID,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Bet shared successfully!')),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to share bet: ${response.body}')),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Exception when sharing bet: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('MM-dd-yyyy');
    final DateFormat timeFormat = DateFormat('hh:mm a');

    return Card(
      margin: EdgeInsets.all(8.0),
      child: Stack(
        children: [
          Padding(
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
                  status,
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
                if (payout != null) ...[
                  SizedBox(height: 8),
                  Text(
                    'Payout: ${payout!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: payout! > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
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
          if (status == 'won' ||
              status ==
                  'lost') // Share icon appears for completed ('won' or 'lost') bets only
            Positioned(
              right: 4.0,
              bottom: 4.0,
              child: IconButton(
                icon: Icon(Icons.share),
                onPressed: () => _showShareDialog(context, betID),
              ),
            ),
        ],
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
      QuerySnapshot betQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('bet_history')
          .orderBy('placedAt', descending: true)
          .get();

      setState(() {
        betList = betQuery.docs;
      });
    } catch (e) {
      print("Error fetching bets: $e");
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
            : ListView.builder(
                itemCount: betList.length,
                itemBuilder: (context, index) {
                  final bet = betList[index];
                  return BetHistoryCard(
                    teamBetOn: bet['team'],
                    betID: bet.id,
                    status: bet['status'] ?? "pending",
                    amount: bet['amount'].toDouble(),
                    matchup: bet['matchup'],
                    betPlacedDate: bet['placedAt'].toDate(),
                    payout: bet['payout']?.toDouble(),
                  );
                },
              ));
  }
}
