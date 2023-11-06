import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ftp_app/views/change_password_view.dart';
import 'package:ftp_app/views/bet_history_view.dart';

class SettingsView extends StatefulWidget {
  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _auth = FirebaseAuth.instance;
  String? username;
  num? balance;

  Future<void> _fetchBalance() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .get();

      var userData = userDoc.data() as Map<String, dynamic>?; // Cast as a Map
      setState(() {
        balance = userData?['balance'] as num?;
        username = userData?['username'];
      });
    } catch (e) {
      // Handle the error or show a message
      print("Error fetching balance: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('Welcome'),
            subtitle: Text(username ?? 'N/A'),
          ),
          ListTile(
            title: Text('Balance'),
            trailing: Text(balance?.toString() ?? 'Loading...'),
          ),
          ListTile(
            title: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BetHistoryView()),
                );
              },
              child: Text('Bet History'),
            ),
          ),
          ListTile(
            title: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ChangePasswordView()), // Redirect to ChangePasswordView
                );
              },
              child: Text('Change Password'),
            ),
          ),
          ListTile(
            title: ElevatedButton(
              onPressed: () async {
                await _auth.signOut();
                Navigator.pushReplacementNamed(
                    context, '/login'); // Navigate back to login after sign out
              },
              child: Text('Sign Out'),
            ),
          ),
        ],
      ),
    );
  }
}
