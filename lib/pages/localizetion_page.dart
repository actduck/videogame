// import 'package:flutter/material.dart';
// import 'package:videogame/util/duck_kv.dart';
//
// import '../generated/l10n.dart';
//
// class LocalizationPage extends StatefulWidget {
//   final String currLang;
//
//   LocalizationPage(this.currLang);
//
//   @override
//   _LocalizationPageState createState() => _LocalizationPageState();
// }
//
// class _LocalizationPageState extends State<LocalizationPage> {
//   late String groupValue = widget.currLang;
//
//   @override
//   Widget build(BuildContext context) {
//     void _changed(value) {
//       if (value != null) {
//         DuckKV.saveKey("app_language", value);
//         setState(() {
//           groupValue = value;
//           if (value == "en") S.load(Locale('en'));
//           if (value == "es") S.load(Locale('es'));
//           if (value == "pt") S.load(Locale('pt'));
//           if (value == "fr") S.load(Locale('fr'));
//           if (value == "de") S.load(Locale('de'));
//           if (value == "it") S.load(Locale('it'));
//           if (value == "ja") S.load(Locale('ja'));
//           if (value == "zh") S.load(Locale('zh'));
//         });
//       }
//     }
//
//     return new Scaffold(
//         appBar: new AppBar(
//           title: Text(
//             S.of(context).Language,
//           ),
//         ),
//         body: new Column(
//           children: [
//             RadioListTile<String>(
//                 title: Text(S.of(context).Language_Auto), value: 'auto', groupValue: groupValue, onChanged: _changed),
//
//             RadioListTile<String>(title: Text('English'), value: 'en', groupValue: groupValue, onChanged: _changed),
//             RadioListTile<String>(title: Text('español'), value: 'es', groupValue: groupValue, onChanged: _changed),
//             RadioListTile<String>(title: Text('Português'), value: 'pt', groupValue: groupValue, onChanged: _changed),
//             RadioListTile<String>(title: Text('Français'), value: 'fr', groupValue: groupValue, onChanged: _changed),
//             RadioListTile<String>(title: Text('Deutsch'), value: 'de', groupValue: groupValue, onChanged: _changed),
//             RadioListTile<String>(title: Text('Italiano'), value: 'it', groupValue: groupValue, onChanged: _changed),
//             RadioListTile<String>(title: Text('日本'), value: 'ja', groupValue: groupValue, onChanged: _changed),
//             RadioListTile<String>(title: Text('中文'), value: 'zh', groupValue: groupValue, onChanged: _changed),
//           ],
//         ));
//   }
// }
