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
