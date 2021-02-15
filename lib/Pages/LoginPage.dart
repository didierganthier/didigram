import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:telegramchatapp/Pages/HomePage.dart';
import 'package:telegramchatapp/Widgets/ProgressWidget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LoginScreen extends StatefulWidget {

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {

  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences preferences;

  bool isLoggedIn = false;
  bool isLoading = false;
  FirebaseUser currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text("DidiGram", style: TextStyle(fontSize: 82.0, color: Colors.white, fontFamily: "Signatra")),
            GestureDetector(
              onTap: controlSignIn,
              child: Center(
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 270.0,
                      height: 65.0,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage("assets/images/google_signin_button.png"),
                          fit: BoxFit.cover
                        )
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(1.0),
                      child: isLoading? circularProgress() : Container(),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }


  Future<Null> controlSignIn() async
  {
    preferences = await SharedPreferences.getInstance();

    this.setState(() {
      isLoading = true;
    });

    GoogleSignInAccount googleuser = await googleSignIn.signIn();
    GoogleSignInAuthentication googleSignInAuthentication = await googleuser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(idToken: googleSignInAuthentication.idToken, accessToken: googleSignInAuthentication.accessToken);

    FirebaseUser firebaseUser = (await firebaseAuth.signInWithCredential(credential)).user;

    if(firebaseUser != null)
    {
      //Check if already signed up
      final QuerySnapshot resultQuery = await Firestore.instance.collection("users").where("id", isEqualTo: firebaseUser.uid).getDocuments();
      final List<DocumentSnapshot> documentSnapshots = resultQuery.documents;

      //Save data to FireStore - if new user
      if(documentSnapshots.length == 0)
      {
        Firestore.instance.collection("users").document(firebaseUser.uid).setData({
          "nickname": firebaseUser.displayName,
          "photoUrl": firebaseUser.photoUrl,
          "id": firebaseUser.uid,
          "aboutMe": "I am using DidiGram",
          "createdAt": DateTime.now().millisecondsSinceEpoch.toString(),
          "chattingWith": null,
        });

        //Write data to local
        currentUser = firebaseUser;
        await preferences.setString("id", currentUser.uid);
        await preferences.setString("nickname", currentUser.displayName);
        await preferences.setString("photoUrl", currentUser.photoUrl);
      }
      else
      {
        //Write data to local
        currentUser = firebaseUser;
        await preferences.setString("id", documentSnapshots[0]["id"]);
        await preferences.setString("nickname", documentSnapshots[0]["nickname"]);
        await preferences.setString("photoUrl", documentSnapshots[0]["photoUrl"]);
        await preferences.setString("aboutMe", documentSnapshots[0]["aboutMe"]);
      }
      Fluttertoast.showToast(msg: "Welcome, Sign in Success");
      this.setState(() {
        isLoading = false;
      });
    }
    //Signin not success signin failed
    else
    {
      Fluttertoast.showToast(msg: "Try again, Sign in Failed");
      this.setState(() {
        isLoading = false;
      });
    }
  }
}
