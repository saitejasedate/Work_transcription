// import 'package:flutter/foundation.dart';

// class User{
//   final String name;
//   final String location;
//   final String mobileNo;
//   final String paymentType;
//   bool isMale;
//   bool isFemale;
//   bool isPaytm;
//   bool isGPay;
//   bool isUPI;

//   User({
//     @required this.name,
//     @required this.location,
//     @required this.mobileNo,
//     @required this.paymentType,
//   });
// }


// import 'dart:async';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:transcribe_calls/screens/register.dart';
// import 'package:transcribe_calls/widgets/logger.dart';
// import '../widgets/google_sign_in_btn.dart';
// import '../widgets/reactive_refresh_indicator.dart';
// import '../widgets/landing_page.dart';

// // Each item on AuthStatus represents quite literally the status of the UI.
// // On SOCIAL_AUTH only the GoogleSignInButton will be visible.
// enum AuthStatus { SOCIAL_AUTH }

// class AuthScreen extends StatefulWidget {
//   @override
//   _AuthScreenState createState() => _AuthScreenState();
// }

// // On _AuthScreenState we start by defining the tag that will be used for our logger, then the default status as SOCIAL_AUTH, which means we need to do Google's sign in and the GoogleSignInButton will be visible and interactive.
// class _AuthScreenState extends State<AuthScreen> {
//   String phoneNo;
//   String smsCode;
//   String verificationId;
//   bool _smsCodeDisabled = true;
//   Future<void> verifyPhone() async {
//     final PhoneCodeAutoRetrievalTimeout autoRetrieve = (String verId) {
//       this.verificationId = verId;
//     };

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

//     final PhoneVerificationCompleted verifySuccess = (AuthCredential user) {
//       print("verified");
//     };

//     final PhoneVerificationFailed verifyFailed = (AuthException exception) {
//       print('${exception.message}');
//     };

//     await FirebaseAuth.instance.verifyPhoneNumber(
//       phoneNumber: this.phoneNo,
//       codeAutoRetrievalTimeout: autoRetrieve,
//       codeSent: smsCodeSent,
//       timeout: const Duration(seconds: 5),
//       verificationCompleted: verifySuccess,
//       verificationFailed: verifyFailed,
//     );
//   }

//   Future<bool> smsCodeDialog(BuildContext context) {
//     return showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (BuildContext context) {
//           return new AlertDialog(
//             title: Text('Enter sms code'),
//             content: TextField(onChanged: (value) {
//               this.smsCode = value;
//             }),
//             contentPadding: EdgeInsets.all(10.0),
//             actions: <Widget>[
//               new FlatButton(
//                   child: Text('Done'),
//                   onPressed: () {
//                     FirebaseAuth.instance.currentUser().then((user) {
//                       if (user != null) {
// //                        Navigator.of(context).pop();
// //                        Navigator.of(context).pushReplacementNamed('/homePage');
// //                        Navigator.of(context).push(MaterialPageRoute<Null>(builder: (BuildContext context) { return new LandingPageApp();}));
//                         Navigator.pushNamed(context, '/homepage');
//                       } else {
//                         Navigator.pop(context);
// //                        signIn();
//                       }
//                     });
//                   })
//             ],
//           );
//         });
//   }

//   signIn() {
//     print("came to sign in page");
//     final AuthCredential credential = PhoneAuthProvider.getCredential(
//       verificationId: verificationId,
//       smsCode: smsCode,
//     );

//     FirebaseAuth.instance.signInWithCredential(credential).then((user) {
//       Navigator.of(context).pushReplacementNamed('/homePage');
//     }).catchError((e) {
//       print(e);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         backgroundColor: Colors.white,
//         body: Container(
//           color: Colors.white,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             mainAxisAlignment: MainAxisAlignment.start,
//             children: <Widget>[
//               Flexible(
//                 flex: 1,
//                 child: new Container(
//                   //color: Colors.white,
//                   height: 200.0,
//                   width: 400.0,
//                   decoration: new BoxDecoration(
//                     image: DecorationImage(
//                       image: new AssetImage('assets/images/download.png'),
//                     ),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 20.0),
//               Padding(
//                 padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
//                 child: TextFormField(
//                     decoration:
//                         InputDecoration(hintText: 'Enter your Phone number'),
//                     keyboardType: TextInputType.phone,
//                     onChanged: (value) {
//                       this.phoneNo = value;
//                     },
//                     validator: (value) =>
//                         value.isEmpty ? 'MobileNo can\'t be empty' : null),
//               ),
//               SizedBox(height: 10.0),
//               RaisedButton(
//                 onPressed: verifyPhone,
//                 child: Text('Verify'),
//                 textColor: Colors.white,
//                 elevation: 7.0,
//                 color: Colors.blue,
//               ),
//               _smsCodeDisabled
//                   ? SizedBox(height: 10.0)
//                   : Column(
//                       mainAxisAlignment: MainAxisAlignment.start,
//                       children: <Widget>[
//                         Padding(
//                           padding: EdgeInsets.symmetric(
//                               horizontal: 20.0, vertical: 16.0),
//                           child: TextFormField(
//                               decoration:
//                                   InputDecoration(hintText: 'Enter OTP'),
//                               keyboardType: TextInputType.number,
//                               onChanged: (value) {
//                                 this.smsCode = value;
//                               },
//                               validator: (value) =>
//                                   value.isEmpty ? 'OTP can\'t be empty' : null),
//                         ),
//                         SizedBox(height: 10.0),
//                         RaisedButton(
//                           onPressed: () {
//                             FirebaseAuth.instance.currentUser().then((user) {
//                               print(["user", user]);
//                               if (user != null) {
//                                 print(user.uid);
//                                 Navigator.of(context).pop();
// //                                    Navigator.of(context).pushReplacementNamed('/homePage');
//                                 Navigator.of(context).push(
//                                     MaterialPageRoute<Null>(
//                                         builder: (BuildContext context) {
//                                   return new LandingPageApp();
//                                 }));
//                               } else {
//                                 print("user is null");
//                                 Navigator.of(context).pop();
//                                 signIn();
//                               }
//                             });
//                           },
//                           child: Text('Done'),
//                           textColor: Colors.white,
//                           elevation: 7.0,
//                           color: Colors.blue,
//                         ),
//                       ],
//                     ),
//               SizedBox(
//                 height: 20.0,
//               ),
//               Column(
//                 children: <Widget>[
//                   Row(children: <Widget>[
//                     Padding(
//                       padding: EdgeInsets.symmetric(
//                           vertical: 16.0, horizontal: 20.0),
//                       child: Text(
//                         'Not a Registered User?',
//                         style: TextStyle(
//                           fontSize: 16,
//                         ),
//                       ),
//                     ),
//                     MaterialButton(
//                       child: Text(
//                         'Register',
//                         style: TextStyle(
//                           color: Colors.black,
//                         ),
//                       ),
//                       //color: Colors.blue,
//                       onPressed: () {
//                         Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (context) => Register()));
//                       },
//                     ),
//                   ]),
//                 ],
//               ),
//             ],
//           ),
//         ));
//   }
// }
//import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:flutter/cupertino.dart';
//import 'package:flutter/material.dart';
//import 'package:flutter/rendering.dart';
//import 'landing_page.dart';
//import 'add_campaigns.dart';
//import 'constributions.dart';
//
//void main() => runApp(MyApp());
//
//class MyApp extends StatelessWidget {
//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(
//      title: 'Switch_board',
//      home: MyHomePage(),
//    );
//  }
//}
//
//class MyHomePage extends StatefulWidget {
//  @override
//  _MyHomePageState createState() {
//    return _MyHomePageState();
//  }
//}
//
//class _MyHomePageState extends State<MyHomePage> {
//  var campaign;
//  var movie, users;
//  var type;
//  final db = Firestore.instance;
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(
//        backgroundColor: Colors.transparent,
//        elevation: 0.0,
//      ),
//      drawer: new Drawer(
//        elevation: 1000,
//        child: new ListView(
//          children: <Widget>[
//            ListTile(
//              leading: Icon(Icons.add_to_queue),
//              title: Text('Add Campaigns'),
//              onTap: () {
//                Navigator.push(
//                  context,
//                  MaterialPageRoute(
//                    builder: (context) => AddCampaignsApp(),
//                  ),
//                );
//              },
//            ),
//            ListTile(
//              leading: Icon(Icons.collections),
//              title: Text('Constributions'),
//              onTap: () {
//                Navigator.push(
//                  context,
//                  MaterialPageRoute(
//                    builder: (context) => ContributionsApp(),
//                  ),
//                );
//              },
//            ),
//          ],
//        ),
//      ),
//      body: SingleChildScrollView(
//        child: Container(
//          child: Column(
//            crossAxisAlignment: CrossAxisAlignment.stretch,
//            mainAxisAlignment: MainAxisAlignment.start,
//            children: <Widget>[
//              Padding(
//                padding: EdgeInsets.only(bottom: 10),
//                child: Image.asset('assets/images/IIITLogo.png'),
//              ),
//              StreamBuilder<QuerySnapshot>(
//                stream: db.collection('Catalog2').snapshots(),
//                builder: (context, snapshot) {
//                  if (!snapshot.hasData) {
//                    return LinearProgressIndicator();
//                  } else {
//                    List<DropdownMenuItem> campaigns = [];
//                    for (int i = 0; i < snapshot.data.documents.length; i++) {
//                      DocumentSnapshot snap = snapshot.data.documents[i];
//                      campaigns.add(
//                        DropdownMenuItem(
//                          child: Text(
//                            snap.documentID,
//                            style: TextStyle(color: Color(0xff212121)),
//                          ),
//                          value: "${snap.documentID}",
//                        ),
//                      );
//                    }
//                    return Column(
//                      crossAxisAlignment: CrossAxisAlignment.center,
//                      mainAxisAlignment: MainAxisAlignment.spaceAround,
//                      children: <Widget>[
//                        Container(
////                          padding: EdgeInsets.all(10),]
//                          decoration: new BoxDecoration(
//                            color: Colors.lightGreen,
//                          ),
//                          child: Padding(
//                            padding: EdgeInsets.all(15),
//                            child: Container(
//                              decoration: new BoxDecoration(
//                                borderRadius: new BorderRadius.circular(16.0),
//                                color: Colors.white,
//                              ),
//                              child: DropdownButton(
////                              style: Theme.of(context).textTheme.title,
//                                items: campaigns,
//                                onChanged: (campaignValue) {
//                                  final snackBar = SnackBar(
//                                    backgroundColor: Color(0xff11b719),
//                                    content: Text(
//                                      'Selected Campaign is $campaignValue',
//                                      style: TextStyle(color: Colors.white),
//                                    ),
//                                  );
//                                  Scaffold.of(context).showSnackBar(snackBar);
//                                  setState(() {
//                                    campaign = campaignValue;
//                                  });
//                                },
//                                value: campaign,
//                                isExpanded: true,
//                                hint: new Center(
//                                  child: new Text(
//                                    "Choose Campaigns",
//                                    style: TextStyle(color: Color(0xff212121)),
//                                  ),
//                                ),
//                              ),
//                            ),
//                          ),
//                        ),
//                        Container(
//                          child: StreamBuilder<QuerySnapshot>(
//                            stream: db
//                                .collection('Catalog2')
//                                .document(campaign).
//                            collection(campaign)
//                                .snapshots(),
//                            builder: (context, snapshot) {
//                              if (!snapshot.hasData) {
//                                return LinearProgressIndicator();
//                              } else {
//                                return new ListView(
//                                  shrinkWrap: true,
//                                  children: snapshot.data.documents.map((
//                                      DocumentSnapshot document) {
//                                    type = document['type'];
////                                    return new ListTile(
////                                      title: new Text(document['topic']),
////                                      subtitle: new Text(document['type']),
////                                    );
//                                    return new Padding(
//                                      padding: EdgeInsets.all(5),
//                                      child: new GestureDetector(
//                                        onTap: () {
//                                          Navigator.push(
//                                            context,
//                                            MaterialPageRoute(
//                                              builder: (context) =>
//                                                  LandingPageApp(),
//                                            ),
//                                          );
//                                        },
//                                        child: Card(
//                                          color: Color(0xffffccbc),
//                                          elevation: 10,
//                                          child: Column(
//                                            crossAxisAlignment:
//                                            CrossAxisAlignment.stretch,
//                                            mainAxisAlignment:
//                                            MainAxisAlignment.spaceEvenly,
//                                            children: <Widget>[
//                                              Text(
//                                                  "   $campaign                                                              $type   "),
//                                              Text(document['topic'],
//                                                  style: TextStyle(
//                                                    fontSize: 30,
//                                                    fontWeight: FontWeight.bold,
//                                                  )),
//                                              Row(
//                                                mainAxisAlignment:
//                                                MainAxisAlignment
//                                                    .spaceEvenly,
//                                                children: <Widget>[
//                                                  Icon(Icons.translate),
//                                                  Text(
//                                                      " English                                        "),
//                                                  Icon(Icons.group),
//                                                  Column(
//                                                    children: <Widget>[
//                                                      Text(document['no_users'].toString()),
//                                                      Text("online")
//                                                    ],
//                                                  ),
//                                                  VerticalDivider(
//                                                    width: 1,
//                                                    thickness: 1,
//                                                  ),
//                                                  Column(
//                                                    mainAxisAlignment:
//                                                    MainAxisAlignment
//                                                        .spaceEvenly,
//                                                    children: <Widget>[
//                                                      Text("3"),
//                                                      Text("hours")
//                                                    ],
//                                                  )
//                                                ],
//                                              )
//                                            ],
//                                          ),
//                                        ),
//                                      ),
//                                    );
//                                  }).toList(),
//                                );
//                              }
//                            },
//                          ),
//                        ),
//                      ],
//                    );
//                  }
//                },
//              ),
//            ],
//          ),
//        ),
//      ),
//    );
//  }
//}