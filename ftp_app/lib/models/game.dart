class Game {
  final String team1;
  final String team2;
  final DateTime date;
  final String gameID;
  final String status;
  final DateTime time;
  final String dateStr;

  Game(
      {required this.gameID,
      required this.team1,
      required this.team2,
      required this.date,
      required this.status,
      required this.time,
      required this.dateStr});

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      gameID: json['gameID'],
      team1: json['home'],
      team2: json['away'],
      status: json['status'],
      time: DateTime.parse(json['time']),
      date: DateTime.parse(json['date']),
      dateStr: json['date'],
    );
  }
}
