import 'package:boaz_nutrition_calculator/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'authentication.dart';
import '../food/day_overview.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  String email = "";
  String password = "";
  bool register = false;
  var error = '';

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void signInFromField(value) {
    signIn();
  }

  void registerFromField(value) {
    registerUser();
  }

  void signIn() async {
    UserOrErrorMessage userOrErrorMessage =
        await Authentication.signInWithUsernameAndPassword(
            context: context, username: email, password: password);

    if (userOrErrorMessage.user != null) {
      setState(() {
        error = '';
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const Dashboard()),
      );
    } else if (userOrErrorMessage.errorMessage != null) {
      setState(() {
        error = userOrErrorMessage.errorMessage!;
      });
      // }
    }
  }

  void registerUser() async {
    UserOrErrorMessage userOrErrorMessage =
        await Authentication.registerUserWithEmailAndPassword(
            context: context, username: email, password: password);

    if (userOrErrorMessage.user != null) {
      setState(() {
        error = '';
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const Dashboard()),
      );
    }

    if (userOrErrorMessage.errorMessage != null) {
      setState(() {
        error = userOrErrorMessage.errorMessage!;
      });
      // }
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const SelectableText('Voercalculator')),
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
              if (Authentication.error != null)
                Text(
                  Authentication.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              Container(
                  padding: const EdgeInsets.all(20),
                  child: SignInButton(Buttons.Google, text: "Log in met Google",
                      onPressed: () async {
                    await Authentication.signInWithGoogle(context: context);
                  })),
            ])));
  }
}
