import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Function to simulate the game between two teams
Future<Map<String, dynamic>?> simulateGame(
    String homeTeam, String awayTeam) async {
  print('${homeTeam} vs ${awayTeam}');
  try {
    // Assuming you have 'predictions' as a top-level collection
    // and 'awayTeams' as a subcollection inside each home team document
    DocumentSnapshot predictionSnapshot = await FirebaseFirestore.instance
        .collection('predictions')
        .doc(homeTeam)
        .collection('AWAYTEAMS')
        .doc(awayTeam)
        .get();

    if (predictionSnapshot.exists) {
      // Return the data of the prediction
      return predictionSnapshot.data() as Map<String, dynamic>;
    } else {
      // Handle the case where there is no prediction
      print("No prediction available for this matchup.");
      return null;
    }
  } catch (e) {
    // Handle any errors that occur during the Firestore query
    print("Error simulating game: $e");
    return null;
  }
}

class SimulatorView extends StatefulWidget {
  @override
  _SimulatorViewState createState() => _SimulatorViewState();
}

class _SimulatorViewState extends State<SimulatorView> {
  String? _selectedHomeTeam;
  String? _selectedAwayTeam;
  List<String> _teams = [
    "ATL",
    "BOS",
    "BKN",
    "CHA",
    "CHI",
    "CLE",
    "DAL",
    "DEN",
    "DET",
    "GSW",
    "HOU",
    "IND",
    "LAC",
    "LAL",
    "MEM",
    "MIA",
    "MIL",
    "MIN",
    "NOP",
    "NYK",
    "OKC",
    "ORL",
    "PHI",
    "PHX",
    "POR",
    "SAC",
    "SAS",
    "TOR",
    "UTA",
    "WAS",
  ];

  List<String> get availableHomeTeams {
    return _selectedAwayTeam != null
        ? _teams.where((t) => t != _selectedAwayTeam).toList()
        : _teams;
  }

  List<String> get availableAwayTeams {
    return _selectedHomeTeam != null
        ? _teams.where((t) => t != _selectedHomeTeam).toList()
        : _teams;
  }

  void _showSimulationResult(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Simulation Result'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Predicted Winner: ${result['predictedWinner']}'),
                Text('Probability: ${result['probability']}%'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Simulator"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedHomeTeam,
              hint: Text("Select Home Team"),
              onChanged: (newValue) {
                setState(() {
                  _selectedHomeTeam = newValue;
                });
              },
              items: availableHomeTeams
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              value: _selectedAwayTeam,
              hint: Text("Select Away Team"),
              onChanged: (newValue) {
                setState(() {
                  _selectedAwayTeam = newValue;
                });
              },
              items: availableAwayTeams
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: (_selectedHomeTeam != null &&
                      _selectedAwayTeam != null)
                  ? () async {
                      var result = await simulateGame(
                          _selectedHomeTeam!, _selectedAwayTeam!);
                      if (result != null) {
                        _showSimulationResult(result);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'No prediction data available for this matchup.'),
                          ),
                        );
                      }
                    }
                  : null, // Button will be disabled if any team is not selected
              child: Text('Simulate Game'),
            ),
          ],
        ),
      ),
    );
  }
}
