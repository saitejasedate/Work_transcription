import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentWidget extends StatefulWidget {
  @override
  _paymentAppState createState() => new _paymentAppState();
}


class _paymentAppState extends State<PaymentWidget> {
  int flag = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Payment"),
      ),
      body: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
              Container(
              //color: Colors.white,
              height: 300.0,
              width: 500.0,
              child: new FlatButton(
                child: Image.asset("assets/images/gpay.jpeg"),
                onPressed: () async {
                  print("image");
                },
              ),
              ),
              Container (
                  padding: const EdgeInsets.all(20.0),
                  child: new FlatButton(
                    child: Text('Withdraw'),
                    onPressed: () async {
                      print("withdraw");
                      flag  = 1;
                      final db = Firestore.instance;
                      await db.collection('paymentDetails').add({
                        "_name":"saiteja",
                        "_money":"50",
                        "_gpayNum":"897811XXXX",
                      });
                    },
                  ),
              )
          ],
        ),
      ),
    );
  }
}