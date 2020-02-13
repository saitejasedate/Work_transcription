import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


class Tabular extends StatefulWidget {
  @override
  _tabularWidget createState() => new _tabularWidget();
}

class _tabularWidget extends State<Tabular> {

  final db = Firestore.instance;
  var query;
//    final db = Firestore.instance;
//    var query = db.collection('jobs').document('02WyuUbKxWE57n1aihhz');
//    var d = await query.get();
//    var output = d.data;
//    return output;

  @override
  Widget build(BuildContext context) {
//    displayRecordings();
    Recordings recordings;
    return Expanded (
        child: Container (
            decoration: BoxDecoration (
                color : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                )
            ),
            child: ListView.builder (
              itemBuilder: (BuildContext context, int index) {
                return Column (
                  children: <Widget>[
                  Container (
                      child: Row (
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Container (
                              child: Column (
                                children: <Widget>[
                                  Text("Audio file", style: TextStyle(fontSize: 25)),
                                ],
                              )
                          ),
                          Container (
                              child: Column (
                                children: <Widget>[
                                  Text("Approval Status", style: TextStyle(fontSize: 25)),
                                ],
                              )
                          ),
                          Container (
                              child: Column (
                                children: <Widget>[
                                  Text("Result", style: TextStyle(fontSize: 25)),
                                ],
                              )
                          ),
                        ],
                      )
                  )
                ]
                );
              }
            )
        )
    );
  }
}
