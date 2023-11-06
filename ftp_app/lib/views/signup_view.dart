import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ftp_app/views/home_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseFirestore _db = FirebaseFirestore.instance;
void main() => runApp(SignupApp());

class SignupApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Signup App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SignupScreen(),
    );
  }
}

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  String _email = '';
  String _username = '';
  String _password = '';

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      final usernameDocRef = _db.collection("usernames").doc(_username);
      final usernameSnapshot = await usernameDocRef.get();

      if (usernameSnapshot.exists) {
        // Username is already taken, show SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Username is already taken.')),
        );
      } else {
        // Username is not taken, proceed with account creation
        try {
          UserCredential userCredential =
              await _auth.createUserWithEmailAndPassword(
            email: _email,
            password: _password,
          );

          // Use a batch to perform both operations atomically
          final batch = _db.batch();

          final userDocRef =
              _db.collection('users').doc(userCredential.user!.uid);
          batch.set(userDocRef, {
            'email': _email,
            'username': _username,
            'balance': 1000.0,
            // Add other user fields as necessary
          });

          batch.set(usernameDocRef, {
            'uid': userCredential.user!.uid,
          });

          // Commit the batch
          await batch.commit();

          // Successful account creation. Navigate to home screen or show a success message
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SportsbookHomeScreen()),
          );
        } catch (e) {
          // Handle other authentication errors, show a message to the user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                },
                onChanged: (value) {
                  _username = value;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
                onChanged: (value) {
                  _email = value;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
                onChanged: (value) {
                  _password = value;
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                child: Text('SignUp'),
                onPressed: _signup,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
