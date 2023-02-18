import 'package:flutter/cupertino.dart';

class CupertinoWallpaperDialog extends StatelessWidget {
  const CupertinoWallpaperDialog({Key? key, this.title, this.content}) : super(key: key);

  final Widget? title;
  final Widget? content;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: title,
      content: content,
      actions: <Widget>[
        CupertinoDialogAction(
          child: const Text('Home Screen'),
          onPressed: () {
            Navigator.pop(context, "home");
          },
        ),
        CupertinoDialogAction(
          child: const Text('Lock Screen'),
          onPressed: () {
            Navigator.pop(context, "lock");
          },
        ),
        CupertinoDialogAction(
          child: const Text('Home Screen & Lock Screen'),
          onPressed: () {
            Navigator.pop(context, "both");
          },
        ),
        CupertinoDialogAction(
          child: const Text('Cancel'),
          isDestructiveAction: true,
          onPressed: () {
            Navigator.pop(context, "cancel");
          },
        ),
      ],
    );
  }
}

class CupertinoShareDialog extends StatelessWidget {
  const CupertinoShareDialog({Key? key, this.title, this.content}) : super(key: key);

  final Widget? title;
  final Widget? content;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: title,
      content: content,
      actions: <Widget>[
        CupertinoDialogAction(
          child: const Text('Twitter'),
          onPressed: () {
            Navigator.pop(context, "twitter");
          },
        ),
        CupertinoDialogAction(
          child: const Text('Facebook'),
          onPressed: () {
            Navigator.pop(context, "facebook");
          },
        ),
        CupertinoDialogAction(
          child: const Text('WhatsApp'),
          onPressed: () {
            Navigator.pop(context, "whatsapp");
          },
        ),
        CupertinoDialogAction(
          child: const Text('System'),
          onPressed: () {
            Navigator.pop(context, "system");
          },
        ),
        CupertinoDialogAction(
          child: const Text('Cancel'),
          isDestructiveAction: true,
          onPressed: () {
            Navigator.pop(context, "cancel");
          },
        ),
      ],
    );
  }
}
