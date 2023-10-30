import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:ftp_app/views/change_password_view.dart';

class SettingsView extends StatefulWidget {
  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('Email:'),
            subtitle: Text(_auth.currentUser?.email ?? 'N/A'),
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
