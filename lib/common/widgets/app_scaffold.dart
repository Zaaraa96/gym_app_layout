

import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appbar;
  final Widget? body;

  const AppScaffold({super.key, this.appbar, this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appbar,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: body,
      ),
    );
  }
}