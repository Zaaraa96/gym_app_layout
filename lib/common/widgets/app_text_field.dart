import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  AppTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.maxLines = 1,
    this.maxLength,
    this.controller,
    this.validator,
    this.textInputAction,
    this.keyboardType,
    this.autofocus = false,
    this.onChanged,
    this.enabled = true,
    this.focusNode,
  });

  final String? label;
  final String? hint;
  final String? helperText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final FocusNode? focusNode;
  final InputBorder border = OutlineInputBorder(
    borderSide: const BorderSide(width: 1.0),
    borderRadius: BorderRadius.circular(16),
  );
  final int maxLines;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        validator: validator,
        textInputAction: textInputAction,
        keyboardType: keyboardType,
        autofocus: autofocus,
        enabled: enabled,
        onChanged: onChanged,
        maxLength: maxLength,
        decoration: InputDecoration(
          focusedBorder: border.copyWith(
            borderSide: border.borderSide.copyWith(
              width: 1.3,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          enabledBorder: border,
          label: Text(label ?? ''),
          hintText: hint,
          helperText: helperText,
        ),
        maxLines: maxLines,
      ),
    );
  }
}
