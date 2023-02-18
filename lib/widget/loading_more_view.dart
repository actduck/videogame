import 'package:flutter/cupertino.dart';
import 'package:videogame/app_theme.dart';

import '../common/platform_adaptive_progress_indicator.dart';

class LoadingMoreView extends StatelessWidget {
  bool loadingMore = false;

  LoadingMoreView(this.loadingMore);

  @override
  Widget build(BuildContext context) {
    return loadingMore
        ? Container(
            height: 48,
            child: Center(
              child: PlatformAdaptiveProgressIndicator(),
            ),
          )
        : Container(
            height: 48,
          );
  }
}
