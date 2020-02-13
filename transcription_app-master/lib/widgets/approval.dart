import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transcribe_calls/widgets/landing_page.dart';
import './reactive_refresh_indicator.dart';
import 'package:http/http.dart';
import './history.dart';
import '../widgets/logger.dart';
import 'package:flutter/animation.dart';

typedef void OnError(Exception exception);

enum PlayerState { stopped, playing, paused }

class ApprovalPageApp extends StatefulWidget {
  @override
  _ApprovalPageAppState createState() => new _ApprovalPageAppState();
}

class _ApprovalPageAppState extends State<ApprovalPageApp> {
  //variables
  var deliverable;
  var log_data;
  var user_det;
  var submission_ts;
  var jobid,
      counter_approve,
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

  bool check;

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
              onPressed: () async {
                oldtxt = "skip";
                setState(() {
                  _btndisabled = false;
                });
                await next();
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
      ],
    );
  }

  // _updateCount() is used to update the count of the number of jobs done by the user for each instance.
  Future<void> _updateCount() async {
    var query = _firestore
        .collection('jobs')
        .where('user', isEqualTo: '/users/' + user.uid)
        .where('status', isEqualTo: 'reviewed');
    var qs = await query.getDocuments();
    print(qs.documents.length);
    setState(() {
      counter_approve = qs.documents.length;
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
        'https://us-central1-audio-transcription-b2285.cloudfunctions.net/assignApprovalUid';

    // headers is the type in which the content is sent to the cloud fucntion.
    final headers = {'Content-Type': 'application/json'};

    // storing the user id of the user in the body of the json data.
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
      deliverable = job['deliverable'];
      log_data = job['log_data'];
      user_det = job['user'];
      submission_ts = job['submission_ts'];
      print(deliverable);
      Logger.log("app_debug", message: deliverable);
      query = _firestore
          .collection('fragments')
          .document(job['fragment'].split('/')[2]);
      doc = await query.get(); //executing the query
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

  bool _isChecked = false;
  bool approved;

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
              new ListTile(
                title: new Text(displayemail.toString()),
              ),

              //Displays the performance of the user.
              new ListTile(
                title: new Text('Performance'),
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

              //About is used to display the text about the app i.e., versions, updates etc.
              new ListTile(
                title: new Text('About'),
                onTap: () {},
              ),
              new Divider(),
            ],
          )),
          appBar: AppBar(
            title: Text("Approval"),
            actions: <Widget>[
              // Chips are compact elements that represent an attribute, text, entity, or action.
              //Chip here is used to display the count of jobs done.
              Chip(
                label: Text('$counter_approve Jobs done'),
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
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                              padding: new EdgeInsets.fromLTRB(
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
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        new Flexible(
                                          child: new TextField(
                                            readOnly: true,
                                            autofocus: true,
                                            textAlign: TextAlign.center,
                                            maxLines: 3,
                                            decoration:
                                                new InputDecoration.collapsed(
                                                    hintText: deliverable),
                                            style: new TextStyle(
                                                fontSize:
                                                    16.0), //Font size for the text field to write the text.
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 10.0),
                                ],
                              ),
                            ),
                            //SizedBox(height: 10.0),
                            SizedBox(
                              height: 50.0,
                              child: new Card(
//                                        color: Colors.white,
//                                        shape: RoundedRectangleBorder(
//                                          side: BorderSide(
//                                              color: Colors.black12, width: 1),
//                                          borderRadius:
//                                              BorderRadius.circular(10),
//                                        ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
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
                            new Container(
                              child: Column(
                                children: <Widget>[
                                  Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: <Widget>[
                                        SizedBox.fromSize(
                                          size: Size(66,
                                              66), // button width and height
                                          child: ClipOval(
                                            child: Material(
                                              color: Colors
                                                  .black12, // button color
                                              child: InkWell(
                                                splashColor: Colors
                                                    .blueAccent, // splash color
                                                onTap: () {
                                                  setState(() {
                                                    approved = true;
                                                    print(
                                                        '$approved approval button');
                                                    approve();
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                LandingPageApp())); // Calling the next method.
                                                  });
                                                }, // button pressed
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: <Widget>[
                                                    Icon(
                                                      Icons.done,
                                                      size: 50.0,
                                                    ), // icon// text
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox.fromSize(
                                          size: Size(66,
                                              66), // button width and height
                                          child: ClipOval(
                                            child: Material(
                                              color: Colors
                                                  .black12, // button color
                                              child: InkWell(
                                                splashColor: Colors
                                                    .redAccent, // splash color
                                                onTap: () {
                                                  setState(() {
                                                    approved = false;
                                                    print(
                                                        '$approved reject button');
                                                    approve();
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                LandingPageApp())); // Calling the next method.
                                                  });
                                                }, // button pressed
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: <Widget>[
                                                    Icon(
                                                      Icons.clear,
                                                      size: 50.0,
                                                    ), // icon// text
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ]),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      SizedBox(width: 100),
                                      Text('Approve'),
                                      SizedBox(width: 115.0),
                                      Text('Reject')
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ])),
                ),
              ))),
    );
  }

  // This function is used to update the values in "jobs" collection for respective "jobid".
  approve() async {
    var result;
    var res;
    bool submitted;
    //checking fragment is approved or not
    if (approved == true) {
      result = 'Approved';
    } else {
      result = 'Rejected';
    }

    //check whether there is any wrong pronounciation or not in the fragment
    if (check == true) {
      res = 'present';
    } else {
      res = 'absent';
    }

    await Firestore.instance.collection('jobs').document(jobid).updateData({
      'submission_ts': submission_ts,
      'log_data': log_data,
      'deliverable': deliverable,
      'status': 'reviewed',
      'review': result,
      'user': user_det,
      'wrong pronunciation': res,
      'review_ts': DateTime.now()
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
    bool isSubmitted = await approve(); // submission is done.
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
