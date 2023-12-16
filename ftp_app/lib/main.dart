import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:ftp_app/views/login_view.dart';
import 'package:ftp_app/views/home_view.dart';

const String apiKey = 'AIzaSyC6DxQs2bkdcBLJ1hGKw_iHOZolFjAMBak';
const String appId = '1:307152432106:android:b8349b5ca232bbbc17a093';
const String messagingSenderId = '307152432106';
const String projectId = 'ftp-sportsbook';

void main() async {
  ErrorWidget.builder = (FlutterErrorDetails details) => Container();
  // Ensure that Firebase is initialized
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          messagingSenderId: messagingSenderId,
          projectId: projectId));

  runApp(SportsbookApp());
}

class SportsbookApp extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FTP App',
      home: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            User? user = snapshot.data;
            if (user == null) {
              return LoginScreen();
            } else {
              return SportsbookHomeScreen();
            }
          } else {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }
}
