import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  File? _imageFile;

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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile != null) {
      try {
        var uid = FirebaseAuth.instance.currentUser?.uid;
        var storageRef =
        FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
        await storageRef.putFile(_imageFile!);
        var imageUrl = await storageRef.getDownloadURL();

        // Save the image URL to Firestore under the user's document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'profileImageUrl': imageUrl});
      } catch (e) {
        print("Error uploading profile picture: $e");
      }
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
          // Add a button to pick an image
          ListTile(
            title: ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Profile Picture'),
            ),
          ),
          // Add a button to upload the image
          ListTile(
            title: ElevatedButton(
              onPressed: _uploadImage,
              child: Text('Upload Profile Picture'),
            ),
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
