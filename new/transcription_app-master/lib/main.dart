
//import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './routes/auth.dart';
import 'widgets/landing_page.dart';
import 'package:package_info/package_info.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import './size_config.dart';
//import './package_info.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

void main() => runApp(MyApp());

// Starting with main.dart which is just setting the title and home as the AuthScreen at routes/auth.dart.
class MyApp extends StatelessWidget {
  //static FirebaseAnalytics analytics = FirebaseAnalytics();

  //RemoteConfig remoteConfig;

  @override
  Widget build(BuildContext context) {
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.portraitUp,
    //   DeviceOrientation.portraitDown,
    // ]);
    setUpRemoteConfig();
    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      home: new MyWidget(),
    );
  }

  void setUpRemoteConfig() async {
    final db = Firestore.instance;
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    String appName = packageInfo.appName;
    String packageName = packageInfo.packageName;
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;
    final RemoteConfig remoteConfig = await RemoteConfig.instance;
    try {
      await remoteConfig.fetch(expiration: const Duration(seconds: 0));
      await remoteConfig.activateFetched();
      print('welcome message: ' + remoteConfig.getString('android_app_version'));
      if (remoteConfig.getString('android_app_version') == version) {
        print("No update");
      }
      else {
        print("There is an update");
      }
    }
    on FetchThrottledException catch (exception) {
      // Fetch throttled.
      print(exception);
    } catch (exception) {
      print('Unable to fetch remote config. Cached or default values will be used');
    }
  }
}



class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context)  {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light(),
        initialRoute: '/',
        routes: <String, WidgetBuilder>{
          '/': (context) => AuthScreen(),
          '/homepage': (context) => LandingPageApp(),
        });
  }
}
//}
//
////app version check
//versionCheck(context) async {
//  PackageInfo info = await PackageInfo.fromPlatform();
//  RemoteConfig remoteConfig = await RemoteConfig.instance;
//  await remoteConfig.fetch(expiration: Duration(seconds: 0));
//  await remoteConfig.activateFetched();
//  final currentBuildNumber = int.parse(info.buildNumber);
//  final requiredBuildNumber = remoteConfig.getInt('android_app_version');
//  if (requiredBuildNumber > currentBuildNumber) {
//    versionDialog(context);
//  }
//}
//
//void versionDialog(context) {}
