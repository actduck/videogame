import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:videogame/generated/l10n.dart';
import 'package:videogame/pages/about_page.dart';

import '../constants.dart';

class SignInPage extends StatelessWidget {
  /// Normally the signin buttons should be contained in the SignInPage

  Function? ggLogin;
  Function? fbLogin;
  Function? appleLogin;

  SignInPage(this.ggLogin, this.fbLogin, this.appleLogin);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Container(
            height: 50,
            child: Stack(
              children: [
                Center(
                  child: Text(
                    S.of(context).sign_in_lets_start,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: Icon(Icons.close_rounded))),
                )
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SignInButton(
                  Buttons.GoogleDark,
                  onPressed: () {
                    ggLogin?.call();
                  },
                ),
                SizedBox(
                  height: 16,
                ),
                // SignInButton(
                //   Buttons.FacebookNew,
                //   onPressed: () {
                //     fbLogin?.call();
                //   },
                // ),
                // SizedBox(
                //   height: 16,
                // ),
                // SignInButton(
                //   Buttons.Apple,
                //   onPressed: () {
                //     appleLogin?.call();
                //   },
                // ),
                // SizedBox(
                //   height: 16,
                // ),
                // TextStyle(color: Color(0xff636363), fontSize: 10)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(children: [
                      TextSpan(
                          text: S.of(context).sign_in_hint1, style: TextStyle(color: Color(0xff636363), fontSize: 14)),
                      TextSpan(
                        style: TextStyle(
                          color: Colors.blueAccent,
                        ),
                        text: S.of(context).sign_in_hint2,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            launchURL(terms_of_service);
                          },
                      ),
                      TextSpan(
                        text: S.of(context).sign_in_hint3,
                        style: TextStyle(color: Color(0xff636363), fontSize: 14),
                      ),
                      TextSpan(
                        style: TextStyle(
                          color: Colors.blueAccent,
                        ),
                        text: S.of(context).sign_in_hint4,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            launchURL(policy);
                          },
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
