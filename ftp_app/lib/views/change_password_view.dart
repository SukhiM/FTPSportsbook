import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordView extends StatefulWidget {
  @override
  _ChangePasswordViewState createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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

          Navigator.of(context).pop();
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
      appBar: AppBar(
        title: Text('Change Password'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _oldPasswordController,
                decoration: InputDecoration(labelText: 'Old Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your old password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(labelText: 'New Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your new password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _changePassword,
                child: Text('Change Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
