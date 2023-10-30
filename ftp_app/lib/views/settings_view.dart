import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsView extends StatefulWidget {
  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _auth = FirebaseAuth.instance;
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  Future<void> _changePassword() async {
    try {
      // Check if the currentUser is not null
      if (_auth.currentUser != null) {
        // Since we've checked for null, we can use the '!' operator
        String? userEmail = _auth.currentUser!.email;

        // Ensure that userEmail is not null before proceeding
        if (userEmail != null) {
          // Re-authenticate the user
          AuthCredential credential = EmailAuthProvider.credential(
            email: userEmail,
            password: _oldPasswordController.text,
          );
          await _auth.currentUser!.reauthenticateWithCredential(credential);

          // Now, change the password
          await _auth.currentUser!.updatePassword(_newPasswordController.text);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Password updated successfully!')),
          );
        } else {
          throw Exception("User's email is null");
        }
      } else {
        throw Exception("No current user found");
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating password. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _oldPasswordController,
              decoration: InputDecoration(
                labelText: 'Current Password',
                icon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            TextField(
              controller: _newPasswordController,
              decoration: InputDecoration(
                labelText: 'New Password',
                icon: Icon(Icons.lock_open),
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Change Password'),
              onPressed: _changePassword,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }
}
