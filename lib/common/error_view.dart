import 'package:flutter/material.dart';

import '../generated/l10n.dart';

class ErrorView extends StatelessWidget {
  final String? title;
  final String? description;
  final VoidCallback? onRetry;

  const ErrorView({
    this.title,
    this.description,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 64, bottom: 8.0),
            child: SizedBox(width: 100, height: 100, child: new Image.asset("assets/images/score_star_sad.webp")),
          ),
          Text(description!, style: new TextStyle(fontSize: 20.0, color: Colors.white70)),
          SizedBox(
            height: 16,
          ),
          new ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shadowColor: Colors.red,
              elevation: 10,
            ),
            // style: ButtonStyle(shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0))),
            child: new Text(
              S.of(context).RETRY,
              style: new TextStyle(fontSize: 18.0),
            ),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
