import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:videogame/app_theme.dart';
import 'package:videogame/generated/l10n.dart';
import 'package:videogame/model/duck_account.dart';
import 'package:videogame/net/app_repo.dart';
import 'package:videogame/util/duck_analytics.dart';
import 'package:videogame/util/duck_user.dart';

class ProfilePage extends StatefulWidget {
  final DuckAccount userinfo;
  final bool isPremium;

  ProfilePage(this.userinfo, this.isPremium);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int counter = 0;


  @override
  void initState() {
    super.initState();
    DuckAnalytics.analytics.setCurrentScreen(
      screenName: 'ProfilePage',
    );
  }
  @override
  Widget build(BuildContext context) {
    var isPremium = widget.isPremium;
    var medal = "";
    medal = isPremium ? "Pro" : "Free";

    return Scaffold(
      body: ListView(
        children: [
          /// 会员
          Container(
            padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
            margin: const EdgeInsets.only(top: 16, left: 8, right: 8),
            decoration: new BoxDecoration(
              image: DecorationImage(
                image:
                    (isPremium != null && isPremium) ? AssetImage("assets/images/rank_header.webp") : AssetImage(""),
                fit: BoxFit.cover,
              ),
              // 边色与边宽度
              color: AppTheme.surface1,

              shape: BoxShape.rectangle,
              // 默认值也是矩形
              borderRadius: new BorderRadius.circular((8)), // 圆角度
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                          width: 80,
                          height: 80,
                          child: CircleAvatar(
                            radius: 50,
                            child: ClipOval(
                              child: new CachedNetworkImage(
                                imageUrl: widget.userinfo.photoUrl!,
                                errorWidget: (context, url, error) =>
                                    new Image.asset("assets/images/score_star_unselect.webp"),
                              ),
                            ),
                          )),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userinfo.displayName!,
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16),
                            ),
                            if (widget.userinfo != null)
                              SizedBox(
                                height: 8,
                              ),
                            if (widget.userinfo != null)
                              Row(
                                children: [
                                  Text(
                                    medal,
                                    style: Theme.of(context).textTheme.caption,
                                  ),
                                  SizedBox(width: 8),
                                  Image.asset(
                                    "assets/images/ic_medal.png",
                                    width: 20,
                                    height: 20,
                                  ),
                                  if (isPremium != null && isPremium)
                                    Image.asset(
                                      "assets/images/gold_medal.webp",
                                      width: 20,
                                      height: 20,
                                    ),
                                  if (isPremium != null && isPremium)
                                    Image.asset(
                                      "assets/images/icon_talent_authenticate.png",
                                      width: 20,
                                      height: 20,
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      Spacer(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 100,
          ),
          TextButton(
            child: Text(S.of(context).Sign_Out, style: TextStyle(color: Colors.redAccent, fontSize: 18)),
            onPressed: () async {
              onLogout();
            },
          ),
          SizedBox(
            height: 16,
          ),
          TextButton(
            child: Text(S.of(context).Delete_User_Account, style: TextStyle(color: Colors.red[700], fontSize: 18)),
            onPressed: () async {
              onDeleteUser();
            },
          ),
        ],
      ),
    );
  }

  void onLogout() {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              content: Text(S.of(context).Are_you_sure_you_want_to_sign_out),
              actions: <Widget>[
                TextButton(
                  child: Text(S.of(context).CANCEL, style: TextStyle(color: Colors.white54)),
                  onPressed: () => Navigator.of(context).pop(), //关闭对话框
                ),
                TextButton(
                  child: Text(S.of(context).SIGN_OUT, style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    await DuckUser.instance.signOut();
                    Navigator.of(context).pop();
                    Fluttertoast.showToast(msg: S.of(context).Sign_out_success);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ));
  }

  void onDeleteUser() {
    showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: Text(S.of(context).Delete_User_Account),
              content: Text(S.of(context).Are_you_sure_you_want_to_Delete_current_User_Account),
              actions: <Widget>[
                TextButton(
                  child: Text(S.of(context).CANCEL, style: TextStyle(color: Colors.white54)),
                  onPressed: () => Navigator.of(context).pop(), //关闭对话框
                ),
                TextButton(
                  child: Text(S.of(context).DELETE, style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    await DuckUser.instance.signOut();
                    AppRepo().deleteUser(widget.userinfo).listen((data) {
                      Navigator.of(context).pop();
                      Fluttertoast.showToast(msg: S.of(context).User_Account_is_Deleted);
                      Navigator.of(context).pop();
                    }, onError: (e) {
                      Navigator.of(context).pop();
                      Fluttertoast.showToast(msg: S.of(context).User_Account_deleted_failed);
                      Navigator.of(context).pop();
                    });
                  },
                ),
              ],
            ));
  }
}
