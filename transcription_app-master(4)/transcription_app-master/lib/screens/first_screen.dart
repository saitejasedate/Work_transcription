import 'package:flutter/material.dart';
import 'package:transcribe_calls/routes/auth.dart';

class FirsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: Container(
        color: Colors.white,
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Flexible(
              flex: 2,
              child: new Container(
                //color: Colors.white,
                height: 400.0,
                width: 400.0,
                decoration: new BoxDecoration(
                  image: DecorationImage(
                    image: new AssetImage('assets/images/download.png'),
                  ),
                ),
              ),
            ),
            Flexible(
              flex: 6,
              child: new Container(
                //color: Colors.black,
                child: RichText(
                  text: TextSpan(
                    children: <TextSpan>[
                      TextSpan(
                          text:
                              'By Downloading, Accessing and by providing your Banking Information You confirm that you Accept and Agree to be bound by the terms of Transcription Program.',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      TextSpan(
                          text: 'Contribution',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                          text:
                              'You are contributing to this program by transcribing the fragments'),
                      TextSpan(
                          text: 'Privacy',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: 'to be filled'),
                      TextSpan(
                          text: 'Renumeration',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                          text:
                              'You will be paid on periodic basis an amount proportional to your contribution through the bank or other payment methods given by you. If we want to contact you we will do so by email, telephone or by SMS, using the contact details you have provided to us.'),
                    ],
                  ),
                ),
              ),
            ),
            Flexible(
              flex: 2,
              child: new Container(
                child: new ButtonTheme.bar(
                  child: new ButtonBar(
                    alignment: MainAxisAlignment.center,
                    children: <Widget>[
                      new RaisedButton(
                        child: Text('Agree'),
                        textColor: Colors.white,
                        elevation: 5.0,
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AuthScreen()));
                        },
                      ),
                      new RaisedButton(
                        child: Text('Disagree'),
                        textColor: Colors.white,
                        elevation: 5.0,
                        onPressed: () {
                          //Do something here
                        },
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
