import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import './reactive_refresh_indicator.dart';
import 'package:http/http.dart';
//import './history.dart';
import '../widgets/logger.dart';
import 'package:flutter/animation.dart';
import 'package:transcribe_calls/widgets/landing_page.dart';

class landing extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transcription'),
      
      ),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child:Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Flexible(
                    flex:1,
                    child: IconButton(
                      padding: new EdgeInsets.all(5.0),
                              icon: new Icon(Icons.send, size: 50.0),
                              onPressed:() {}
                          ),
                  ),
                  SizedBox(
                    width: 50.0,
                  ),
                  Flexible(
                    flex:1,
                    child: Text('jnlf'),
                  ),
                  SizedBox(
                    width: 50.0,
                  ),
                  Flexible(
                    flex: 1,
                    child:Text('jlfba'),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  Flexible(
                    flex:1,
                    child: Text('sjkdgk'),
                    ),
                  Flexible(
                    flex:1,
                    child: Text('jnlf'),
                  ),
                  Flexible(
                    flex: 1,
                    child:Text('jlfba'),
                  ),
                ],
              ),
            ]
          ),
        ),
      )
    );
  }
}