import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transcribe_calls/widgets/approval.dart';
import 'package:transcribe_calls/widgets/payment.dart';
import './reactive_refresh_indicator.dart';
import 'package:http/http.dart';
import './history.dart';
import '../widgets/logger.dart';
import 'package:flutter/animation.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';

typedef void OnError(Exception exception);

enum PlayerState { stopped, playing, paused }

class LandingPageApp extends StatefulWidget {
  @override
  _LandingPageAppState createState() => new _LandingPageAppState();
}

class _LandingPageAppState extends State<LandingPageApp> {
  //variables
  var jobid,
      counter,
      time,
      displayemail,
      url = "",
      data = "",
      newtxt = "",
      oldtxt = "",
      inProgressTxt = "";

  //boolean variables for checking the tasks
  bool _btndisabled = true,
      _isRefreshing = true,
      _isSubmissionInProgress = false,
      _ispressed = false,
      _iscompleted = false;

  bool viewVisible = true;
  bool check;

  void showWidget() {
    setState(() {
      viewVisible = true;
    });
  }

  void hideWidget() {
    setState(() {
      viewVisible != viewVisible;
    });
  }

  AnimationController _animationController;
  bool isPlaying = false;
  //text editing controller
  final TextEditingController _controller = new TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    _controller.dispose();
    super.dispose();
    _animationController.dispose();
  }

  //firebase initialisation
  FirebaseUser user;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Firestore _firestore = Firestore.instance;

  //AudioPlayer variables initialisation
  /// Flutter can only play audios on device folders, so first this class copies the files to a temporary folder, and then plays them.
  /// You can pre-cache your audio, or clear the cache, as desired.

  AudioCache audioCache =
      new AudioCache(); // calling the audiocache function from "audio_cache.dart".
  AudioPlayer advancedPlayer =
      new AudioPlayer(); //creating an instance for audioplayer
  bool isLocal;
  PlayerMode mode;
  AudioPlayerState _audioPlayerState;
  Duration _duration;
  Duration _position;
  PlayerState _playerState = PlayerState.stopped;
  StreamSubscription _durationSubscription;
  StreamSubscription _positionSubscription;
  StreamSubscription _playerCompleteSubscription;
  StreamSubscription _playerErrorSubscription;
  StreamSubscription _playerStateSubscription;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  AudioPlayer _audioPlayer;
  get _isPlaying => _playerState == PlayerState.playing;

  @override
  void initState() {
    logUser().then((res) {
      super.initState();
      _initAudioPlayer();
    }).catchError((e) {
      print(e);
    });
    // Start listening to changes.
    _controller.addListener(_keyStrokeLogger);
  }

  _keyStrokeLogger() {
    newtxt = _controller.text; //The letter or data typed for this instance.
    print([oldtxt, newtxt]);
    if (newtxt != "") {
      setState(() {
        _btndisabled = false;
      });
      _chardifference(oldtxt, newtxt);
    } else {
      setState(() {
        _btndisabled = true;
      });
    }
    oldtxt = newtxt;
  }

  // user defined function
  void _showDialog() {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Confirm"),
          content: new Text("Are you going to skip this job?"),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Yes"),
              onPressed: () {
                oldtxt = "skip";
                setState(() {
                  _btndisabled = false;
                });
                next();
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text("No"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void filler(var text) {
    var cursorPos = _controller.selection;

    _controller.text += text;
    oldtxt = _controller.text;
    cursorPos = new TextSelection.fromPosition(
        new TextPosition(offset: _controller.text.length));
    _controller.selection = cursorPos;

    setState(() {
      _btndisabled = false;
    });
  }

  void _handleOnPressed() {
    setState(() {
      isPlaying = !isPlaying;
      isPlaying
          ? _animationController.forward()
          : _animationController.reverse();
    });
  }

  // player() widget represents the audio player  i.e., play and skip
  Widget player() {
    return new Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        new Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Play icon - used to play the audio fragment.
            // IconButton(
            //     iconSize: 64,
            //     icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            //     onPressed: () => _handleOnPressed(),
            //   ),
            // IconButton(
            //     iconSize: 64,
            //     icon: AnimatedIcon(
            //       icon: AnimatedIcons.play_pause,
            //       progress: _animationController,
            //     ),
            //     onPressed: () => _handleOnPressed(),
            //   ),
            new IconButton(
                onPressed: _isPlaying ? null : () => _play(),
                padding: EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
                iconSize: 64.0,
                icon: new Icon(Icons.play_arrow),
                color: Colors.cyan),

            //Skip Icon- used to skip the job
            // new IconButton(
            //     onPressed: () {
            //       Logger.log("app_debug", message: "forward button pressed");
            //     },
            //     iconSize: 64.0,
            //     icon: new Icon(Icons.last_page),
            //     color: Colors.blueAccent),
          ],
        ),

        //This row indicates the  CircularProgressIndicator icon and its progress based on the application state.
        // new Row(
        //   mainAxisSize: MainAxisSize.min,
        //   children: [
        //     new Padding(
        //       padding: new EdgeInsets.all(12.0),
        //       child: new Stack(
        //         children: [
        //           new CircularProgressIndicator(
        //             //This is used not playing i.e, initial state and end state.
        //             value: 1.0,
        //             valueColor: new AlwaysStoppedAnimation(Colors.grey[300]),
        //           ),
        //           new CircularProgressIndicator(
        //             //this is used when the audio is playing.
        //             value: (_position != null &&
        //                     _duration != null &&
        //                     _position.inMilliseconds > 0 &&
        //                     _position.inMilliseconds < _duration.inMilliseconds)
        //                 ? _position.inMilliseconds / _duration.inMilliseconds
        //                 : 0.0,
        //             valueColor: new AlwaysStoppedAnimation(Colors.blue),
        //           ),
        //         ],
        //       ),
        //     ),
        //   ],
        // ),
      ],
    );
  }

  // _updateCount() is used to update the count of the number of jobs done by the user for each instance.
  Future<void> _updateCount() async {
    var query = _firestore
        .collection('jobs')
        .where('user', isEqualTo: '/users/' + user.uid)
        .where('status', isEqualTo: 'done');
    var qs = await query.getDocuments();
    print(qs.documents.length);
    setState(() {
      counter = qs.documents.length;
    });
  }

  // _assignJob() is used to assign a job for the user by sending a post request to the cloud function
  Future<void> _assignJob() async {
    setState(() {
      this._isRefreshing =
          true; //Updating the boolean value to false if the job is not assigned to the user.
    });

    // uri is the link for the assignJob cloud function.
    final uri =
        'https://us-central1-audio-transcription-b2285.cloudfunctions.net/assignJobUid';

    // headers is the type in which the content is sent to the cloud fucntion.
    final headers = {'Content-Type': 'application/json'};

    // storing the email id of the user in the body of the json data.
    Logger.log("app_debug", message: "userid " + user.uid);
    Map<String, dynamic> body = {'userid': user.uid};

    // jsonBody is the encoded version of the email id
    String jsonBody = json.encode(body);

    // the format in which the json data is encoded.
    final encoding = Encoding.getByName('utf-8');

    //send a post request and waiting for the response and storing it in "response" variable.
    Response response = await post(
      uri,
      headers: headers,
      body: jsonBody,
      encoding: encoding,
    );
    Logger.log("app_debug", message: "_assignJob");
    Logger.log("app_debug", message: response.body);

    //checking the status code
    if (response.statusCode == 200) {
      // if success
      // getting the jobid from the json body.
      jobid = jsonDecode(response.body)[
          "jobid"]; // condition might not work for few situations.
      Logger.log("app_debug", message: "jobid");
      Logger.log("app_debug", message: jobid);
      var query = _firestore.collection('jobs').document(
          jobid); // query to get the documents of "jobs" collection using "jobid" from firestore.
      var doc = await query
          .get(); // getting the documents in the collection "jobs" using the query.
      var job = doc.data; // getting the data from the documents.
      // query to get the "fragment" field from "fragments" collection using "fragment id" in the current job from firestore.
      query = _firestore
          .collection('fragments')
          .document(job['fragment'].split('/')[2]);
      doc = await query.get(); //executing the query
      print("----------------------------");
      print(doc.data);
      setState(() {
        // updating the url for each instance which we get from the fragments collection.
        this.url = doc.data['url'];
        this._isRefreshing =
            false; // updating the "_isRefreshing" to false i.e., the refreshing is done.
        _initAudioPlayer(); //calling the "_initAudioPlayer" function.
      });
    } else if (response.statusCode == 404) {
      //if not success i.e., there are no jobs left.
      Logger.log("app_debug", message: "response is unsucessful");
      Logger.log("app_debug", message: "body: " + response.body);
      Logger.log("app_debug",
          message: "statuscode: " + response.statusCode.toString());
      if (['No fragments to assign a job.', 'No Fragments']
          .contains(response.body)) {
        setState(() {
          _iscompleted = true; //updating the boolean "_iscompleted" to true.
        });
      }
      return;
    } else {
      //If there is another status code other than 200 or 404 then
      Logger.log("app_debug", message: "body: " + response.body);
      Logger.log("app_debug",
          message: "statuscode: " + response.statusCode.toString());
      return; // return null
    }
  }

  // logUser() function is implemented to check whether the user is logged in and once signed in then storing the email in users collection, assign a job to that user and also update the count of jobs.
  Future<void> logUser() async {
    user = await _auth.currentUser(); // wait till we get the current user.
    await _firestore.collection('users').document(user.uid).setData(
        {"email": user.email},
        merge: true); // store the email in the users collection.
    await _assignJob(); // assign a job
    await _updateCount(); //updating the count
    displayemail =
        user.email; //Storing the user email to display in side menu bar
  }

  // _text() is used to get the fragment id i.e., mkbid
  Widget _text() {
    var t = this.url.split("/"); // split the url using '/'
    var s = t[t.length - 1].split(".")[0]; //getting the mkbid from the url.
    return Text(s);
  }

  // Player Controls
  Future<int> _play() async {
    // start the audio play only when the position and duration are null.
    final playPosition = (_position != null &&
            _duration != null &&
            _position.inMilliseconds > 0 &&
            _position.inMilliseconds < _duration.inMilliseconds)
        ? _position // if it is null then return position
        : null; //else return null
    final result = await _audioPlayer.play(url,
        isLocal: isLocal,
        position: playPosition); //waiting for the audio to play.
    if (result == 1)
      setState(() => _playerState =
          PlayerState.playing); // audio plays when it loads to local path.
    return result;
  }

  // tracking the difference between old and new texts
  _chardifference(String str1, String str2) {
    var i = 0;
    var j = str1.length - 1;
    var k = str2.length - 1;
    print([i, j, k]);
    while (i < str1.length && i < str2.length && str1[i] == str2[i]) {
      i++;
    }
    print([i, j, k]);

    while (j >= 0 && k >= 0 && str1[j] == str2[k]) {
      j--;
      k--;
    }
    print([i, j, k]);
    time = new DateTime.now()
        .millisecondsSinceEpoch; // Unix time (also known as POSIX time or UNIX Epoch time) is a system for describing a point in time. It is the number of seconds that have elapsed since 00:00:00 Thursday, 1 January 1970, Coordinated Universal Time (UTC), minus leap seconds.

    if (str1.length < str2.length) {
      print(["beforeif", i, str2, str2.length, k + 1]);
      print(str2.substring(i, k + 1));
      if (str2.substring(i, k + 1) == " ") {
        data += "INSERT|SP" +
            "|$time" +
            "|$str2" +
            "\n"; // If space then updating it to the "data" string.
      } else {
        data +=
            "INSERT|" + str2.substring(i, k + 1) + "|$time" + "|$str2" + "\n";
      }
      print(["ifelse", i, j, k]);
    } else {
      print(["beforeelse", i, str1.length, j + 1]);
      print(str1.substring(i, j + 1));
      if (str1.substring(i, j + 1) == " ") {
        data += "DELETE|SP" +
            "|$time" +
            "|$str2" +
            "\n"; // If space then updating it to the "data" string.
      } else {
        data += "DELETE|" +
            str1.substring(i, j + 1) +
            "|$time" +
            "|$str2" +
            "\n"; //If not then updating the character to the "data" string.
        print(["elseelse", i, j, k]);
      }
    }
    print(["end", i, j, k]);
  }

  // Widget remoteUrl() {
  //   return SingleChildScrollView(
  //     // Scroll view the whole page
  //     child: !_iscompleted
  //         ? Column(
  //             // Only if there are jobs left for a user this displays.
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             crossAxisAlignment: CrossAxisAlignment.stretch,
  //             children: <Widget>[
  //                 // Display the mkbid.
  //                 // new Card(
  //                 //   child: _text(),
  //                 // ),

  //                 //Display the audio player which includes the play button and skip button
  //                 new Card(
  //                   color: Colors.white,
  //                   child: Row(
  //                     mainAxisAlignment: MainAxisAlignment.center,
  //                     children: <Widget>[
  //                       player(),
  //                       new SizedBox(
  //                           height: 50.0,
  //                           width: 50.0,
  //                           child: new IconButton(
  //                             padding: new EdgeInsets.all(0.0),
  //                             icon: new Icon(Icons.skip_next, size: 50.0),
  //                             onPressed: () {
  //                               _showDialog(); // Calling the next method.
  //                                     },
  //                             color: Colors.cyan,

  //                           )),

  //                     ]),
  //                 ),

  //                 // Display the text field where user can type the input and submit.
  //                 new Card(
  //                   child: Row(
  //                     children: <Widget>[
  //                       new Flexible(
  //                         child: new TextField(
  //                           // A TextField widget allows collection of information from the user.
  //                           //Since TextFields do not have an ID like in Android, text cannot be retrieved upon demand and must instead be stored in a variable on change or use a controller.
  //                           // I have used the onChanged method and store the current value in a simple variable.
  //                           //on changed text
  //                           controller: _controller,
  //                           keyboardType: TextInputType.multiline,
  //                           maxLines:
  //                               5, // Number of lines in the text field.
  //                           autofocus: true,
  //                           decoration: new InputDecoration.collapsed(
  //                               hintText: 'Start typing here...'),
  //                           style: new TextStyle(
  //                               fontSize:
  //                                   16.0), //Font size for the text field to write the text.
  //                         ),
  //                       ),

  //                       //Submit button
  //                       new SizedBox(
  //                           height: 50.0,
  //                           width: 50.0,
  //                           child: new IconButton(
  //                             padding: new EdgeInsets.all(0.0),
  //                             icon: new Icon(Icons.send, size: 50.0),
  //                             onPressed: _btndisabled
  //                                 ? null
  //                                 : () {
  //                                     setState(() {
  //                                       next(); // Calling the next method.
  //                                     });
  //                                   },
  //                           )),
  //                     ],
  //                   ),
  //                 ),
  //                 new Card(
  //                   //height: 370.0,
  //                   child: Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                       children: <Widget>[
  //                     // new RaisedButton(
  //                     //     child: const Text('Noise'),
  //                     //     onPressed: () => filler("/noise/"),
  //                     //     color: Colors.amber[300]),
  //                     // RaisedButton(
  //                     //     child: const Text('Skip Job'),
  //                     //     onPressed: () {
  //                     //       _showDialog();
  //                     //     },
  //                     //     color: Colors.amber[300]),
  //                     ButtonTheme(
  //                       height: 60.0,
  //                       minWidth: 340.0,
  //                       child: RaisedButton(

  //                         child: const Text('Non Verbal Keyboard',
  //                         style: TextStyle(color: Colors.black45, fontSize: 24.0),),
  //                           color: Colors.white,
  //                           onPressed: () {
  //                             setState(() {
  //                               _ispressed = true;
  //                             });
  //                           },
  //                         ),
  //                       ),
  //                       //Submit button
  //                     new SizedBox(
  //                         height: 50.0,
  //                         width: 50.0,
  //                         child: new IconButton(
  //                           padding: new EdgeInsets.all(0.0),
  //                           icon: new Icon(Icons.keyboard_hide, size: 50.0),
  //                           onPressed: _btndisabled
  //                               ? null
  //                               : () {
  //                                   setState(() {
  //                                     next(); // Calling the next method.
  //                                   });
  //                                 },
  //                           )),
  //                       ],
  //                     ),
  //                 ),
  //                 // new Card(
  //                 //   child: new Container(
  //                 //     child:Column(
  //                 //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                 //       children: <Widget>[
  //                 //         new Container(
  //                 //           child: new Row(
  //                 //             crossAxisAlignment: CrossAxisAlignment.start,
  //                 //             children: <Widget>[
  //                 //               Flexible(
  //                 //                 flex: 1, child: CustomButton(("Noise"), onPressed: (){filler("/noise");},),
  //                 //               ),
  //                 //               Flexible(
  //                 //                 flex: 1, child: CustomButton(("Noise"), onPressed: (){filler("/noise");},),
  //                 //               ),
  //                 //               Flexible(
  //                 //                 flex: 1, child: CustomButton(("Noise"), onPressed: (){filler("/noise");},),
  //                 //               ),
  //                 //               Flexible(
  //                 //                 flex: 1, child: CustomButton(("Noise"), onPressed: (){filler("/noise");},),
  //                 //               ),
  //                 //               ],
  //                 //             ),
  //                 //           ),
  //                 //         ],
  //                 //       ),
  //                 //     )
  //                 //   )
  //                 ],
  //               )
  //         : Text(
  //             "All jobs are completed."), // Displayed when all the jobs are done for the user.
  //   );
  // }

  Future<bool> _onBackPressed() {
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Do you really want to exit the app?'),
              actions: <Widget>[
                FlatButton(
                  child: Text('No'),
                  onPressed: () => Navigator.pop(context, false),
                ),
                FlatButton(
                  child: Text('Yes'),
                  onPressed: () => exit(0),
                ),
              ],
            ));
  }

  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
          resizeToAvoidBottomPadding: false,
          drawer: Drawer(
              child: new ListView(
            children: <Widget>[
              // Displays the email id of the respective user.
//              new ListTile(
//                title: new Text(displayemail.toString()),
//              ),

              //Displays the performance of the user.
              new ListTile(
                title: new Text('Profile'),
                onTap: () {},
              ),

              // Displays the history i.e., the deliverables for a user.
              new ListTile(
                title: new Text('History'),
                onTap: () {
                  Navigator.of(context).push(
                      MaterialPageRoute<Null>(builder: (BuildContext context) {
                    return new HistoryWidget();
                  }));
                },
              ),

              new ListTile(
                title: new Text('Payments'),
                onTap: () {
                  Navigator.of(context).push(
                      MaterialPageRoute<Null>(builder: (BuildContext context) {
                        return new PaymentWidget();
                      }));
                },
              ),

              //About is used to display the text about the app i.e., versions, updates etc.
              new ListTile(
                title: new Text('About'),
                onTap: () {},
              ),
              new Divider(),
            ],
          )),
          appBar: AppBar(
            title: Text("Transcription"),
            actions: <Widget>[
              // Chips are compact elements that represent an attribute, text, entity, or action.
              //Chip here is used to display the count of jobs done.
              Chip(
                label: Text('$counter Jobs done'),
              ),
            ],
          ),
          body: Container(
              color: Colors.white,
              //height: 650.0,
              child: SingleChildScrollView(
                child: ReactiveRefreshIndicator(
                  onRefresh:
                      _onRefresh, // Checking if the refresh is done or not.
                  isRefreshing:
                      _isRefreshing, // updating the "_isRefreshing" based on the applicaition status.
                  child: Container(
                      height: 650.0,
                      color: Colors.white,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Container(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: <Widget>[
                                    new Card(
                                      child: _text(),
                                    ),
                                    SizedBox(height: 10.0),
//                                      color: Colors.white,
//                                      shape: RoundedRectangleBorder(
//                                        side: BorderSide(
//                                            color: Colors.black12, width: 1),
//                                        borderRadius: BorderRadius.circular(10),
//                                      ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: <Widget>[
                                            SizedBox(child: player()),
                                            SizedBox(
                                              height: 50.0,
                                              width: 50.0,
                                              child: new IconButton(
                                                padding:
                                                    new EdgeInsets.fromLTRB(
                                                        0.0, 0.0, 0.0, 40.0),
                                                icon: new Icon(Icons.skip_next,
                                                    size: 64.0),
                                                onPressed: () {
                                                  _showDialog(); //Calling the next method.
                                                },
                                                color: Colors.cyan,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: <Widget>[
                                            SizedBox(width: 120.0),
                                            Text('Play'),
                                            SizedBox(width: 130.0),
                                            Text('Skip Job'),
                                          ],
                                        ),
                                      ],
                                    ),
//                                    SizedBox(
//                                      height: 10.0,
//                                    ),
                                    new Card(
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        side: BorderSide(
                                            color: Colors.black12, width: 1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          new Flexible(
                                            child: new TextField(
                                              // A TextField widget allows collection of information from the user.
                                              //Since TextFields do not have an ID like in Android, text cannot be retrieved upon demand and must instead be stored in a variable on change or use a controller.
                                              // I have used the onChanged method and store the current value in a simple variable.
                                              //on changed text
                                              controller: _controller,
                                              keyboardType:
                                                  TextInputType.multiline,
                                              maxLines:
                                                  4, // Number of lines in the text field.
                                              autofocus: true,
                                              textAlign: TextAlign.center,
                                              decoration: new InputDecoration
                                                      .collapsed(
                                                  hintText:
                                                      'Start typing here...'),
                                              style: new TextStyle(
                                                  fontSize:
                                                      16.0), //Font size for the text field to write the text.
                                            ),
                                          ),

                                          //Submit button
                                          new SizedBox(
                                              height: 50.0,
                                              width: 50.0,
                                              child: new IconButton(
                                                //alignment: Alignment.centerRight,
                                                padding:
                                                    new EdgeInsets.all(0.0),
                                                icon: new Icon(Icons.send,
                                                    size: 40.0),
                                                onPressed: _btndisabled
                                                    ? null
                                                    : () {
                                                        setState(() async {
                                                          await next();
                                                          Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          ApprovalPageApp())); // Calling the next method.
                                                        });
                                                      },
                                              )),
                                        ],
                                      ),
                                    ),
                                    //SizedBox(height: 10.0),
                                    SizedBox(
                                      height: 60.0,
                                      child: new Card(
//                                        color: Colors.white,
//                                        shape: RoundedRectangleBorder(
//                                          side: BorderSide(
//                                              color: Colors.black12, width: 1),
//                                          borderRadius:
//                                              BorderRadius.circular(10),
//                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: <Widget>[
                                            Container(
                                              width: 330.0,
                                              child: Text(
                                                'This audio sample contains Wrong Pronunciation.',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 20.0),
                                            new Checkbox(
                                                value: _isChecked,
                                                onChanged: (val) {
                                                  setState(() {
                                                    check = true;
                                                    _isChecked = val;
                                                  });
                                                  Text('Wrong Pronunciation');
                                                }),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 10.0),
                                    new Card(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          new SizedBox(width: 40.0),
                                          ButtonTheme(
                                            child: FlatButton(
                                              child: const Text(
                                                'Non Verbal Keyboard',
                                                style: TextStyle(
                                                    color: Colors.black45,
                                                    fontSize: 24.0),
                                              ),
                                              color: Colors.white,
                                              onPressed: () {
                                                setState(() =>
                                                    viewVisible = !viewVisible);
                                                hideWidget();
                                              },
                                            ),
                                          ),
                                          //Submit button
                                          new SizedBox(width: 39.0),
                                          new Padding(
                                              padding: EdgeInsets.fromLTRB(
                                                  0.0, 0.0, 15.0, 0.0),
                                              child: new SizedBox(
                                                  height: 40.0,
                                                  width: 50.0,
                                                  child: new IconButton(
                                                      alignment:
                                                          Alignment.centerRight,
                                                      padding:
                                                          new EdgeInsets.all(
                                                              0.0),
                                                      icon: new Icon(
                                                          Icons.keyboard_hide,
                                                          size: 35.0),
                                                      onPressed: () {
                                                        setState(() =>
                                                            viewVisible =
                                                                !viewVisible);
                                                        hideWidget();
                                                      }))),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 10.0,
                                    ),
                                    SingleChildScrollView(
                                      padding: new EdgeInsets.fromLTRB(
                                          10.0, 16.0, 10.0, 10.0),
                                      child: Visibility(
                                        maintainSize: true,
                                        maintainAnimation: true,
                                        maintainState: true,
                                        visible: viewVisible,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            new Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: <Widget>[
                                                SizedBox(
                                                  height: 40.0,
                                                  width: 70.0,
                                                  child: RaisedButton(
                                                    child: Text(
                                                      'noise',
                                                      style: TextStyle(
                                                          fontSize: 12.0),
                                                    ),
                                                    onPressed: () {
                                                      filler('/noise');
                                                    },
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 15.0,
                                                ),
                                                SizedBox(
                                                  height: 40.0,
                                                  width: 70.0,
                                                  child: RaisedButton(
                                                    child: Text(
                                                      'laugh',
                                                      style: TextStyle(
                                                          fontSize: 12.0),
                                                    ),
                                                    onPressed: () {
                                                      filler('/laugh');
                                                    },
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 15.0,
                                                ),
                                                SizedBox(
                                                  height: 40.0,
                                                  width: 70.0,
                                                  child: RaisedButton(
                                                    child: Text(
                                                      'cough',
                                                      style: TextStyle(
                                                          fontSize: 12.0),
                                                    ),
                                                    onPressed: () {
                                                      filler('/cough');
                                                    },
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 15.0,
                                                ),
                                                SizedBox(
                                                  height: 40.0,
                                                  width: 70.0,
                                                  child: RaisedButton(
                                                    child: Text(
                                                      'sneeze',
                                                      style: TextStyle(
                                                          fontSize: 11.0),
                                                    ),
                                                    onPressed: () {
                                                      filler('/sneeze');
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              height: 15.0,
                                            ),
                                            new Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: <Widget>[
                                                SizedBox(
                                                  height: 40.0,
                                                  width: 70.0,
                                                  child: RaisedButton(
                                                    child: Text(
                                                      'unknown',
                                                      style: TextStyle(
                                                          fontSize: 9.0,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    onPressed: () {
                                                      filler('/unknown');
                                                    },
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 15.0,
                                                ),
                                                SizedBox(
                                                  height: 40.0,
                                                  width: 70.0,
                                                  child: RaisedButton(
                                                    child: Text(
                                                      'cold',
                                                      style: TextStyle(
                                                          fontSize: 12.0),
                                                    ),
                                                    onPressed: () {
                                                      filler('/cold');
                                                    },
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 15.0,
                                                ),
                                                SizedBox(
                                                  height: 40.0,
                                                  width: 70.0,
                                                  child: RaisedButton(
                                                    child: Text(
                                                      'oh',
                                                      style: TextStyle(
                                                          fontSize: 12.0),
                                                    ),
                                                    onPressed: () {
                                                      filler('/oh');
                                                    },
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 15.0,
                                                ),
                                                SizedBox(
                                                  height: 40.0,
                                                  width: 70.0,
                                                  child: RaisedButton(
                                                    child: Text(
                                                      'shh',
                                                      style: TextStyle(
                                                          fontSize: 12.0),
                                                    ),
                                                    onPressed: () {
                                                      filler('/shh/');
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 15.0),
                                            new Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: <Widget>[
                                                SizedBox(
                                                  height: 40.0,
                                                  width: 70.0,
                                                  child: RaisedButton(
                                                    child: Text(
                                                      'ee',
                                                      style: TextStyle(
                                                          fontSize: 12.0),
                                                    ),
                                                    onPressed: () {
                                                      filler('/ee');
                                                    },
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 15.0,
                                                ),
                                                SizedBox(
                                                  height: 40.0,
                                                  width: 70.0,
                                                  child: RaisedButton(
                                                    child: Text(
                                                      'aaa',
                                                      style: TextStyle(
                                                          fontSize: 12.0),
                                                    ),
                                                    onPressed: () {
                                                      filler('/aaa');
                                                    },
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 15.0,
                                                ),
                                                SizedBox(
                                                  height: 40.0,
                                                  width: 70.0,
                                                  child: RaisedButton(
                                                    child: Text(
                                                      'haan',
                                                      style: TextStyle(
                                                          fontSize: 12.0),
                                                    ),
                                                    onPressed: () {
                                                      filler('/haan');
                                                    },
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 15.0,
                                                ),
                                                SizedBox(
                                                  height: 40.0,
                                                  width: 70.0,
                                                  child: RaisedButton(
                                                    child: Text(
                                                      'hmm',
                                                      style: TextStyle(
                                                          fontSize: 12.0),
                                                    ),
                                                    onPressed: () {
                                                      filler('/hmm');
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 15.0),
                                            new Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: <Widget>[
                                                SizedBox(
                                                  height: 40.0,
                                                  width: 70.0,
                                                  child: RaisedButton(
                                                    child: Text(
                                                      'arey',
                                                      style: TextStyle(
                                                          fontSize: 12.0),
                                                    ),
                                                    onPressed: () {
                                                      filler('/arey');
                                                    },
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 15.0,
                                                ),
                                                SizedBox(
                                                  height: 40.0,
                                                  width: 70.0,
                                                  child: RaisedButton(
                                                    child: Text(
                                                      'oho',
                                                      style: TextStyle(
                                                          fontSize: 12.0),
                                                    ),
                                                    onPressed: () {
                                                      filler('/oho');
                                                    },
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 15.0,
                                                ),
                                                SizedBox(
                                                  height: 40.0,
                                                  width: 70.0,
                                                  child: RaisedButton(
                                                    child: Text(
                                                      'oye',
                                                      style: TextStyle(
                                                          fontSize: 12.0),
                                                    ),
                                                    onPressed: () {
                                                      filler('/oye');
                                                    },
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 15.0,
                                                ),
                                                SizedBox(
                                                  height: 40.0,
                                                  width: 70.0,
                                                  child: RaisedButton(
                                                    child: Text(
                                                      'ahh',
                                                      style: TextStyle(
                                                          fontSize: 12.0),
                                                    ),
                                                    onPressed: () {
                                                      filler('/ahh/');
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 15.0),
                                            new Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: <Widget>[
                                                SizedBox(
                                                  height: 40.0,
                                                  width: 70.0,
                                                  child: RaisedButton(
                                                    child: Text(
                                                      'shh',
                                                      style: TextStyle(
                                                          fontSize: 12.0),
                                                    ),
                                                    onPressed: () {
                                                      filler('/shh');
                                                    },
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 15.0,
                                                ),
                                                SizedBox(
                                                  height: 40.0,
                                                  width: 70.0,
                                                  child: RaisedButton(
                                                    child: Text(
                                                      'che',
                                                      style: TextStyle(
                                                          fontSize: 12.0),
                                                    ),
                                                    onPressed: () {
                                                      filler('/che');
                                                    },
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 15.0,
                                                ),
                                                SizedBox(
                                                  height: 40.0,
                                                  width: 70.0,
                                                  child: RaisedButton(
                                                    child: Text(
                                                      'oops',
                                                      style: TextStyle(
                                                          fontSize: 12.0),
                                                    ),
                                                    onPressed: () {
                                                      filler('/oops');
                                                    },
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 15.0,
                                                ),
                                                SizedBox(
                                                  height: 40.0,
                                                  width: 70.0,
                                                  child: RaisedButton(
                                                    child: Text(
                                                      'ho',
                                                      style: TextStyle(
                                                          fontSize: 12.0),
                                                    ),
                                                    onPressed: () {
                                                      filler('/ho/');
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ]),
                            ),
                          ])),
                ),
              ))),
    );
  }

  // This function is used to update the values in "jobs" collection for respective "jobid".
  submit() async {
    bool submitted;
    var res;
    //check whether there is any wrong pronounciation or not in the fragment
    if (check == true) {
      res = 'present';
    } else {
      res = 'absent';
    }

    await Firestore.instance.collection('jobs').document(jobid).updateData({
      'submission_ts': Timestamp.now(),
      'log_data': data,
      'deliverable': oldtxt,
      'status': 'done',
      'wrong pronunciation': res
    }).catchError((e) {
      Logger.log("app_debug", message: e);
      submitted = false;
    }).then((value) {
      Logger.log("app_debug", message: "inside then");
      submitted = true;
    }).catchError((e) {
      Logger.log("app_debug", message: "Future failed" + e);
      submitted = false;
    });
    return submitted;
  }

  // this function is asynchronous and used to update the count of jobs done and assign a job for the user which is not submitted.
  next() async {
    setState(() {
      _btndisabled = true;
      _isSubmissionInProgress = true;
    });
    Logger.log("app_debug", message: "deliverable: " + oldtxt);
    Logger.log("app_debug", message: "log_data: " + data);
    if ([""].contains(oldtxt)) {
      return;
    }
    bool isSubmitted = await submit(); // submission is done.
    if (!isSubmitted) {
      Logger.log("app_debug", message: "Deliverable submission failed.");
      inProgressTxt = "Deliverable submission failed.";
      return;
    }
    Logger.log("app_debug", message: "Deliverable submission successful.");
    inProgressTxt = "Deliverable submission successful.";
    _updateCount(); // count of jobs is updated.
    _controller.clear(); // clear the text in text field.
    data = ""; // make the string null.
    oldtxt = "";
    newtxt = "";
    _initAudioPlayer(); // initiate the audio player.
    await _assignJob(); // assign a job.
    setState(() {
      _isSubmissionInProgress = false;
    });
  }

  // Checking if the refreshing is happening or not  #debug
  Future<Null> _onRefresh() async {
    print('refreshing ;)');
  }

  // Function to represent the audio player.
  void _initAudioPlayer() {
    this.isLocal = false;
    this.mode = PlayerMode.MEDIA_PLAYER;
    _audioPlayer = new AudioPlayer(mode: mode);

    // States to represent audio playback.

    // checking the duration of the audio clip.
    _durationSubscription =
        _audioPlayer.onDurationChanged.listen((duration) => setState(() {
              _duration = duration;
            }));

    //Status and current position
    //The dart part of the plugin listen for platform calls
    _positionSubscription =
        _audioPlayer.onAudioPositionChanged.listen((p) => setState(() {
              _position = p;
            }));

    // if the audio play is completed.
    _playerCompleteSubscription =
        _audioPlayer.onPlayerCompletion.listen((event) {
      _onComplete();
      setState(() {
        _position = _duration;
      });
    });

    //when the player stops
    _playerErrorSubscription = _audioPlayer.onPlayerError.listen((msg) {
      setState(() {
        _playerState = PlayerState.stopped;
        _duration = new Duration(seconds: 0);
        _position = new Duration(seconds: 0);
      });
    });

    // Do not forget to cancel all the subscriptions when the widget is disposed.
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _audioPlayerState =
            state; //checking the state of the player whether it is stopped or playing.
      });
    });
  }

  //Checking if the audio play is completed or not.
  void _onComplete() {
    setState(() =>
        _playerState = PlayerState.stopped); //set the player state to null
  }
}

// Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: <Widget>[
//                   Visibility(
//                     maintainSize: true,
//                     maintainAnimation: true,
//                     maintainState: true,
//                     visible: viewVisible,
//                     child: Row(
//                       children: <Widget>[
//                         ButtonTheme(
//                           child: RaisedButton(
//                             child: const Text('Noise',
//                             style: TextStyle(color: Colors.black45, fontSize:24.0),),
//                             color: Colors.white,
//                             onPressed: () {
//                               setState(() {
//                                 _ispressed = true;
//                                 filler('/noise/');
//                               });
//                             },
//                           ),),
//                         SizedBox(width: 10.0,),
//                         ButtonTheme(
//                           child: RaisedButton(
//                             child: const Text('Han',
//                             style: TextStyle(color: Colors.black45, fontSize:24.0),),
//                             color: Colors.white,
//                             onPressed: () {
//                               setState(() {
//                                 _ispressed = true;
//                                 filler('/han/');
//                                 });
//                               },
//                             ),
//                           ),
//                         SizedBox(width: 10.0,),
//                         ButtonTheme(
//                           child: RaisedButton(
//                             child: const Text('Hun',
//                             style: TextStyle(color: Colors.black45, fontSize:24.0),),
//                             color: Colors.white,
//                             onPressed: () {
//                               setState(() {
//                                 _ispressed = true;
//                                 filler('/hun/');
//                               });
//                             },
//                           ),
//                           ),
//                         ],
//                       ),
//                       ),
//                   SizedBox(height: 10.0,),
//                   Visibility(
//                     maintainSize: true,
//                     maintainAnimation: true,
//                     maintainState: true,
//                     visible: viewVisible,
//                     child: Row(
//                       children: <Widget>[
//                         ButtonTheme(
//                           child: RaisedButton(
//                             child: const Text('mmm',
//                             style: TextStyle(color: Colors.black45, fontSize:24.0),),
//                             color: Colors.white,
//                             onPressed: () {
//                               setState(() {
//                                 _ispressed = true;
//                                 filler('/mmm/');
//                               });
//                               },
//                             ),
//                           ),
//                         SizedBox(width: 10.0,),
//                         ButtonTheme(
//                             child: RaisedButton(
//                               child: const Text('Han',
//                               style: TextStyle(color: Colors.black45, fontSize:24.0),),
//                               color: Colors.white,
//                               onPressed: () {
//                                 setState(() {
//                                   _ispressed = true;
//                                   filler('/han/');
//                                   });
//                                 },
//                               ),
//                             ),
//                         SizedBox(width: 10.0,),
//                         ButtonTheme(
//                             child: RaisedButton(
//                               child: const Text('Hun',
//                               style: TextStyle(color: Colors.black45, fontSize:24.0),),
//                               color: Colors.white,
//                               onPressed: () {
//                                 setState(() {
//                                   _ispressed = true;
//                                   filler('/hun/');
//                                 });
//                               },
//                             ),
//                             ),
//                           ],
//                         ),
//                       ),
//                   SizedBox(height: 10.0,),
//                   Visibility(
//                     maintainSize: true,
//                     maintainAnimation: true,
//                     maintainState: true,
//                     visible: viewVisible,
//                     child: Row(
//                       children: <Widget>[
//                         ButtonTheme(
//                           child: RaisedButton(
//                             child: const Text('Noise',
//                             style: TextStyle(color: Colors.black45, fontSize:24.0),),
//                             color: Colors.white,
//                             onPressed: () {
//                               setState(() {
//                               _ispressed = true;
//                               filler('/noise/');
//                             });
//                           },
//                         ),
//                       ),
//                         SizedBox(width: 10.0,),
//                         ButtonTheme(
//                           child: RaisedButton(
//                             child: const Text('Han',
//                             style: TextStyle(color: Colors.black45, fontSize:24.0),),
//                             color: Colors.white,
//                             onPressed: () {
//                               setState(() {
//                                 _ispressed = true;
//                                 filler('/han/');
//                                 });
//                               },
//                             ),
//                           ),
//                         SizedBox(width: 10.0,),
//                         ButtonTheme(
//                           child: RaisedButton(
//                             child: const Text('Hun',
//                             style: TextStyle(color: Colors.black45, fontSize:24.0),),
//                             color: Colors.white,
//                             onPressed: () {
//                             filler('/hun/');
//                         },
//                       ),
//                     ),
//                       ],
//                     ),
//                   ),
//                   SizedBox(height: 10.0),
//                   Visibility(
//                     maintainSize: true,
//                     maintainAnimation: true,
//                     maintainState: true,
//                     visible: viewVisible,
//                     child: Row(
//                       children: <Widget>[
//                         ButtonTheme(
//                           child: RaisedButton(
//                             child: const Text('Noise',
//                             style: TextStyle(color: Colors.black45, fontSize:24.0),),
//                             color: Colors.white,
//                             onPressed: () {
//                               setState(() {
//                                 _ispressed = true;
//                                 filler('/noise/');
//                               });
//                             },
//                           ),
//                         ),
//                         SizedBox(width: 10.0,),
//                         ButtonTheme(
//                           child: RaisedButton(
//                             child: const Text('Han',
//                             style: TextStyle(color: Colors.black45, fontSize:24.0),),
//                             color: Colors.white,
//                             onPressed: () {
//                               setState(() {
//                                 _ispressed = true;
//                                 filler('/han/');
//                                 });
//                               },
//                             ),
//                           ),
//                         SizedBox(width: 10.0,),
//                         ButtonTheme(
//                           child: RaisedButton(
//                             child: const Text('Hun',
//                             style: TextStyle(color: Colors.black45, fontSize:24.0),),
//                             color: Colors.white,
//                             onPressed: () {
//                               setState(() {
//                                 _ispressed = true;
//                                 filler('/hun/');
//                               });
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Visibility(
//                     maintainSize: true,
//                     maintainAnimation: true,
//                     maintainState: true,
//                     visible: viewVisible,
//                     child: Row(
//                       children: <Widget>[
//                         ButtonTheme(
//                             child: RaisedButton(
//                               child: const Text('Noise',
//                               style: TextStyle(color: Colors.black45, fontSize:24.0),),
//                               color: Colors.white,
//                               onPressed: () {
//                                 setState(() {
//                                   _ispressed = true;
//                                   filler('/noise/');
//                                 });
//                               },
//                             ),),
//                         SizedBox(width: 10.0,),
//                         ButtonTheme(
//                             child: RaisedButton(
//                               child: const Text('Han',
//                               style: TextStyle(color: Colors.black45, fontSize:24.0),),
//                               color: Colors.white,
//                               onPressed: () {
//                                 setState(() {
//                                   _ispressed = true;
//                                   filler('/han/');
//                                   });
//                                 },
//                               ),
//                             ),
//                         SizedBox(width: 10.0,),
//                         ButtonTheme(
//                             child: RaisedButton(
//                               child: const Text('Hun',
//                               style: TextStyle(color: Colors.black45, fontSize:24.0),),
//                               color: Colors.white,
//                               onPressed: () {
//                                 setState(() {
//                                   _ispressed = true;
//                                   filler('/hun/');
//                                 });
//                               },
//                             ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
