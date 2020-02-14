
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Tabular extends StatefulWidget {
  @override
  _tabularWidget createState() => new _tabularWidget();
}

class _tabularWidget extends State<Tabular> {

  final db = Firestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  var ll;
  String uid = "s";

  @override
  Widget build(BuildContext context) {
//    displayRecordings();
//    Recordings recordings;

    inputData();
    print(uid);
    return SingleChildScrollView(
      child:Container(
        child: new Column(
        children: <Widget>[
          Container(
            height: MediaQuery.of(context).size.height - 202,
            child: StreamBuilder<QuerySnapshot>(
              stream: db
                  .collection('jobs')
                  .where('user', isEqualTo: '/users/' + uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return LinearProgressIndicator();
                } else {
                  return new ListView(
                    shrinkWrap: true,
                    children: snapshot.data.documents.map((
                        DocumentSnapshot document) {
                      return new Row(
                        children: <Widget>[
                          Container (
                            width:  MediaQuery.of(context).size.width,
                            child: Card (
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                color: Colors.white,
                                elevation: 60,
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      ListTile(
                                        leading: Icon(Icons.play_circle_filled, size: 40),
                                        title: Container (
                                          child: Column (
                                            children: <Widget>[
                                              Text(document["fragment"].toString()),
                                            ],
                                          ),
                                        ),
                                        subtitle: Text(document["deliverable"].toString(), style: TextStyle(color: Colors.black)),
                                      ),
                                    ],
                               )
                            ),
                          )
                        ],
                      );
                    }).toList(),
                  );
                }
              },
            ),
          ),
        ],
      ),
    ),);
  }

  Future<void> inputData() async {
    final FirebaseUser user = await FirebaseAuth.instance.currentUser();
    uid = user.uid.toString();
  }
}
