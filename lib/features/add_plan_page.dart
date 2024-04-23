import 'package:flutter/material.dart';
import 'package:gym_app/common/app_theme.dart';

import '../common/widgets/app_scaffold.dart';
import '../common/widgets/app_text.dart';
import '../common/widgets/app_text_field.dart';

class AddNewPlanPage extends StatelessWidget {
  const AddNewPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: Image.asset("assets/image/new.png", fit: BoxFit.cover,)),
        AppScaffold(
          backgroundColor: appTheme.colorScheme.background.withOpacity(0.7),
          appbar: AppBar(
            backgroundColor: appTheme.colorScheme.background.withOpacity(0.9),
            title:  AppText("New Plan", style: titleTextStyle,),
          ),
          body: Center(
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       AppTextField(
                        label: 'title',
                      ),
                       AppTextField(
                        label: 'summary',
                        hint: "ex: which of your muscles are focused on...",
                         maxLines: 3,
                      ),
                      const SizedBox(height: 20,),
                      ElevatedButton(
                          onPressed: (){}, child:
                       Padding(
                         padding: const EdgeInsets.all(8.0),
                         child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppText('save', style: titleTextStyle,),
                            const SizedBox(width: 6,),
                            const Icon(Icons.add, size: 32,),
                          ],
                                               ),
                       ))
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
