/// Named routes. Kept in one place so `main` and tests agree on the strings.
abstract final class AppRoutes {
  static const welcome = '/';
  static const home = '/home';
  static const newPlan = '/new-plan';
  static const plan = '/plan';
  /// Not nested under `/plan` — GetX treats `/plan/day` as a child of `/plan`
  /// and `Get.toNamed` from the plan screen would no-op.
  static const editDay = '/edit-day';
}
