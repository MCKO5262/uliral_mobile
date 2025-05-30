import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'provider/globalProvider.dart';
import 'firebase_options.dart';
import 'screens/login_page.dart';
import 'screens/profile_page.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  //  Background notification  handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  //  Foreground  notification
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // App state provider-оор о
  runApp(
    ChangeNotifierProvider(
      create: (_) => Global_provider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeFirebaseMessaging(); //  Push
  }

  Future<void> _initializeFirebaseMessaging() async {
    final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

    //  Хэрэглэгчээс мэдэгдлийн зөвшөөрөл хүсэх
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission for notifications');

      //  FCM token 
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification!.title}, ${message.notification!.body}');
          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(message.notification?.body ?? 'Шинэ мэдэгдэл ирлээ!'),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      });

      // background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('A new onMessageOpenedApp event was published!');
        print('Message data: ${message.data}');
      });

      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        print('App launched from terminated state via a notification!');
        print('Initial Message data: ${initialMessage.data}');
      }
    } else {
      print('User declined or has not yet granted permission for notifications');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey, 
      title: 'Shop App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        primarySwatch: Colors.blue,
      ),

      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const ProfilePage(); // ✅ Нэвтэрсэн бол профайл
          }
          return const LoginPage(); // ✅ Үгүй бол login
        },
      ),
    );
  }
}
