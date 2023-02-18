import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../generated/l10n.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: new Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 32),
          child: SizedBox(
              width: 140,
              height: 140,
              // child: new Image.asset("assets/images/ic_empty.png")),
              child: new Image.asset("assets/images/ic_empty_list_not_found.webp")),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            S.of(context).Empty,
            style: Theme.of(context).textTheme.headline6,
          ),
        ),
      ],
    ));
  }
}
