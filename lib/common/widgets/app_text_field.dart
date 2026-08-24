
import 'package:flutter/material.dart';
import 'package:gym_app/common/app_theme.dart';

class AppTextField extends StatelessWidget {
   AppTextField({
     super.key,
     this.label,
     this.hint,
     this.maxLines = 1,
     this.controller,
     this.validator,
     this.textInputAction,
     this.keyboardType,
     this.autofocus = false,
   });
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final bool autofocus;
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
        controller: controller,
        validator: validator,
        textInputAction: textInputAction,
        keyboardType: keyboardType,
        autofocus: autofocus,
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
