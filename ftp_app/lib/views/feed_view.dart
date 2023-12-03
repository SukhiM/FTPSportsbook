import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:firebase_auth/firebase_auth.dart';

class SocialFeed extends StatefulWidget {
  @override
  _SocialFeedState createState() => _SocialFeedState();
}

class _SocialFeedState extends State<SocialFeed> {
  TextEditingController _postController = TextEditingController();

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

  // Function to handle posting a new message to the social feed
  void _postMessage() async {
    var username;
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();

      var userData = userDoc.data() as Map<String, dynamic>?; // Cast as a Map
      username = userData?['username'];
    } catch (e) {
      // Handle the error or show a message
      print("Error fetching username: $e");
    }
    String message = _postController.text.trim();
    if (message.isNotEmpty && message.length <= 80) {
      // Add the message to Firestore
      FirebaseFirestore.instance.collection('global_feed').add({
        'username': username,
        'message': message,
        'placedAt': FieldValue.serverTimestamp(),
        'type': 'post',
      });

      _postController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Message must be between 1 and 80 characters long. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Social Feed"),
      ),
      body: Column(
        children: [
          // Text field for entering the message
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _postController,
              maxLength: 80,
              decoration: InputDecoration(
                hintText: 'Type your message (max 80 characters)',
              ),
            ),
          ),

          ElevatedButton(
            onPressed: _postMessage,
            child: Text('Share'),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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

                final feedItems = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: feedItems.length,
                  itemBuilder: (context, index) {
                    var feedItem =
                        feedItems[index].data() as Map<String, dynamic>;

                    if (feedItem['type'] == 'betslip') {
                      return Card(
                        margin:
                            EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: ListTile(
                          title: Text(
                              '${feedItem['username']} bet on ${feedItem['team']}'),
                          subtitle: Text('Game: ${feedItem['matchup']}'),
                          trailing: Text(formatTimestamp(feedItem['placedAt'])),
                        ),
                      );
                    } else if (feedItem['type'] == 'post') {
                      return Card(
                        margin:
                            EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: ListTile(
                          title: Text('${feedItem['username']} shared:'),
                          subtitle: Text('${feedItem['message']}'),
                          trailing: Text(formatTimestamp(feedItem['placedAt'])),
                        ),
                      );
                    } else if (feedItem['type'] == 'share') {
                      return Card(
                        margin:
                            EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(feedItem['username']),
                              SizedBox(height: 8),
                              Text(
                                feedItem['result'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              Text(
                                feedItem['matchup'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              SizedBox(height: 8),
                              if (feedItem['message'] != null &&
                                  feedItem['message'].isNotEmpty)
                                Text(
                                  feedItem['message'],
                                  style: TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                              SizedBox(height: 8),
                              Text(
                                'Amount Wagered: \$${feedItem['amount']}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Payout: \$${feedItem['payout']}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: feedItem['payout'] > 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Container(); // Return an empty container
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
