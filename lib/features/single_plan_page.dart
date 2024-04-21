
import 'package:flutter/material.dart';
import 'package:gym_app/common/widgets/app_scaffold.dart';
import 'package:gym_app/common/widgets/app_text.dart';
import 'package:gym_app/features/single_day_plan_page.dart';

import '../common/app_theme.dart';


class SinglePlanModel{
  final String title;
  final List<SingleDayPlanModel> dayPlans;

  SinglePlanModel({required this.title, required this.dayPlans});
}

class SinglePlanPage extends StatelessWidget {
  final SinglePlanModel plan;
  const SinglePlanPage({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return  AppScaffold(
      body: CustomScrollView(
        slivers: [
           SliverAppBar(
            title: AppText(plan.title, style: titleTextStyle.copyWith(color: appTheme.colorScheme.tertiary, fontSize: 22),),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final dayPlan = plan.dayPlans[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Transform.flip(
                              flipX: index == 1,
                              child: Opacity(
                                opacity: 0.8,
                                child: Image.asset("assets/image/${index%3}.png",
                                  fit: BoxFit.cover,width: double.infinity,),
                              )),
                        ),
                        Padding(
                          padding:  const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                               AppText(dayPlan.title, style: titleTextStyle,),
                              Padding(
                                padding:  EdgeInsets.only(right: MediaQuery.of(context).size.width/3),
                                child: AppText(dayPlan.summary, style: dataTextStyle,),
                              ),
                              const Spacer(),
                              Align(
                                  alignment: Alignment.bottomLeft,
                                  child: IconButton(onPressed: (){}, icon: Icon(Icons.arrow_forward, color: appTheme.colorScheme.tertiary,))),
                              const SizedBox(height: 8,),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
              childCount: plan.dayPlans.length,
            ),
          ),
        ],
      ),
    );
  }
}
