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
//    Recordings recordings;
    return SingleChildScrollView(
      child:Container(
      child: new Column(
        children: <Widget>[
          Container(
            child: StreamBuilder<QuerySnapshot>(
              stream: db
                  .collection('jobs')
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
                          Card (
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
}
