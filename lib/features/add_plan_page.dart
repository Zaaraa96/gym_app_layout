import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gym_app/common/app_routes.dart';
import 'package:gym_app/common/app_theme.dart';
import 'package:gym_app/data/models/models.dart';
import 'package:gym_app/data/plan_repository.dart';

import '../common/widgets/app_scaffold.dart';
import '../common/widgets/app_text.dart';
import '../common/widgets/app_text_field.dart';

class AddNewPlanPage extends StatefulWidget {
  const AddNewPlanPage({super.key});

  @override
  State<AddNewPlanPage> createState() => _AddNewPlanPageState();
}

class _AddNewPlanPageState extends State<AddNewPlanPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final summary = _summaryController.text.trim();
      final id = await Get.find<PlanRepository>().save(
        WorkoutPlan.create(
          title: _titleController.text.trim(),
          source: PlanSource.created,
          createdAt: now,
          updatedAt: now,
          days: [
            PlanDay.create(
              dayId: now.microsecondsSinceEpoch.toString(),
              title: 'Day 1',
              summary: summary,
            ),
          ],
        ),
      );
      if (!mounted) return;
      await Get.offAllNamed(AppRoutes.plan, arguments: id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save plan: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
            child: IgnorePointer(
          child: Image.asset(
            "assets/image/new.png",
            fit: BoxFit.cover,
          ),
        )),
        AppScaffold(
          backgroundColor: appTheme.colorScheme.background.withOpacity(0.7),
          appbar: AppBar(
            backgroundColor: appTheme.colorScheme.background.withOpacity(0.9),
            title: AppText(
              "New Plan",
              style: titleTextStyle,
            ),
          ),
          body: Center(
            child: SingleChildScrollView(
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppTextField(
                          label: 'title',
                          controller: _titleController,
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Add a title before saving'
                                  : null,
                        ),
                        AppTextField(
                          label: 'summary',
                          hint: "ex: which of your muscles are focused on...",
                          maxLines: 3,
                          controller: _summaryController,
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        ElevatedButton(
                            onPressed: _saving ? null : _save,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppText(
                                    'save',
                                    style: titleTextStyle,
                                  ),
                                  const SizedBox(
                                    width: 6,
                                  ),
                                  const Icon(
                                    Icons.add,
                                    size: 32,
                                  ),
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
        ),
      ],
    );
  }
}
