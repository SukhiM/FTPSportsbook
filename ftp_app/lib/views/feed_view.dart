import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        'username': username, // You can replace 'User' with the actual username
        'message': message,
        'placedAt': FieldValue.serverTimestamp(),
      });

      // Clear the text field after posting
      _postController.clear();
    } else {
      // Display an error or inform the user about the message length requirement
      // You can use a Snackbar or another appropriate method.
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

          // Button to post the message
          ElevatedButton(
            onPressed: _postMessage,
            child: Text('Share'),
          ),

          // Social Feed StreamBuilder
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

                    // Check if the item is a bet or a user message
                    if (feedItem.containsKey('team')) {
                      // Displaying a bet
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
                    } else if (feedItem.containsKey('message')) {
                      // Displaying a user message
                      return Card(
                        margin:
                            EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: ListTile(
                          title: Text('${feedItem['username']} shared:'),
                          subtitle: Text('${feedItem['message']}'),
                          trailing: Text(formatTimestamp(feedItem['placedAt'])),
                        ),
                      );
                    }

                    // Add more conditions if there are other types of feed items

                    return Container(); // Placeholder for unknown feed item types
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
