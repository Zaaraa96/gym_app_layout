
import 'package:flutter/material.dart';

import '../app_theme.dart';

class AppText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  const AppText({super.key, required this.data, this.style, this.textAlign});

  @override
  Widget build(BuildContext context) {

    return Text(data,style: style, textAlign: textAlign,);
  }
}

TextStyle titleTextStyle = TextStyle(color: appTheme.primaryColor, fontWeight: FontWeight.w900, fontSize: 20);
const subtitleTextStyle = TextStyle(color: Colors.black54, fontWeight: FontWeight.w200);
