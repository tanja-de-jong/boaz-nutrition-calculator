import 'package:boaz_nutrition_calculator/dashboard.dart';
import 'package:boaz_nutrition_calculator/food/day_overview.dart';
import 'package:boaz_nutrition_calculator/authentication/sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'authentication/authentication.dart';
import 'database/firebase_options.dart'; // generated via `flutterfire` CLI
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  initializeDateFormatting();
  runApp(GetMaterialApp(
      home: const MyApp(),
      title: "Boaz' Voercalculator",
      theme: ThemeData(
          inputDecorationTheme: const InputDecorationTheme(isDense: true))));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voercalculator',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Boaz\' Voercalculator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.active:
              final firebaseUser = snapshot.data;
              if (firebaseUser == null) {
                return const SizedBox(
                    height: 30, width: 100, child: SignInScreen());
              }
              return const Dashboard();
            default:
              return Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Center(
                    child: ElevatedButton(
                        onPressed: () =>
                            Authentication.signInWithGoogle(context: context),
                        child: const Text("Inloggen met Google")),
                  ));
          }
        });
  }
}
