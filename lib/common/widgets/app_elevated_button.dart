
import 'package:flutter/material.dart';

class AppElevatedButton extends StatelessWidget {
  final String data;
  final VoidCallback onPressed;
  const AppElevatedButton({super.key, required this.onPressed, required this.data});

  @override
  Widget build(BuildContext context) {

    return ElevatedButton(onPressed: onPressed, child: Text(data));
  }
}
