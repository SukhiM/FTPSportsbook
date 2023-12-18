import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:firebase_auth/firebase_auth.dart';
enum FeedCategory {All, Bets, Shared}
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

  FeedCategory selectedCategory = FeedCategory.All;

  // Popup for creating posts 
  void _openPostCreationPopup(BuildContext context) async {
    // Get the message from the TextField controller in the popup
    String? message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Create a Post"),
        content: TextField(
          controller: _postController,
          maxLength: 80,
          decoration: InputDecoration(
            hintText: "What's on your mind?",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _postController.text),
            child: Text("Post"),
          ),
        ],
      ),
    );

    // Check if message is not null (meaning the user clicked "Post")
    if (message != null) {
      // Call your actual post sending logic with the message
      _postMessage();
    }
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
  Widget _buildUserProfile() {
    var uid = FirebaseAuth.instance.currentUser?.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        var userData = snapshot.data?.data() as Map<String, dynamic>?;

        if (userData == null) {
          return Text('Error loading user data');
        }

        var profileImageUrl = userData['profileImageUrl'] ?? '';

        return Row(
          children: [
            // Display profile picture in a circle avatar
            CircleAvatar(
              radius: 20,
              backgroundImage: profileImageUrl.isNotEmpty
                  ? NetworkImage(profileImageUrl) as ImageProvider<Object>
                  : AssetImage('assets/default_profile_image.jpg') as ImageProvider<Object>,
            ),

            SizedBox(width: 10),
            Text(userData['username'] ?? ''),
          ],
        );
      },
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text("Social Feed"),
      actions: [
        // Dropdown button for category selection
        DropdownButton<FeedCategory>(
          value: selectedCategory,
          onChanged: (FeedCategory? value) {
            setState(() {
              selectedCategory = value!;
             });
          },
          items: [
            DropdownMenuItem(
              value: FeedCategory.All,
              child: Text('All'),
             ),
            DropdownMenuItem(
              value: FeedCategory.Bets,
              child: Text('Bets'),
             ),
             DropdownMenuItem(
               value: FeedCategory.Shared,
               child: Text('Shared'),
               ),
              ],
            ),
      ],
    ),
    body: Column(
      children: [
        // ... User profile information if you want to display it
        _buildUserProfile(),

        // Button to open the post creation popup
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () => _openPostCreationPopup(context),
            child: Text('Create a Post'),
          ),
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
               // Filter feed items based on selected category
                var filteredFeedItems = feedItems.where((feedItem) {
                var type = feedItem['type'];

                if (selectedCategory == FeedCategory.All) {
                return true;
               } else if (selectedCategory == FeedCategory.Bets) {
                 return type == 'betslip' && feedItem['payout'] > 0;
               } else if (selectedCategory == FeedCategory.Shared) {
                  return type == 'share' && feedItem['payout'] <= 0;
               }
                return false;
               }).toList();
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
