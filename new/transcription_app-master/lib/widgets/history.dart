import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transcribe_calls/widgets/dashboard.dart';
import 'package:transcribe_calls/widgets/tabular.dart';

class HistoryWidget extends StatefulWidget {
  @override
  _historyAppState createState() => new _historyAppState();
}

class _historyAppState extends State<HistoryWidget> {
  final int counter_transactions = 0;
  final int counter_approved = 0;
  final int counter_result = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("History"),

        ),
        body: Column(
          children: <Widget>[
            DashBoard(),
            Tabular(),
          ],
        )
    );
  }
}








