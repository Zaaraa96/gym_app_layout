
import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appbar;
  final Widget? body;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;

  const AppScaffold({
    super.key,
    this.appbar,
    this.body,
    this.backgroundColor,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appbar,
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: body,
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
