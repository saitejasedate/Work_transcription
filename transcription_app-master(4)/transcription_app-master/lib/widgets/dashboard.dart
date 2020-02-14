import 'package:flutter/material.dart';

class DashBoard extends StatefulWidget {
  @override
  _dashBoard createState() => _dashBoard();
}

class _dashBoard extends State<DashBoard> {
  final int counter_transactions = 0;
  final int counter_approved = 0;
  final int counter_result = 0;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Align (
        alignment: Alignment.topCenter,
        child: Row (
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
                child: Column (
                  children: <Widget>[
                    Text("$counter_transactions", style: TextStyle(fontSize: 22)),
                    Text("Transcations", style: TextStyle(fontSize: 22)),
                    SizedBox(width: 20),
                  ],
                )
            ),
            Container(
                child: Column (
                  children: <Widget>[
                    Text("$counter_approved", style: TextStyle(fontSize: 22)),
                    Text("Approved", style: TextStyle(fontSize: 22)),
                    SizedBox(width: 20),
                  ],
                )
            ),
            Container(
                child: Column (
                  children: <Widget>[
                    Text("$counter_result", style: TextStyle(fontSize: 22)),
                    Text("Result", style: TextStyle(fontSize: 22)),
                    SizedBox(width: 20),
                  ],
                )
            ),
          ],
        ),
      ),
    );
  }
}