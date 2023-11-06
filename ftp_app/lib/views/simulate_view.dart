import 'package:flutter/material.dart';

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
                  ? () {
                      // Logic for simulator
                      print(
                          'Simulating game between $_selectedHomeTeam and $_selectedAwayTeam');
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
