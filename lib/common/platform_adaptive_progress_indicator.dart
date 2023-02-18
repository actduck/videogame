import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:videogame/constants.dart';

class PlatformAdaptiveProgressIndicator extends StatelessWidget {
  const PlatformAdaptiveProgressIndicator() : super();

  @override
  Widget build(BuildContext context) {
    // return isIOS
    //     ? const CupertinoActivityIndicator()
    //     : AnimatedTextKit(
    //         animatedTexts: [
    //           WavyAnimatedText(
    //             'Loading...',
    //             textStyle: const TextStyle(
    //               fontSize: 14.0,
    //             ),
    //           ),
    //         ],
    //       );
    return const CupertinoActivityIndicator();
  }
}
