
import 'package:flutter/material.dart';
import 'package:gym_app/common/app_theme.dart';

class AppTextField extends StatelessWidget {
   AppTextField({super.key, this.label, this.hint, this.maxLines = 1});
  final String? label;
  final String? hint;
  final InputBorder border= OutlineInputBorder(
      borderSide: const BorderSide(width: 1.0),
      borderRadius: BorderRadius.circular(16)
  );
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return  Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration:  InputDecoration(
          focusedBorder: border.copyWith(borderSide: border.borderSide.copyWith(width: 1.3, color: appTheme.colorScheme.primary), ),
          enabledBorder: border,
            label: Text(label?? ''),
            hintText: hint,
        ),
        maxLines: maxLines,
      ),
    );
  }
}
