import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:transcribe_calls/routes/auth.dart';
import 'package:transcribe_calls/widgets/landing_page.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Register extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Register Form',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          color: Colors.white,
          child: RegisterPage(),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key key}) : super(key: key);
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _registerFormKey = GlobalKey<FormState>();

  String name;
  String location;
  String mobileno;
  String paymenttype;
  String gendervalue;
  String paymentoptionvalue;
  String language;
  int group = 0;
  int group1 = 0;
  bool registerState = true;
  bool autovalidate;
  bool _validate = false;
  bool isPresent;

  var _languages = ['Telugu', 'English', 'Hindi', 'Others'];
  //final _registerFocusNode = FocusNode();

  //firebase initialisation
  final db = Firestore.instance;

  //final FirebaseAuth _auth = FirebaseAuth.instance;
  //final Firestore _firestore = Firestore.instance;

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
                      'You are a registered user. Login Please.'),
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

  Future<void> numberCheck(String phoneNo,isPresent) async {
    print("Start of the function");
    //bool registerState = false;
    //bool isPresent = false;
    Firestore.instance
        .collection("transcriber_user_registeration")
        .getDocuments()
        .then((QuerySnapshot snapshot) {
      snapshot.documents.forEach((f) async {
        if (isPresent = ('${f.data['mobileno']}' == phoneNo)) {
          _showMessage();
        }
//        else {
//          _saveForm();
//          _sendToServer();
//        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Form(
            key: _registerFormKey,
            autovalidate: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Flexible(
                  flex: 1,
                  child: new Container(
                    //color: Colors.white,
                    height: 150.0,
                    width: 200.0,
                    decoration: new BoxDecoration(
                      image: DecorationImage(
                        image: new AssetImage('assets/images/download.png'),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                  child: TextFormField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person),
                      labelText: 'Name',
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black54)),
                      border: OutlineInputBorder(),
                    ),
                    validator: validateName,
                    onSaved: (String value) => name = value,
                  ),
                ),
//              SizedBox(
//                height: 20.0,
//              ),
                Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 100.0,
                        child: Text(
                          'Gender',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 20.0,
                      ),
                      new Radio(
                        value: 'Male',
                        groupValue: gendervalue,
                        onChanged: (String val) {
                          setGenderValue(val);
                        },
                      ),
                      Text('Male'),
                      Radio(
                        value: 'Female',
                        groupValue: gendervalue,
                        onChanged: (String val) {
                          setGenderValue(val);
                        },
                      ),
                      Text('Female'),
                    ],
                  ),
                ),
//              SizedBox(
//                height: 20.0,
//              ),
                Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                  child: TextFormField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.location_on),
                      labelText: 'Location',
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black54)),
                      border: OutlineInputBorder(),
                    ),
                    validator: validateLocation,
                    onSaved: (value) => location = value,
                  ),
                ),
//              SizedBox(
//                height: 20.0,
//              ),
                Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 250.0,
                        child: Text(
                          'Transcription Language',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      DropdownButton<String>(
                        items: _languages.map((String dropDownStringItem) {
                          return DropdownMenuItem<String>(
                            value: dropDownStringItem,
                            child: Text(dropDownStringItem),
                          );
                        }).toList(),
                        underline: Container(
                          height: 2.0,
                          color: Colors.black54,
                        ),
                        onChanged: (String newValueSelected) {
                          setState(() {
                            this.language = newValueSelected;
                          });
                        },
                        value: language,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                  child: TextFormField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.phone),
                      labelText: 'Mobile no',
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black54)),
                      border: OutlineInputBorder(),
                    ),
                    //textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.number,
                    validator: validateMobile,
                    onSaved: (value) => mobileno = value,
                  ),
                ),
//              SizedBox(
//                height: 20.0,
//              ),
                Text(
                  'Choose a Payment Option',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.black54,
                  ),
                ),
//              SizedBox(
//                height: 20.0,
//              ),
                Padding(
                  padding: EdgeInsets.fromLTRB(15.0, 16.0, 15.0, 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Radio(
                        value: 'Paytm Number',
                        groupValue: paymentoptionvalue,
                        onChanged: (String val) {
                          setPaymentOptionValue(val);
                        },
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Image(
                          image: AssetImage(
                            'assets/logos/Paytm.jpg',
                          ),
                          fit: BoxFit.cover,
                        ),
                        iconSize: 40.0,
                      ),
                      Radio(
                        value: 'GPay Number',
                        groupValue: paymentoptionvalue,
                        onChanged: (String val) {
                          setPaymentOptionValue(val);
                        },
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Image(
                          image: AssetImage(
                            'assets/logos/gpay.png',
                          ),
                          fit: BoxFit.cover,
                        ),
                        iconSize: 40.0,
                      ),
                      Radio(
                        value: 'UPI Id',
                        groupValue: paymentoptionvalue,
                        onChanged: (String val) {
                          setPaymentOptionValue(val);
                        },
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Image(
                          image: AssetImage(
                            'assets/logos/upi.png',
                          ),
                          fit: BoxFit.cover,
                        ),
                        iconSize: 50.0,
                      ),
                    ],
                  ),
                ),

//              SizedBox(
//                height: 20.0,
//              ),
                Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                  child: TextFormField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.payment),
                      hintText: '$paymentoptionvalue',
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black54)),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Please enter a valid number';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a Valid number';
                      }
                      return null;
                    },
                    onSaved: (value) => paymenttype = value,
                  ),
                ),
//              SizedBox(
//                height: 60,
//              ),
                Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                  child: RaisedButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    child: Text(
                      'Register',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    color: Colors.blue,
                    onPressed: () async {
//                      await _saveForm();
//                      _sendToServer();
                      //bool isPresent;
                      await numberCheck(mobileno, isPresent);
                      if (isPresent == true) {
                        _showMessage();
                      } else {
                        await _saveForm();
                        await _sendToServer();
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AuthScreen()));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String validateName(String value) {
    if (value.length < 3)
      return 'Name must be more than 2 characters';
    else
      return null;
  }

  String validateMobile(String value) {
    //Indian Mobile numbers are of 10 digits only.
    if (value.length != 10)
      return 'Mobile number must be of 10 digits';
    else
      return null;
  }

  String validateLocation(String value) {
    if (value.length < 3)
      return 'Location must be more than 2 characters';
    else
      return null;
  }

//  void _saveForm() {
//    final isValid = _registerFormKey.currentState.validate();
//    if (!isValid) {
//      return;
//    }
//    _registerFormKey.currentState.save();
//    print(name);
//    print(gendervalue);
//    print(location);
//    print(language);
//    print(mobileno);
//    print(paymentoptionvalue);
//    print(paymenttype);
//  }

  //Future<void> numberCheck(String mobileno, bool isPresent) async {}

  Future<void> _saveForm() async {
    if (_registerFormKey.currentState.validate()) {
      //If all the data entered is correct then save data to our variables.
      _registerFormKey.currentState.save();
      print(name);
      print(gendervalue);
      print(location);
      print(language);
      print(mobileno);
      print(paymentoptionvalue);
      print(paymenttype);
    }
  }

  setGenderValue(String value) {
    setState(() {
      gendervalue = value;
      print(gendervalue);
    });
  }

  setPaymentOptionValue(String value) {
    setState(() {
      paymentoptionvalue = value;
      print(paymentoptionvalue);
    });
  }

  _sendToServer() async {
    if (_registerFormKey.currentState.validate()) {
      //No error in validator
      _registerFormKey.currentState.save();
      final db = Firestore.instance;

      await db.collection('transcriber_user_registeration').add({
        "userid": "$mobileno",
        "Name": "$name",
        "Gender": "$gendervalue",
        "Location": "$location",
        "Transcription Language": "$language",
        "mobileno": "+91$mobileno",
        "Payment Option": "$paymentoptionvalue",
        "Payment Number": "$paymenttype",
        "user_creation_ts": DateTime.now()
      });
      print("new user added.");
    }
  }
}
