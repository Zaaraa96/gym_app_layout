
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../common/widgets/app_elevated_button.dart';
import '../common/widgets/app_scaffold.dart';
import '../common/widgets/app_text.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return  AppScaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/json/gym.json'),
             AppText(data: 'Welcome To the Amazing Gym app', style: titleTextStyle, textAlign: TextAlign.center,),
            const SizedBox(height: 10,),
            const AppText(data: 'this app is going to make your gym experience more fun', style: subtitleTextStyle,
            textAlign: TextAlign.center,),
            const SizedBox(height: 10,),
            AppElevatedButton(onPressed: () {  }, data: 'Let\'s get started!',)
          ],
        ),
      ),
    );
  }
}
