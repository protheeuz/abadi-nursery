import 'package:flutter/material.dart';

class CustomRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const CustomRefreshIndicator({
    Key? key,
    required this.child,
    required this.onRefresh,
  }) : super(key: key);

  @override
  _CustomRefreshIndicatorState createState() => _CustomRefreshIndicatorState();
}

class _CustomRefreshIndicatorState extends State<CustomRefreshIndicator> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: widget.onRefresh,
      displacement: 40.0,
      color: Colors.transparent,
      backgroundColor: Colors.transparent,
      notificationPredicate: (ScrollNotification notification) {
        return notification.depth == 0;
      },
      child: Stack(
        children: <Widget>[
          widget.child,
          // Align(
          //   alignment: Alignment.topCenter,
          //   child: Padding(
          //     padding: const EdgeInsets.only(top: 16.0),
          //     child: Image.asset(
          //       'assets/images/flutter_logo.png',
          //       width: 60,
          //       height: 60,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
