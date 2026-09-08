/// On-disk layout for a `.gymplan` zip (also accepted as `.zip`).
abstract final class PlanPackageFormat {
  static const formatVersion = 1;
  static const extension = 'gymplan';
  static const planJsonName = 'plan.json';
  static const manifestName = 'manifest.json';
  static const mediaFolder = 'media';
  static const createdByApp = 'gym_app';

  /// Skip user files larger than this when packing (bytes).
  static const maxMediaBytes = 8 * 1024 * 1024;
}

bool looksLikeZip(List<int> bytes) {
  return bytes.length >= 4 && bytes[0] == 0x50 && bytes[1] == 0x4B;
}
