import '../l10n/app_strings.dart';

enum LayoutType { single, strip4, grid2x2 }

extension LayoutTypeExt on LayoutType {
  int get photoCount {
    switch (this) {
      case LayoutType.single:
        return 1;
      case LayoutType.strip4:
        return 4;
      case LayoutType.grid2x2:
        return 4;
    }
  }

  String get displayName => S.layoutName(name);

  String get description => S.layoutDesc(name);
}
