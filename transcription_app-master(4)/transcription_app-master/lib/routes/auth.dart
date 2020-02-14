import 'dart:async';
import 'dart:ffi';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import 'package:transcribe_calls/widgets/landing_page.dart';
import '../widgets/landing_page.dart';
import '../screens/register.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../widgets/google_sign_in_btn.dart';
import '../widgets/reactive_refresh_indicator.dart';

// Each item on AuthStatus represents quite literally the status of the UI.
// On SOCIAL_AUTH only the GoogleSignInButton will be visible.
enum AuthStatus { SOCIAL_AUTH }

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

// On _AuthScreenState we start by defining the tag that will be used for our logger, then the default status as SOCIAL_AUTH, which means we need to do Google's sign in and the GoogleSignInButton will be visible and interactive.
class _AuthScreenState extends State<AuthScreen> {
  String phoneNo;
  String smsCode;
  String verificationId;
  bool _smsCodeDisabled = true;

  final db = Firestore.instance;

  void _showMessage() {
    showDialog<Null>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return new AlertDialog(
            title: new Text('Not a Registered User'),
            content: new SingleChildScrollView(
              child: new ListBody(
                children: <Widget>[
                  new Text(
                      'You are not a registered user. Register First please'),
                ],
              ),
            ),
            actions: <Widget>[
              new FlatButton(
                child: new Text('Ok'),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => AuthScreen()));
                },
              )
            ],
          );
        });
  }

  // static Future<bool> doesNumberAlreadyExists(String phoneNo, String mobileno) async{
  //   final QuerySnapshot result = await Firestore.instance
  //     .collection('transcriber_user_registeration')
  //     .where(mobileno, isEqualTo:phoneNo)
  //     .limit(1)
  //     .getDocuments();
  //     final List<DocumentSnapshot> documents = result.documents;
  //    return documents.length >= 1;
  // }

  // Firestore.instance.collection('transcriber_user_registeration').where('mobileno', isEqualTo: phoneNo)
  // .snapshots().listen(
  //       (data) { print("Inside phone number check : $data"); });
  //       // return phoneNumberCheck(phoneNo);

  // QuerySnapshot result =
  //       await Firestore.instance.collection('transcriber_user_registeration').getDocuments();
  //  var list = result.documents;
  // print("Before data loop");
  // list.forEach((data) => print(data));
  // print("After data loop");

  Future<void> phoneNumberCheck(String phoneNo, bool isPresent) async {
    print("Start of the function");
    //bool registerState = false;
    //bool isPresent = false;
    Firestore.instance
        .collection("transcriber_user_registeration")
        .getDocuments()
        .then((QuerySnapshot snapshot) {
      snapshot.documents.forEach((f) async {
        if (isPresent = ('${f.data['mobileno']}' == phoneNo)) {
          final PhoneCodeAutoRetrievalTimeout autoRetrieve = (String verId) {
            this.verificationId = verId;
          };
          final PhoneCodeSent smsCodeSent =
              (String verId, [int forceCodeResend]) {
            this.verificationId = verId;
            print("im in sms code dialog");
//          smsCodeDialog(context).then((value) {
//          print('Signed in');
//          });
            setState(() {
              this._smsCodeDisabled = false;
            });
          };
          final PhoneVerificationCompleted verifySuccess =
              (AuthCredential user) {
            print("verified");
          };

          final PhoneVerificationFailed verifyFailed =
              (AuthException exception) {
            print('${exception.message}');
          };

          await FirebaseAuth.instance.verifyPhoneNumber(
            phoneNumber: this.phoneNo,
            codeAutoRetrievalTimeout: autoRetrieve,
            codeSent: smsCodeSent,
            timeout: const Duration(seconds: 5),
            verificationCompleted: verifySuccess,
            verificationFailed: verifyFailed,
          );
        }
//        else {
//          _showMessage();
//        }
      });
    });
    //print("End of the function $isPresent");
  }

  Future<void> verifyPhone() async {
    // final PhoneCodeAutoRetrievalTimeout autoRetrieve = (String verId) {
    //   this.verificationId = verId;
    // };
    var tmp1 = phoneNo.toString();
    print('ref stsmt starts $tmp1');
    //Firestore.instance.collection('transcriber_user_registeration').where('mobileno', isEqualTo:phoneNo).snapshots().listen( (data) => print('mobileno ${data.documents[0]['mobileno']}'));
    // String tmp = ref.toString();
    //QuerySnapshot doclist;
    //doclist = (await Firestore.instance.collection('transcriber_user_registeration').where('mobileno', isEqualTo:phoneNo).getDocuments());
    //var ref = Firestore.instance.collection('transcriber_user_registeration').where('mobileno', isEqualTo:phoneNo);
    //var tmp2 = doclist == null;
    //var docs = ref.getDocuments();
    //print('Ref val $tmp2');
    // var tmp = A().getInt(ref);
    // print('Value of tmp is $tmp');
    // print(ref.runtimeType);
    //print('bvvvn');
    // var ref = Firestore.instance.collection('transcriber_user_registeration').where('mobileno', isEqualTo:phoneNo);
    // print(ref.runtimeType);
    // doesNumberAlreadyExists(phoneNo, '+919632185780');
    bool isPresent = false;
    await phoneNumberCheck(phoneNo, isPresent);
    print("After execution of the function $isPresent");
    // print(ref.runtimeType);
    print('bvnnn');

//     final PhoneCodeSent smsCodeSent = (String verId, [int forceCodeResend]) {
//       this.verificationId = verId;
//       print("im in sms code dialog");
// //      smsCodeDialog(context).then((value) {
// //        print('Signed in');
// //      });
//       setState(() {
//         this._smsCodeDisabled = false;
//       });
//     };

    //   final PhoneVerificationCompleted verifySuccess = (AuthCredential user) {
    //     print("verified");
    //   };

    //   final PhoneVerificationFailed verifyFailed = (AuthException exception) {
    //     print('${exception.message}');
    //   };

    //   await FirebaseAuth.instance.verifyPhoneNumber(
    //     phoneNumber: this.phoneNo,
    //     codeAutoRetrievalTimeout: autoRetrieve,
    //     codeSent: smsCodeSent,
    //     timeout: const Duration(seconds: 5),
    //     verificationCompleted: verifySuccess,
    //     verificationFailed: verifyFailed,
    //   );
    // }
  }

  Future<bool> smsCodeDialog(BuildContext context) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text('Enter sms code'),
            content: TextField(onChanged: (value) {
              this.smsCode = value;
            }),
            contentPadding: EdgeInsets.all(10.0),
            actions: <Widget>[
              new FlatButton(
                    child: Text('Login'),
                    onPressed: () async {
                      await FirebaseAuth.instance.currentUser().then((user) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LandingPageApp()));
                    });
                  })
            ],
          );
        });
  }

  // _number() async {
  //   final db = Firestore.instance;

  //   await db.collection('mobilenumbers').add({
  //     "MobileNumber": "$phoneNo",
  //     "OTP": "$smsCode",
  //   });
  //   print("new mobile number added.");
  // }

  signIn() {
    print("came to sign in page");
    final AuthCredential credential = PhoneAuthProvider.getCredential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    FirebaseAuth.instance.signInWithCredential(credential).then((user) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => LandingPageApp()));
    }).catchError((e) {
      print(e);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Flexible(
                flex: 1,
                child: new Container(
                  //color: Colors.white,
                  height: 200.0,
                  width: 400.0,
                  decoration: new BoxDecoration(
                    image: DecorationImage(
                      image: new AssetImage('assets/images/download.png'),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                child: TextFormField(
                    decoration:
                        InputDecoration(hintText: 'Enter your Phone number'),
                    keyboardType: TextInputType.phone,
                    onChanged: (value) {
                      this.phoneNo = "+91$value";
                    },
                    validator: validateMobile),
              ),
              SizedBox(height: 10.0),
              RaisedButton(
                onPressed: () {
                  verifyPhone();
                  //_number();
                },
                child: Text('Login'),
                textColor: Colors.white,
                elevation: 7.0,
                color: Colors.blue,
              ),
              _smsCodeDisabled
                  ? SizedBox(height: 10.0)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 16.0),
                          child: TextFormField(
                              decoration:
                                  InputDecoration(hintText: 'Enter OTP'),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                this.smsCode = value;
                              },
                              validator: validateOtp),
                        ),
                        SizedBox(height: 10.0),
                        RaisedButton(
                          onPressed: () async {
                            await signIn();
//                            FirebaseAuth.instance.currentUser().then((user) {
//                              print(["user", user]);
//                              if (user != null) {
//                                print(user.uid);
//                                Navigator.of(context).pop();
////                                    Navigator.of(context).pushReplacementNamed('/homePage');
//                                Navigator.of(context).push(
//                                    MaterialPageRoute<Null>(
//                                        builder: (BuildContext context) {
//                                  return new LandingPageApp();
//                                }));
//                              } else {
//                                print("user is null");
//                                Navigator.of(context).pop();
//                                signIn();
//                              }
//                            });
                          },
                          child: Text('Submit'),
                          textColor: Colors.white,
                          elevation: 7.0,
                          color: Colors.blue,
                        ),
                      ],
                    ),
              SizedBox(
                height: 20.0,
              ),
              Column(
                children: <Widget>[
                  Row(children: <Widget>[
                    Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 20.0),
                      child: Text(
                        'Not a Registered User?',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                    MaterialButton(
                      child: Text(
                        'Register',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      //color: Colors.blue,
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Register()));
                      },
                    ),
                  ]),
                ],
              ),
            ],
          ),
        ));
  }
}

String validateMobile(String value) {
  //Indian Mobile numbers are of 10 digits only.
  if (value.length != 10)
    return 'Mobile number must be of 10 digits';
  else
    return null;
}

String validateOtp(String value) {
  //Otp needs to be of 6 digits
  if (value.length != 6)
    return 'OTP must be of 6 digits';
  else
    return null;
}
