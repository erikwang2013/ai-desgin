import '../l10n/app_localizations.dart';
import '../models/session.dart';

/// 设计领域标签走 l10n：模型层 [DesignCategory.label] 为固定中文，
/// UI 层用当前语言版本，避免英文界面混排中文。
extension DesignCategoryLocalizedLabel on DesignCategory {
  String localizedLabel(AppLocalizations? l10n) => switch (this) {
    DesignCategory.web => l10n?.categoryWeb ?? label,
    DesignCategory.ad => l10n?.categoryAd ?? label,
    DesignCategory.industrial => l10n?.categoryIndustrial ?? label,
    DesignCategory.threeD => l10n?.categoryThreeD ?? label,
    DesignCategory.arch => l10n?.categoryArch ?? label,
    DesignCategory.interior => l10n?.categoryInterior ?? label,
  };
}
