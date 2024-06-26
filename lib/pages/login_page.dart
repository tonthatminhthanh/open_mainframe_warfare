import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mw_project/firebase/firebase_user_score.dart';
import 'package:mw_project/objects/user_score.dart';
import 'package:mw_project/pages/main_menu.dart';
import 'dart:io';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? _errorMsg;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.gamepad, color: Colors.blue, size: 85,),
              ElevatedButton(
                  onPressed: () async {
                    _logIn();
                  },
                  child: Wrap(
                    children: [
                      Image.asset("assets/images/google.png", width: 16, height: 16,),
                      SizedBox(width: 10,),
                      Text("Sign in with Google")
                    ],
                  )
              ),
              _errorMsg != null ? Text("Error: $_errorMsg", style: TextStyle(color: Colors.red),) : Container()
            ],
          ),
        )
      ),
    );
  }

  void _logIn() async
  {
    bool _loggingIn = true;
    final GoogleSignInAccount? googleAccount = await GoogleSignIn().signIn();

    final GoogleSignInAuthentication? googleAuthentication
    = await googleAccount?.authentication;

    final userAuthentication = GoogleAuthProvider.credential(
      accessToken: googleAuthentication?.accessToken,
      idToken: googleAuthentication?.idToken
    );

    final UserCredential authResult = await FirebaseAuth.instance.signInWithCredential(userAuthentication)
        .catchError((e) {
          setState(() {
            _errorMsg = e.toString();
            _loggingIn = false;
          });
    });

    if(_loggingIn)
    {
      if(authResult.additionalUserInfo!.isNewUser)
      {
        UserScoreSnapshot.addUserScores(
          UserScore(
            uid: authResult.user!.uid,
              name: authResult.user!.displayName!,
              kills: 0,
              maxWave: 0,
            achievements: []
          )
        );
      }

      UserScoreSnapshot.setName();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => MainMenuPage(),)
      );
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => autoLogIn());
    super.initState();
  }

  Future<void> autoLogIn()
  async {
    bool canConnect = await checkNetwork();

    if(FirebaseAuth.instance.currentUser != null && canConnect)
      {
        UserScoreSnapshot.setName();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => MainMenuPage(),)
        );
      }
  }

  Future<bool> checkNetwork() async {
    bool isConnected = false;
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        isConnected = true;
      }
    } on SocketException catch (_) {
      isConnected = false;
    }
    return isConnected;
  }
}
