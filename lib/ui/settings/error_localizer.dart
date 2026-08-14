import '../../l10n/app_localizations.dart';

/// 把各设置页返回的英文校验错误文案转成本地化文案；
/// 未收录的错误原样返回。
String localizeError(AppLocalizations? l10n, String error) {
  switch (error) {
    case 'Invalid endpoint URL (e.g. https://api.example.com/v1)':
      return l10n?.invalidEndpointUrl ?? error;
    case 'Invalid model name (letters, digits, dot, dash, underscore only)':
      return l10n?.invalidModelName ?? error;
    case 'Invalid proxy host (no spaces allowed)':
      return l10n?.invalidProxyHostSpaces ?? error;
    case 'Invalid proxy host (host name only, no path)':
      return l10n?.invalidProxyHostPath ?? error;
    case 'Invalid proxy port (1-65535)':
      return l10n?.invalidProxyPort ?? error;
    case 'Proxy host is required when a port is set':
      return l10n?.proxyHostRequired ?? error;
  }
  return error;
}
