import 'package:flutter/widgets.dart';

/// Uniform padding for standalone screens (no bottom navigation bar).
const EdgeInsets pagePadding = EdgeInsets.fromLTRB(20, 8, 20, 24);

/// Padding for screens inside the bottom-navigation shell (home/history/
/// education/profile) so content clears the navigation bar.
const EdgeInsets pagePaddingWithBottomNav = EdgeInsets.fromLTRB(20, 8, 20, 96);

/// Padding for the home screen: a little extra top gap below the SafeArea.
const EdgeInsets homePagePadding = EdgeInsets.fromLTRB(20, 16, 20, 96);

/// Padding for the record screen.
const EdgeInsets recordPagePadding = EdgeInsets.fromLTRB(20, 12, 20, 24);
