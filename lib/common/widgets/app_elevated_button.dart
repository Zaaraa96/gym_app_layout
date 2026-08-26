
import 'package:flutter/material.dart';

class AppElevatedButton extends StatelessWidget {
  final String data;
  final VoidCallback? onPressed;
  final bool outlined;

  const AppElevatedButton({
    super.key,
    required this.onPressed,
    required this.data,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton(onPressed: onPressed, child: Text(data));
    }
    return ElevatedButton(onPressed: onPressed, child: Text(data));
  }
}
