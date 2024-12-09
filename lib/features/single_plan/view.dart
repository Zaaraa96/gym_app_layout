import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'logic.dart';

class SinglePlanPage extends StatelessWidget {
  SinglePlanPage({super.key});

  final logic = Get.put(SinglePlanLogic());
  final state = Get.find<SinglePlanLogic>().state;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
