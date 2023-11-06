import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class SocialFeed extends StatefulWidget {
  @override
  _SocialFeedState createState() => _SocialFeedState();
}

class _SocialFeedState extends State<SocialFeed> {
  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
  }

  String formatTimestamp(Timestamp timestamp) {
    var estZone = tz.getLocation('America/New_York');
    var now = tz.TZDateTime.from(timestamp.toDate(), estZone);
    return DateFormat('MM-dd HH:mm').format(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Social Feed"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('global_feed')
            .orderBy('placedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final bets = snapshot.data!.docs;

          return ListView.builder(
            itemCount: bets.length,
            itemBuilder: (context, index) {
              var bet = bets[index].data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  title: Text('${bet['username']} bet on ${bet['team']}'),
                  subtitle: Text('Game: ${bet['matchup']}'),
                  trailing: Text(formatTimestamp(bet['placedAt'])),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
