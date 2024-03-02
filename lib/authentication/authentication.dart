import 'package:boaz_nutrition_calculator/authentication/sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Authentication {
  static String? error;
  static List<String> allowedEmails = [
    "tanja@tanjadejong.com",
    "mattanjav@gmail.com",
    "samen@tanjadejong.com"
  ];

  static Future<String?> signInWithGoogle(
      {required BuildContext context}) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user;

    if (kIsWeb) {
      GoogleAuthProvider authProvider = GoogleAuthProvider();
      authProvider.setCustomParameters({'prompt': 'select_account'});

      try {
        final UserCredential userCredential =
            await auth.signInWithPopup(authProvider);
        user = userCredential.user;
        if (!allowedEmails.contains(user?.email!.toLowerCase())) {
          error = "Gebruiker heeft geen toegang tot deze app.";
          auth.signOut();
        } else {
          error = null;
        }
      } catch (e) {
        print(e);
      }
    } else {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();

      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        try {
          final UserCredential userCredential =
              await auth.signInWithCredential(credential);

          user = userCredential.user;
          if (!allowedEmails.contains(user?.email!.toLowerCase())) {
            error = "Gebruiker heeft geen toegang tot deze app.";
            auth.signOut();
          } else {
            error = null;
          }
        } on FirebaseAuthException catch (e) {
          if (e.code == 'account-exists-with-different-credential') {
            // ...
          } else if (e.code == 'invalid-credential') {
            // ...
          }
        } catch (e) {
          // ...
        }
      }
    }

    return error;
  }

  static Future<void> signOut({required BuildContext context}) async {
    final GoogleSignIn googleSignIn = GoogleSignIn();

    try {
      if (!kIsWeb) {
        await googleSignIn.signOut();
      }
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        Authentication.customSnackBar(
          content: 'Error signing out. Try again.',
        ),
      );
    }
  }

  static SnackBar customSnackBar({required String content}) {
    return SnackBar(
      backgroundColor: Colors.black,
      content: SelectableText(
        content,
        style: const TextStyle(color: Colors.redAccent, letterSpacing: 0.5),
      ),
    );
  }

  static Future<UserOrErrorMessage> signInWithUsernameAndPassword(
      {required BuildContext context,
      required String username,
      required String password}) async {
    UserOrErrorMessage result = UserOrErrorMessage();

    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: username.toLowerCase(),
        password: password,
      );

      result = UserOrErrorMessage(user: userCredential.user);
      // await TODO: Store.initializeStore(username);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        result =
            UserOrErrorMessage(errorMessage: 'Gebruikersnaam niet gevonden.');
      } else if (e.code == 'wrong-password') {
        result = UserOrErrorMessage(errorMessage: 'Wachtwoord is incorrect.');
      } else {
        result = UserOrErrorMessage(
            errorMessage:
                'Er is een probleem opgetreden bij het inloggen. Controleer je gebruikersnaam en wachtwoord.');
      }
    }

    return result;
  }

  static Future<UserOrErrorMessage> registerUserWithEmailAndPassword(
      {required BuildContext context,
      required String username,
      required String password}) async {
    // bool userAllowed = await FirestoreHandler.userAllowed(username);
    UserOrErrorMessage result = UserOrErrorMessage();

    // if (userAllowed) {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: username.toLowerCase(), password: password);
      result = UserOrErrorMessage(user: userCredential.user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        result = UserOrErrorMessage(errorMessage: 'Account bestaat al.');
      } else if (e.code == 'invalid-email') {
        result = UserOrErrorMessage(
            errorMessage: 'Het opgegeven e-mailadres is niet geldig.');
      } else if (e.code == 'weak-password') {
        result = UserOrErrorMessage(
            errorMessage: 'Het opgegeven wachtwoord is te zwak.');
      } else {
        result = UserOrErrorMessage(errorMessage: e.code);
      }
    } catch (e) {
      print(e);
    }
    // } else {
    //   result = UserOrErrorMessage(errorMessage: 'Voor dit e-mailadres kan geen account worden gemaakt.');
    // }

    return result;
  }

  static Future<String> resetPassword(String email) async {
    print("Password reset email sent");
    var error = '';
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: email.toLowerCase());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        error = "E-mailadres is ongeldig.";
      } else if (e.code == 'user-not-found') {
        error = 'Dit e-mailadres is niet bekend.';
      } else {
        error = 'Er is een onbekende fout opgetreden';
      }
    } catch (e) {
      print(e);
    }
    return error;
  }

  static Future<void> logOut({required BuildContext context}) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SignInScreen()),
    );
  }

  static Future<void> deleteUser() async {
    FirebaseAuth.instance.currentUser?.delete();
  }

  static deleteAccountDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
              title: const SelectableText('Account verwijderen'),
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                      padding: const EdgeInsets.only(left: 25, right: 25),
                      child: const SelectableText(
                          'Weet je zeker dat je je account wilt verwijderen?')),
                  const SizedBox(height: 20),
                  Center(
                      child: Wrap(spacing: 10, children: [
                    OutlinedButton(
                        onPressed: () {
                          Authentication.deleteUser();
                          Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute<void>(
                                  builder: (BuildContext context) =>
                                      const SignInScreen()),
                              (Route<dynamic> route) => false);
                        },
                        child: const Text('Verwijder')),
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Annuleer')),
                  ]))
                ])
              ]);
        });
  }
}

class UserOrErrorMessage {
  User? user;
  String? errorMessage;

  UserOrErrorMessage({this.user, this.errorMessage});
}
