import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:ftp_app/models/game.dart';

const String placeBet = 'https://placebet-kca5bali4a-uc.a.run.app/';

void _placeBet(BuildContext context, String team, double amount, String gameID,
    String matchup, String date) async {
  String uid = FirebaseAuth.instance.currentUser!.uid;

  try {
    final response = await http.post(
      Uri.parse(placeBet),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'uid': uid,
        'team': team,
        'amount': amount,
        'gameID': gameID,
        'matchup': matchup,
        'date': date,
      }),
    );

    if (response.statusCode == 200) {
      print('Bet placed successfully'); // Debugging print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bet placed successfully!')),
      );
      Navigator.of(context).pop();
    } else {
      print('Failed to place bet: ${response.body}'); // Debugging print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.body}')),
      );
    }
  } catch (e) {
    print('Error occurred while trying to place bet: $e'); // Debugging print
  }
}

class PlaceBetScreen extends StatefulWidget {
  final Game selectedGame;
  final String selectedTeam;

  const PlaceBetScreen(
      {Key? key, required this.selectedGame, required this.selectedTeam})
      : super(key: key);

  @override
  _PlaceBetScreenState createState() => _PlaceBetScreenState();
}

class _PlaceBetScreenState extends State<PlaceBetScreen> {
  final TextEditingController _amountController = TextEditingController();
  double _estimatedPayout = 0.0;

  void _calculatePayout(String amount) {
    double enteredAmount = double.tryParse(amount) ?? 0.00;
    setState(() {
      _estimatedPayout =
          enteredAmount * 2; // Test calculation; no odds implemented
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Place Bet'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Display bet information
            Text(
                'Game: ${widget.selectedGame.team1} vs ${widget.selectedGame.team2}'),
            SizedBox(height: 16.0),
            Text('${widget.selectedTeam} to Win'),
            SizedBox(height: 16.0),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Bet Amount',
              ),
              onChanged: _calculatePayout,
            ),
            SizedBox(height: 16.0),
            Text('Estimated Payout: \$$_estimatedPayout'),
            SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: () {
                _placeBet(
                  context,
                  widget.selectedTeam,
                  double.tryParse(_amountController.text) ?? 0.0,
                  widget.selectedGame.gameID,
                  '${widget.selectedGame.team1} vs ${widget.selectedGame.team2}',
                  widget.selectedGame.dateStr,
                );
              },
              child: Text('Place Bet'),
            ),
          ],
        ),
      ),
    );
  }
}
