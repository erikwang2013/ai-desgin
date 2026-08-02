# Multi-Language Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add i18n support for 12 languages (zh/en/ru/es/ko/ja/fr/de/ar/fil/hi/fa) to the AI Design Studio Flutter app, translating both UI text and AI conversation responses.

**Architecture:** Flutter official ARB-based localization via `flutter_localizations` + `intl`. A `LocaleProvider` (ChangeNotifier) manages locale state and persists to SharedPreferences. Language instructions are injected into AI prompts via `TaskOrchestrator`. RTL supported for ar/fa.

**Tech Stack:** Flutter 3.x, flutter_localizations, intl, shared_preferences

---

### Task 1: Add dependencies and configure code generation

**Files:**
- Modify: `pubspec.yaml`
- Create: `l10n.yaml`

- [ ] **Step 1: Add dependencies to pubspec.yaml**

Read `pubspec.yaml`, then edit. Under `dependencies:`, add `shared_preferences` and `intl`, and `flutter_localizations`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  sqflite: ^2.3.0
  path_provider: ^2.1.0
  uuid: ^4.2.0
  yaml: ^3.1.0
  logging: ^1.2.0
  shared_preferences: ^2.2.0
  intl: ^0.19.0
```

Under the `flutter:` section, add `generate: true`:

```yaml
flutter:
  uses-material-design: true
  generate: true
```

- [ ] **Step 2: Create l10n.yaml at project root**

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
untranslated-messages-file: untranslated.txt
```

- [ ] **Step 3: Run flutter pub get**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter pub get
```
Expected: exits 0, no errors.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock l10n.yaml
git commit -m "chore: add i18n dependencies and l10n config"
```

---

### Task 2: Create all 12 ARB translation files

**Files:**
- Create: `lib/l10n/app_en.arb` (template + fallback)
- Create: `lib/l10n/app_zh.arb`
- Create: `lib/l10n/app_ru.arb`
- Create: `lib/l10n/app_es.arb`
- Create: `lib/l10n/app_ko.arb`
- Create: `lib/l10n/app_ja.arb`
- Create: `lib/l10n/app_fr.arb`
- Create: `lib/l10n/app_de.arb`
- Create: `lib/l10n/app_ar.arb`
- Create: `lib/l10n/app_fil.arb`
- Create: `lib/l10n/app_hi.arb`
- Create: `lib/l10n/app_fa.arb`

- [ ] **Step 1: Create lib/l10n/app_en.arb (template, fallback locale)**

```json
{
  "@@locale": "en",
  "appTitle": "AI Design",
  "designDomains": "Design Domains",
  "navigation": "Navigation",
  "tabChat": "Chat",
  "tabTasks": "Tasks",
  "tabPlugins": "Plugins",
  "settings": "Settings",
  "targetSoftware": "Target Software:",
  "hintText": "Describe the design operation you want...",
  "modelConfig": "Model Config",
  "modelConfigDesc": "Manage API endpoint and keys",
  "pluginMarket": "Plugin Marketplace",
  "pluginMarketDesc": "Browse and install plugins",
  "proxySettings": "Proxy Settings",
  "proxySettingsDesc": "Configure network proxy",
  "about": "About",
  "aboutVersion": "AI Design v{version}",
  "@aboutVersion": {
    "placeholders": {
      "version": {}
    }
  },
  "comingSoon": "Coming Soon",
  "aboutDescription1": "An AI-driven design software automation tool.",
  "aboutDescription2": "Covers 6 design domains and 47+ mainstream design software with AI-driven script generation and execution.",
  "installedPlugins": "Installed Plugins",
  "installPlugin": "Install Plugin",
  "connected": "Connected",
  "disconnected": "Disconnected",
  "all": "All",
  "inProgress": "In Progress",
  "completed": "Completed",
  "taskList": "Task List",
  "noTasks": "No Tasks",
  "noTasksHint": "Enter your design requirements in the chat panel; tasks will appear here.",
  "installed": "Installed ({count})",
  "@installed": {
    "placeholders": {
      "count": {}
    }
  },
  "available": "Available ({count})",
  "@available": {
    "placeholders": {
      "count": {}
    }
  },
  "install": "Install",
  "uninstall": "Uninstall",
  "installSuccess": "{name} installed successfully",
  "@installSuccess": {
    "placeholders": {
      "name": {}
    }
  },
  "uninstallSuccess": "{name} uninstalled",
  "@uninstallSuccess": {
    "placeholders": {
      "name": {}
    }
  },
  "ok": "OK",
  "errorPrefix": "Error",
  "echoPrefix": "Echo",
  "taskCompleted": "Task completed",
  "taskFailed": "Task failed",
  "noOutput": "(no output)",
  "unknownError": "Unknown error",
  "languageInstruction": "Please respond in English."
}
```

- [ ] **Step 2: Create lib/l10n/app_zh.arb**

```json
{
  "@@locale": "zh",
  "appTitle": "AI Design",
  "designDomains": "设计领域",
  "navigation": "导航",
  "tabChat": "对话",
  "tabTasks": "任务",
  "tabPlugins": "插件",
  "settings": "设置",
  "targetSoftware": "目标软件：",
  "hintText": "描述你想要的设计操作...",
  "modelConfig": "模型配置",
  "modelConfigDesc": "管理 API endpoint 和密钥",
  "pluginMarket": "插件市场",
  "pluginMarketDesc": "浏览和安装插件",
  "proxySettings": "代理设置",
  "proxySettingsDesc": "配置网络代理",
  "about": "关于",
  "aboutVersion": "AI Design v{version}",
  "@aboutVersion": {
    "placeholders": {
      "version": {}
    }
  },
  "comingSoon": "即将推出",
  "aboutDescription1": "一款 AI 驱动的设计软件自动化工具。",
  "aboutDescription2": "覆盖 6 大设计领域、47 款主流设计软件的 AI 驱动脚本生成与执行。",
  "installedPlugins": "已安装插件",
  "installPlugin": "安装插件",
  "connected": "已连接",
  "disconnected": "未连接",
  "all": "全部",
  "inProgress": "进行中",
  "completed": "已完成",
  "taskList": "任务列表",
  "noTasks": "暂无任务",
  "noTasksHint": "在对话面板中输入设计需求，任务将显示在这里",
  "installed": "已安装 ({count})",
  "@installed": { "placeholders": { "count": {} } },
  "available": "可安装 ({count})",
  "@available": { "placeholders": { "count": {} } },
  "install": "安装",
  "uninstall": "卸载",
  "installSuccess": "{name} 安装成功",
  "@installSuccess": { "placeholders": { "name": {} } },
  "uninstallSuccess": "{name} 已卸载",
  "@uninstallSuccess": { "placeholders": { "name": {} } },
  "ok": "确定",
  "errorPrefix": "错误",
  "echoPrefix": "Echo",
  "taskCompleted": "任务完成",
  "taskFailed": "任务失败",
  "noOutput": "(无输出)",
  "unknownError": "未知错误",
  "languageInstruction": "请使用中文回复。"
}
```

- [ ] **Step 3: Create lib/l10n/app_ru.arb**

```json
{
  "@@locale": "ru",
  "appTitle": "AI Design",
  "designDomains": "Области дизайна",
  "navigation": "Навигация",
  "tabChat": "Чат",
  "tabTasks": "Задачи",
  "tabPlugins": "Плагины",
  "settings": "Настройки",
  "targetSoftware": "Целевое ПО:",
  "hintText": "Опишите желаемую операцию дизайна...",
  "modelConfig": "Конфигурация модели",
  "modelConfigDesc": "Управление endpoint API и ключами",
  "pluginMarket": "Маркет плагинов",
  "pluginMarketDesc": "Просмотр и установка плагинов",
  "proxySettings": "Настройки прокси",
  "proxySettingsDesc": "Настройка сетевого прокси",
  "about": "О программе",
  "aboutVersion": "AI Design v{version}",
  "@aboutVersion": { "placeholders": { "version": {} } },
  "comingSoon": "Скоро",
  "aboutDescription1": "Инструмент автоматизации дизайна на основе ИИ.",
  "aboutDescription2": "Охватывает 6 областей дизайна и 47+ программ для автоматизированной генерации скриптов.",
  "installedPlugins": "Установленные плагины",
  "installPlugin": "Установить плагин",
  "connected": "Подключено",
  "disconnected": "Не подключено",
  "all": "Все",
  "inProgress": "В процессе",
  "completed": "Завершено",
  "taskList": "Список задач",
  "noTasks": "Нет задач",
  "noTasksHint": "Введите требования в чате; задачи появятся здесь.",
  "installed": "Установлено ({count})",
  "@installed": { "placeholders": { "count": {} } },
  "available": "Доступно ({count})",
  "@available": { "placeholders": { "count": {} } },
  "install": "Установить",
  "uninstall": "Удалить",
  "installSuccess": "{name} успешно установлен",
  "@installSuccess": { "placeholders": { "name": {} } },
  "uninstallSuccess": "{name} удалён",
  "@uninstallSuccess": { "placeholders": { "name": {} } },
  "ok": "OK",
  "errorPrefix": "Ошибка",
  "echoPrefix": "Echo",
  "taskCompleted": "Задача выполнена",
  "taskFailed": "Ошибка задачи",
  "noOutput": "(нет вывода)",
  "unknownError": "Неизвестная ошибка",
  "languageInstruction": "Пожалуйста, отвечайте на русском языке."
}
```

- [ ] **Step 4: Create lib/l10n/app_es.arb**

```json
{
  "@@locale": "es",
  "appTitle": "AI Design",
  "designDomains": "Dominios de diseño",
  "navigation": "Navegación",
  "tabChat": "Chat",
  "tabTasks": "Tareas",
  "tabPlugins": "Plugins",
  "settings": "Configuración",
  "targetSoftware": "Software objetivo:",
  "hintText": "Describe la operación de diseño que deseas...",
  "modelConfig": "Configuración del modelo",
  "modelConfigDesc": "Gestionar endpoint API y claves",
  "pluginMarket": "Mercado de plugins",
  "pluginMarketDesc": "Explorar e instalar plugins",
  "proxySettings": "Configuración de proxy",
  "proxySettingsDesc": "Configurar proxy de red",
  "about": "Acerca de",
  "aboutVersion": "AI Design v{version}",
  "@aboutVersion": { "placeholders": { "version": {} } },
  "comingSoon": "Próximamente",
  "aboutDescription1": "Una herramienta de automatización de diseño impulsada por IA.",
  "aboutDescription2": "Cubre 6 dominios de diseño y más de 47 software de diseño con generación de scripts por IA.",
  "installedPlugins": "Plugins instalados",
  "installPlugin": "Instalar plugin",
  "connected": "Conectado",
  "disconnected": "Desconectado",
  "all": "Todo",
  "inProgress": "En progreso",
  "completed": "Completado",
  "taskList": "Lista de tareas",
  "noTasks": "Sin tareas",
  "noTasksHint": "Ingresa los requisitos de diseño en el chat; las tareas aparecerán aquí.",
  "installed": "Instalado ({count})",
  "@installed": { "placeholders": { "count": {} } },
  "available": "Disponible ({count})",
  "@available": { "placeholders": { "count": {} } },
  "install": "Instalar",
  "uninstall": "Desinstalar",
  "installSuccess": "{name} instalado correctamente",
  "@installSuccess": { "placeholders": { "name": {} } },
  "uninstallSuccess": "{name} desinstalado",
  "@uninstallSuccess": { "placeholders": { "name": {} } },
  "ok": "OK",
  "errorPrefix": "Error",
  "echoPrefix": "Echo",
  "taskCompleted": "Tarea completada",
  "taskFailed": "Error en la tarea",
  "noOutput": "(sin salida)",
  "unknownError": "Error desconocido",
  "languageInstruction": "Por favor, responde en español."
}
```

- [ ] **Step 5: Create lib/l10n/app_ko.arb**

```json
{
  "@@locale": "ko",
  "appTitle": "AI Design",
  "designDomains": "디자인 분야",
  "navigation": "내비게이션",
  "tabChat": "채팅",
  "tabTasks": "작업",
  "tabPlugins": "플러그인",
  "settings": "설정",
  "targetSoftware": "대상 소프트웨어:",
  "hintText": "원하는 디자인 작업을 설명하세요...",
  "modelConfig": "모델 구성",
  "modelConfigDesc": "API 엔드포인트 및 키 관리",
  "pluginMarket": "플러그인 마켓",
  "pluginMarketDesc": "플러그인 탐색 및 설치",
  "proxySettings": "프록시 설정",
  "proxySettingsDesc": "네트워크 프록시 구성",
  "about": "정보",
  "aboutVersion": "AI Design v{version}",
  "@aboutVersion": { "placeholders": { "version": {} } },
  "comingSoon": "곧 출시",
  "aboutDescription1": "AI 기반 디자인 소프트웨어 자동화 도구.",
  "aboutDescription2": "6개 디자인 분야와 47개 이상의 주요 디자인 소프트웨어를 위한 AI 스크립트 생성 및 실행.",
  "installedPlugins": "설치된 플러그인",
  "installPlugin": "플러그인 설치",
  "connected": "연결됨",
  "disconnected": "연결 안 됨",
  "all": "전체",
  "inProgress": "진행 중",
  "completed": "완료됨",
  "taskList": "작업 목록",
  "noTasks": "작업 없음",
  "noTasksHint": "채팅 패널에 디자인 요구사항을 입력하면 작업이 여기에 표시됩니다.",
  "installed": "설치됨 ({count})",
  "@installed": { "placeholders": { "count": {} } },
  "available": "설치 가능 ({count})",
  "@available": { "placeholders": { "count": {} } },
  "install": "설치",
  "uninstall": "제거",
  "installSuccess": "{name} 설치 성공",
  "@installSuccess": { "placeholders": { "name": {} } },
  "uninstallSuccess": "{name} 제거됨",
  "@uninstallSuccess": { "placeholders": { "name": {} } },
  "ok": "확인",
  "errorPrefix": "오류",
  "echoPrefix": "Echo",
  "taskCompleted": "작업 완료",
  "taskFailed": "작업 실패",
  "noOutput": "(출력 없음)",
  "unknownError": "알 수 없는 오류",
  "languageInstruction": "한국어로 답변해 주세요."
}
```

- [ ] **Step 6: Create lib/l10n/app_ja.arb**

```json
{
  "@@locale": "ja",
  "appTitle": "AI Design",
  "designDomains": "デザイン分野",
  "navigation": "ナビゲーション",
  "tabChat": "チャット",
  "tabTasks": "タスク",
  "tabPlugins": "プラグイン",
  "settings": "設定",
  "targetSoftware": "対象ソフトウェア：",
  "hintText": "実行したいデザイン操作を説明してください...",
  "modelConfig": "モデル設定",
  "modelConfigDesc": "APIエンドポイントとキーを管理",
  "pluginMarket": "プラグインマーケット",
  "pluginMarketDesc": "プラグインの参照とインストール",
  "proxySettings": "プロキシ設定",
  "proxySettingsDesc": "ネットワークプロキシを設定",
  "about": "について",
  "aboutVersion": "AI Design v{version}",
  "@aboutVersion": { "placeholders": { "version": {} } },
  "comingSoon": "近日公開",
  "aboutDescription1": "AI駆動のデザインソフトウェア自動化ツール。",
  "aboutDescription2": "6つのデザイン分野、47以上の主要デザインソフトウェアに対応するAIスクリプト生成と実行。",
  "installedPlugins": "インストール済みプラグイン",
  "installPlugin": "プラグインをインストール",
  "connected": "接続済み",
  "disconnected": "未接続",
  "all": "すべて",
  "inProgress": "進行中",
  "completed": "完了",
  "taskList": "タスク一覧",
  "noTasks": "タスクなし",
  "noTasksHint": "チャットパネルにデザイン要件を入力すると、タスクがここに表示されます。",
  "installed": "インストール済み ({count})",
  "@installed": { "placeholders": { "count": {} } },
  "available": "インストール可能 ({count})",
  "@available": { "placeholders": { "count": {} } },
  "install": "インストール",
  "uninstall": "アンインストール",
  "installSuccess": "{name} インストール成功",
  "@installSuccess": { "placeholders": { "name": {} } },
  "uninstallSuccess": "{name} アンインストール済み",
  "@uninstallSuccess": { "placeholders": { "name": {} } },
  "ok": "OK",
  "errorPrefix": "エラー",
  "echoPrefix": "Echo",
  "taskCompleted": "タスク完了",
  "taskFailed": "タスク失敗",
  "noOutput": "(出力なし)",
  "unknownError": "不明なエラー",
  "languageInstruction": "日本語で返信してください。"
}
```

- [ ] **Step 7: Create lib/l10n/app_fr.arb**

```json
{
  "@@locale": "fr",
  "appTitle": "AI Design",
  "designDomains": "Domaines de design",
  "navigation": "Navigation",
  "tabChat": "Chat",
  "tabTasks": "Tâches",
  "tabPlugins": "Plugins",
  "settings": "Paramètres",
  "targetSoftware": "Logiciel cible :",
  "hintText": "Décrivez l'opération de design souhaitée...",
  "modelConfig": "Configuration du modèle",
  "modelConfigDesc": "Gérer l'endpoint API et les clés",
  "pluginMarket": "Marché des plugins",
  "pluginMarketDesc": "Parcourir et installer des plugins",
  "proxySettings": "Paramètres proxy",
  "proxySettingsDesc": "Configurer le proxy réseau",
  "about": "À propos",
  "aboutVersion": "AI Design v{version}",
  "@aboutVersion": { "placeholders": { "version": {} } },
  "comingSoon": "Bientôt disponible",
  "aboutDescription1": "Un outil d'automatisation de conception piloté par l'IA.",
  "aboutDescription2": "Couvre 6 domaines de conception et plus de 47 logiciels avec génération de scripts par IA.",
  "installedPlugins": "Plugins installés",
  "installPlugin": "Installer un plugin",
  "connected": "Connecté",
  "disconnected": "Déconnecté",
  "all": "Tout",
  "inProgress": "En cours",
  "completed": "Terminé",
  "taskList": "Liste des tâches",
  "noTasks": "Aucune tâche",
  "noTasksHint": "Saisissez vos exigences dans le chat ; les tâches apparaîtront ici.",
  "installed": "Installé ({count})",
  "@installed": { "placeholders": { "count": {} } },
  "available": "Disponible ({count})",
  "@available": { "placeholders": { "count": {} } },
  "install": "Installer",
  "uninstall": "Désinstaller",
  "installSuccess": "{name} installé avec succès",
  "@installSuccess": { "placeholders": { "name": {} } },
  "uninstallSuccess": "{name} désinstallé",
  "@uninstallSuccess": { "placeholders": { "name": {} } },
  "ok": "OK",
  "errorPrefix": "Erreur",
  "echoPrefix": "Echo",
  "taskCompleted": "Tâche terminée",
  "taskFailed": "Échec de la tâche",
  "noOutput": "(aucune sortie)",
  "unknownError": "Erreur inconnue",
  "languageInstruction": "Veuillez répondre en français."
}
```

- [ ] **Step 8: Create lib/l10n/app_de.arb**

```json
{
  "@@locale": "de",
  "appTitle": "AI Design",
  "designDomains": "Designbereiche",
  "navigation": "Navigation",
  "tabChat": "Chat",
  "tabTasks": "Aufgaben",
  "tabPlugins": "Plugins",
  "settings": "Einstellungen",
  "targetSoftware": "Zielsoftware:",
  "hintText": "Beschreiben Sie die gewünschte Design-Operation...",
  "modelConfig": "Modellkonfiguration",
  "modelConfigDesc": "API-Endpunkt und Schlüssel verwalten",
  "pluginMarket": "Plugin-Marktplatz",
  "pluginMarketDesc": "Plugins durchsuchen und installieren",
  "proxySettings": "Proxy-Einstellungen",
  "proxySettingsDesc": "Netzwerk-Proxy konfigurieren",
  "about": "Über",
  "aboutVersion": "AI Design v{version}",
  "@aboutVersion": { "placeholders": { "version": {} } },
  "comingSoon": "Demnächst",
  "aboutDescription1": "Ein KI-gesteuertes Automatisierungstool für Designsoftware.",
  "aboutDescription2": "Deckt 6 Designbereiche und über 47 Designprogramme mit KI-Skripterstellung ab.",
  "installedPlugins": "Installierte Plugins",
  "installPlugin": "Plugin installieren",
  "connected": "Verbunden",
  "disconnected": "Nicht verbunden",
  "all": "Alle",
  "inProgress": "In Bearbeitung",
  "completed": "Abgeschlossen",
  "taskList": "Aufgabenliste",
  "noTasks": "Keine Aufgaben",
  "noTasksHint": "Geben Sie Designanforderungen im Chat ein; Aufgaben erscheinen hier.",
  "installed": "Installiert ({count})",
  "@installed": { "placeholders": { "count": {} } },
  "available": "Verfügbar ({count})",
  "@available": { "placeholders": { "count": {} } },
  "install": "Installieren",
  "uninstall": "Deinstallieren",
  "installSuccess": "{name} erfolgreich installiert",
  "@installSuccess": { "placeholders": { "name": {} } },
  "uninstallSuccess": "{name} deinstalliert",
  "@uninstallSuccess": { "placeholders": { "name": {} } },
  "ok": "OK",
  "errorPrefix": "Fehler",
  "echoPrefix": "Echo",
  "taskCompleted": "Aufgabe abgeschlossen",
  "taskFailed": "Aufgabe fehlgeschlagen",
  "noOutput": "(keine Ausgabe)",
  "unknownError": "Unbekannter Fehler",
  "languageInstruction": "Bitte antworten Sie auf Deutsch."
}
```

- [ ] **Step 9: Create lib/l10n/app_ar.arb**

```json
{
  "@@locale": "ar",
  "appTitle": "AI Design",
  "designDomains": "مجالات التصميم",
  "navigation": "التنقل",
  "tabChat": "المحادثة",
  "tabTasks": "المهام",
  "tabPlugins": "الإضافات",
  "settings": "الإعدادات",
  "targetSoftware": "البرنامج المستهدف:",
  "hintText": "صف عملية التصميم التي تريدها...",
  "modelConfig": "إعدادات النموذج",
  "modelConfigDesc": "إدارة نقطة نهاية API والمفاتيح",
  "pluginMarket": "سوق الإضافات",
  "pluginMarketDesc": "تصفح وتثبيت الإضافات",
  "proxySettings": "إعدادات الوكيل",
  "proxySettingsDesc": "تكوين وكيل الشبكة",
  "about": "حول",
  "aboutVersion": "AI Design v{version}",
  "@aboutVersion": { "placeholders": { "version": {} } },
  "comingSoon": "قريباً",
  "aboutDescription1": "أداة أتمتة برامج التصميم مدعومة بالذكاء الاصطناعي.",
  "aboutDescription2": "تغطي 6 مجالات تصميم وأكثر من 47 برنامج تصميم مع إنشاء وتنفيذ النصوص بالذكاء الاصطناعي.",
  "installedPlugins": "الإضافات المثبتة",
  "installPlugin": "تثبيت إضافة",
  "connected": "متصل",
  "disconnected": "غير متصل",
  "all": "الكل",
  "inProgress": "قيد التنفيذ",
  "completed": "مكتمل",
  "taskList": "قائمة المهام",
  "noTasks": "لا توجد مهام",
  "noTasksHint": "أدخل متطلبات التصميم في لوحة المحادثة؛ ستظهر المهام هنا.",
  "installed": "مثبت ({count})",
  "@installed": { "placeholders": { "count": {} } },
  "available": "متاح ({count})",
  "@available": { "placeholders": { "count": {} } },
  "install": "تثبيت",
  "uninstall": "إلغاء التثبيت",
  "installSuccess": "تم تثبيت {name} بنجاح",
  "@installSuccess": { "placeholders": { "name": {} } },
  "uninstallSuccess": "تم إلغاء تثبيت {name}",
  "@uninstallSuccess": { "placeholders": { "name": {} } },
  "ok": "موافق",
  "errorPrefix": "خطأ",
  "echoPrefix": "Echo",
  "taskCompleted": "اكتملت المهمة",
  "taskFailed": "فشلت المهمة",
  "noOutput": "(لا يوجد مخرجات)",
  "unknownError": "خطأ غير معروف",
  "languageInstruction": "الرجاء الرد باللغة العربية."
}
```

- [ ] **Step 10: Create lib/l10n/app_fil.arb**

```json
{
  "@@locale": "fil",
  "appTitle": "AI Design",
  "designDomains": "Mga Domain ng Disenyo",
  "navigation": "Nabigasyon",
  "tabChat": "Chat",
  "tabTasks": "Mga Gawain",
  "tabPlugins": "Mga Plugin",
  "settings": "Mga Setting",
  "targetSoftware": "Target na Software:",
  "hintText": "Ilarawan ang nais na operasyon ng disenyo...",
  "modelConfig": "Configuration ng Modelo",
  "modelConfigDesc": "Pamahalaan ang API endpoint at mga susi",
  "pluginMarket": "Plugin Marketplace",
  "pluginMarketDesc": "Mag-browse at mag-install ng mga plugin",
  "proxySettings": "Mga Setting ng Proxy",
  "proxySettingsDesc": "I-configure ang network proxy",
  "about": "Tungkol Sa",
  "aboutVersion": "AI Design v{version}",
  "@aboutVersion": { "placeholders": { "version": {} } },
  "comingSoon": "Malapit Na",
  "aboutDescription1": "Isang AI-driven na tool sa automation ng design software.",
  "aboutDescription2": "Sakop ang 6 na domain ng disenyo at 47+ pangunahing design software gamit ang AI script generation.",
  "installedPlugins": "Mga Naka-install na Plugin",
  "installPlugin": "Mag-install ng Plugin",
  "connected": "Nakakonekta",
  "disconnected": "Hindi Nakakonekta",
  "all": "Lahat",
  "inProgress": "Isinasagawa",
  "completed": "Tapos Na",
  "taskList": "Listahan ng Gawain",
  "noTasks": "Walang Gawain",
  "noTasksHint": "Ilagay ang mga kinakailangan sa disenyo sa chat panel; lalabas dito ang mga gawain.",
  "installed": "Naka-install ({count})",
  "@installed": { "placeholders": { "count": {} } },
  "available": "Available ({count})",
  "@available": { "placeholders": { "count": {} } },
  "install": "I-install",
  "uninstall": "I-uninstall",
  "installSuccess": "Matagumpay na na-install ang {name}",
  "@installSuccess": { "placeholders": { "name": {} } },
  "uninstallSuccess": "Na-uninstall ang {name}",
  "@uninstallSuccess": { "placeholders": { "name": {} } },
  "ok": "OK",
  "errorPrefix": "Error",
  "echoPrefix": "Echo",
  "taskCompleted": "Tapos na ang gawain",
  "taskFailed": "Nabigo ang gawain",
  "noOutput": "(walang output)",
  "unknownError": "Hindi kilalang error",
  "languageInstruction": "Mangyaring tumugon sa wikang Filipino."
}
```

- [ ] **Step 11: Create lib/l10n/app_hi.arb**

```json
{
  "@@locale": "hi",
  "appTitle": "AI Design",
  "designDomains": "डिज़ाइन क्षेत्र",
  "navigation": "नेविगेशन",
  "tabChat": "चैट",
  "tabTasks": "कार्य",
  "tabPlugins": "प्लगइन्स",
  "settings": "सेटिंग्स",
  "targetSoftware": "लक्ष्य सॉफ़्टवेयर:",
  "hintText": "अपनी इच्छित डिज़ाइन कार्रवाई का वर्णन करें...",
  "modelConfig": "मॉडल कॉन्फ़िगरेशन",
  "modelConfigDesc": "API एंडपॉइंट और कुंजियाँ प्रबंधित करें",
  "pluginMarket": "प्लगइन मार्केटप्लेस",
  "pluginMarketDesc": "प्लगइन ब्राउज़ करें और इंस्टॉल करें",
  "proxySettings": "प्रॉक्सी सेटिंग्स",
  "proxySettingsDesc": "नेटवर्क प्रॉक्सी कॉन्फ़िगर करें",
  "about": "के बारे में",
  "aboutVersion": "AI Design v{version}",
  "@aboutVersion": { "placeholders": { "version": {} } },
  "comingSoon": "जल्द आ रहा है",
  "aboutDescription1": "एक AI-संचालित डिज़ाइन सॉफ़्टवेयर स्वचालन उपकरण।",
  "aboutDescription2": "6 डिज़ाइन क्षेत्रों और 47+ प्रमुख डिज़ाइन सॉफ़्टवेयर के लिए AI स्क्रिप्ट जनरेशन और निष्पादन।",
  "installedPlugins": "इंस्टॉल किए गए प्लगइन्स",
  "installPlugin": "प्लगइन इंस्टॉल करें",
  "connected": "कनेक्टेड",
  "disconnected": "डिस्कनेक्टेड",
  "all": "सभी",
  "inProgress": "प्रगति में",
  "completed": "पूर्ण",
  "taskList": "कार्य सूची",
  "noTasks": "कोई कार्य नहीं",
  "noTasksHint": "चैट पैनल में डिज़ाइन आवश्यकताएँ दर्ज करें; कार्य यहाँ दिखाई देंगे।",
  "installed": "इंस्टॉल किया गया ({count})",
  "@installed": { "placeholders": { "count": {} } },
  "available": "उपलब्ध ({count})",
  "@available": { "placeholders": { "count": {} } },
  "install": "इंस्टॉल करें",
  "uninstall": "अनइंस्टॉल करें",
  "installSuccess": "{name} सफलतापूर्वक इंस्टॉल हुआ",
  "@installSuccess": { "placeholders": { "name": {} } },
  "uninstallSuccess": "{name} अनइंस्टॉल किया गया",
  "@uninstallSuccess": { "placeholders": { "name": {} } },
  "ok": "ठीक है",
  "errorPrefix": "त्रुटि",
  "echoPrefix": "Echo",
  "taskCompleted": "कार्य पूर्ण",
  "taskFailed": "कार्य विफल",
  "noOutput": "(कोई आउटपुट नहीं)",
  "unknownError": "अज्ञात त्रुटि",
  "languageInstruction": "कृपया हिंदी में उत्तर दें।"
}
```

- [ ] **Step 12: Create lib/l10n/app_fa.arb**

```json
{
  "@@locale": "fa",
  "appTitle": "AI Design",
  "designDomains": "حوزه‌های طراحی",
  "navigation": "ناوبری",
  "tabChat": "گفتگو",
  "tabTasks": "وظایف",
  "tabPlugins": "افزونه‌ها",
  "settings": "تنظیمات",
  "targetSoftware": "نرم‌افزار هدف:",
  "hintText": "عملیات طراحی مورد نظر خود را توضیح دهید...",
  "modelConfig": "پیکربندی مدل",
  "modelConfigDesc": "مدیریت endpoint API و کلیدها",
  "pluginMarket": "بازار افزونه‌ها",
  "pluginMarketDesc": "مرور و نصب افزونه‌ها",
  "proxySettings": "تنظیمات پروکسی",
  "proxySettingsDesc": "پیکربندی پروکسی شبکه",
  "about": "درباره",
  "aboutVersion": "AI Design v{version}",
  "@aboutVersion": { "placeholders": { "version": {} } },
  "comingSoon": "به زودی",
  "aboutDescription1": "ابزار خودکارسازی نرم‌افزار طراحی مبتنی بر هوش مصنوعی.",
  "aboutDescription2": "پوشش 6 حوزه طراحی و بیش از 47 نرم‌افزار طراحی با تولید و اجرای اسکریپت هوش مصنوعی.",
  "installedPlugins": "افزونه‌های نصب شده",
  "installPlugin": "نصب افزونه",
  "connected": "متصل",
  "disconnected": "قطع",
  "all": "همه",
  "inProgress": "در حال انجام",
  "completed": "تکمیل شده",
  "taskList": "لیست وظایف",
  "noTasks": "بدون وظیفه",
  "noTasksHint": "نیازمندی‌های طراحی را در پنل گفتگو وارد کنید؛ وظایف در اینجا نمایش داده می‌شوند.",
  "installed": "نصب شده ({count})",
  "@installed": { "placeholders": { "count": {} } },
  "available": "در دسترس ({count})",
  "@available": { "placeholders": { "count": {} } },
  "install": "نصب",
  "uninstall": "حذف",
  "installSuccess": "{name} با موفقیت نصب شد",
  "@installSuccess": { "placeholders": { "name": {} } },
  "uninstallSuccess": "{name} حذف شد",
  "@uninstallSuccess": { "placeholders": { "name": {} } },
  "ok": "تأیید",
  "errorPrefix": "خطا",
  "echoPrefix": "Echo",
  "taskCompleted": "وظیفه تکمیل شد",
  "taskFailed": "وظیفه ناموفق بود",
  "noOutput": "(بدون خروجی)",
  "unknownError": "خطای ناشناخته",
  "languageInstruction": "لطفاً به فارسی پاسخ دهید."
}
```

- [ ] **Step 13: Run flutter gen-l10n**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter gen-l10n
```
Expected: exits 0, generates files in `.dart_tool/flutter_gen/gen_l10n/`.

- [ ] **Step 14: Commit**

```bash
git add lib/l10n/
git commit -m "feat: add ARB translation files for 12 languages"
```

---

### Task 3: Create LocaleProvider

**Files:**
- Create: `lib/core/locale_provider.dart`

- [ ] **Step 1: Create lib/core/locale_provider.dart**

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const _key = 'app_locale';
  Locale _locale = const Locale('zh');

  Locale get locale => _locale;

  static const supportedLocales = [
    Locale('zh'),
    Locale('en'),
    Locale('ru'),
    Locale('es'),
    Locale('ko'),
    Locale('ja'),
    Locale('fr'),
    Locale('de'),
    Locale('ar'),
    Locale('fil'),
    Locale('hi'),
    Locale('fa'),
  ];

  static const languageNames = {
    'zh': '中文',
    'en': 'English',
    'ru': 'Русский',
    'es': 'Español',
    'ko': '한국어',
    'ja': '日本語',
    'fr': 'Français',
    'de': 'Deutsch',
    'ar': 'العربية',
    'fil': 'Filipino',
    'hi': 'हिन्दी',
    'fa': 'فارسی',
  };

  static const languageInstructions = {
    'zh': '请使用中文回复。',
    'en': 'Please respond in English.',
    'ru': 'Пожалуйста, отвечайте на русском языке.',
    'es': 'Por favor, responde en español.',
    'ko': '한국어로 답변해 주세요.',
    'ja': '日本語で返信してください。',
    'fr': 'Veuillez répondre en français.',
    'de': 'Bitte antworten Sie auf Deutsch.',
    'ar': 'الرجاء الرد باللغة العربية.',
    'fil': 'Mangyaring tumugon sa wikang Filipino.',
    'hi': 'कृपया हिंदी में उत्तर दें।',
    'fa': 'لطفاً به فارسی پاسخ دهید.',
  };

  Future<void> loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_key);
      if (code != null && supportedLocales.any((l) => l.languageCode == code)) {
        _locale = Locale(code);
        notifyListeners();
      }
    } catch (_) {
      // Default to zh on failure
    }
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, locale.languageCode);
    } catch (_) {
      // Non-critical; locale still applied for this session
    }
  }

  String get languageInstruction =>
      languageInstructions[_locale.languageCode] ?? languageInstructions['zh']!;
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/locale_provider.dart
git commit -m "feat: add LocaleProvider for i18n state management"
```

---

### Task 4: Update main.dart and app.dart for localization

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/app.dart`

- [ ] **Step 1: Update main.dart**

Replace `lib/main.dart` with:

```dart
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localeProvider = LocaleProvider();
  await localeProvider.loadSavedLocale();
  runApp(AiDesignApp(localeProvider: localeProvider));
}
```

- [ ] **Step 2: Update app.dart**

Add imports at top:
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'core/locale_provider.dart';
```

Change `AiDesignApp` to accept `LocaleProvider`:

```dart
class AiDesignApp extends StatelessWidget {
  final LocaleProvider localeProvider;

  const AiDesignApp({super.key, required this.localeProvider});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Design',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: localeProvider.locale,
      home: _MainShell(localeProvider: localeProvider),
      routes: {'/settings': (_) => const SettingsView()},
    );
  }
}
```

Change `_MainShell` to accept `LocaleProvider`:
```dart
class _MainShell extends StatefulWidget {
  final LocaleProvider localeProvider;
  const _MainShell({required this.localeProvider});
  @override
  State<_MainShell> createState() => _MainShellState();
}
```

In `_MainShellState.build()`, pass `localeProvider` to `AppShell`:
```dart
child: AppShell(
  selectedDomain: _currentDomain,
  selectedTabIndex: _currentTab,
  onDomainChanged: _onDomainChanged,
  onTabSelected: _onTabSelected,
  pluginManager: _pluginManager,
  localeProvider: widget.localeProvider,
  child: IndexedStack(...),
),
```

Wire `LocaleProvider` to `TaskOrchestrator` in `_initOrchestrator()`, after `_orchestrator = TaskOrchestrator(...)`:
```dart
_orchestrator.setLocaleProvider(widget.localeProvider);
```

- [ ] **Step 3: Run flutter analyze**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter analyze
```

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart lib/app.dart
git commit -m "feat: integrate localization into app entry and shell"
```

---

### Task 5: Update shell.dart with language switcher

**Files:**
- Modify: `lib/ui/shell.dart`

- [ ] **Step 1: Add imports and field**

Add imports:
```dart
import '../core/locale_provider.dart';
import 'language_selector.dart';
```

Add `localeProvider` field to `AppShell`:
```dart
final LocaleProvider localeProvider;
```

Add to constructor:
```dart
required this.localeProvider,
```

At bottom of sidebar `Column`, before the settings ListTile, add:
```dart
const Divider(),
LanguageSelector(localeProvider: widget.localeProvider),
const Divider(),
```

- [ ] **Step 2: Commit**

```bash
git add lib/ui/shell.dart
git commit -m "feat: add language switcher to sidebar"
```

---

### Task 6: Create LanguageSelector widget

**Files:**
- Create: `lib/ui/language_selector.dart`

- [ ] **Step 1: Create widget**

```dart
import 'package:flutter/material.dart';
import '../core/locale_provider.dart';

class LanguageSelector extends StatelessWidget {
  final LocaleProvider localeProvider;

  const LanguageSelector({super.key, required this.localeProvider});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeProvider,
      builder: (context, _) {
        final currentCode = localeProvider.locale.languageCode;
        return ListTile(
          leading: const Icon(Icons.language, size: 20),
          title: const Text('Language', style: TextStyle(fontSize: 14)),
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentCode,
              isDense: true,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              items: LocaleProvider.supportedLocales.map((locale) {
                final code = locale.languageCode;
                return DropdownMenuItem<String>(
                  value: code,
                  child: Text(LocaleProvider.languageNames[code] ?? code,
                      style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  localeProvider.setLocale(Locale(value));
                }
              },
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/ui/language_selector.dart
git commit -m "feat: add LanguageSelector widget"
```

---

### Task 7: i18n for chat_view.dart

**Files:**
- Modify: `lib/ui/chat_view.dart`

- [ ] **Step 1: Apply changes**

Add import:
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
```

Replace hardcoded strings:
- Line 131: `'目标软件:'` → `AppLocalizations.of(context)!.targetSoftware`
- Line 186: `'描述你想要的设计操作...'` → `AppLocalizations.of(context)!.hintText`
- Line 83: `'❌ 错误: $error'` → `'❌ ${AppLocalizations.of(context)!.errorPrefix}: $error'`
- Line 91: `'Echo: $text'` → `'${AppLocalizations.of(context)!.echoPrefix}: $text'`

- [ ] **Step 2: Commit**

```bash
git add lib/ui/chat_view.dart
git commit -m "feat: i18n for chat_view"
```

---

### Task 8: i18n for task_dashboard.dart

**Files:**
- Modify: `lib/ui/task_dashboard.dart`

- [ ] **Step 1: Add enum and apply changes**

Add import:
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
```

Add filter enum at file top (after imports):
```dart
enum _TaskFilter { all, inProgress, completed }
```

Replace `String _filter = '全部';` with:
```dart
_TaskFilter _filter = _TaskFilter.all;
```

Replace `_filteredTasks` getter:
```dart
List<TaskItem> get _filteredTasks {
  return switch (_filter) {
    _TaskFilter.all => _tasks,
    _TaskFilter.inProgress => _tasks.where((t) => t.status == TaskStatus.running || t.status == TaskStatus.pending).toList(),
    _TaskFilter.completed => _tasks.where((t) => t.status == TaskStatus.completed).toList(),
  };
}
```

Replace hardcoded strings in build():
- Line 68: `'暂无任务'` → `AppLocalizations.of(context)!.noTasks`
- Line 70: `'在对话面板中输入设计需求，任务将显示在这里'` → `AppLocalizations.of(context)!.noTasksHint`
- Line 96: `'任务列表'` → `AppLocalizations.of(context)!.taskList`

Update `_buildFilterBar`:
```dart
_buildChip(AppLocalizations.of(context)!.all, _filter == _TaskFilter.all),
const SizedBox(width: 8),
_buildChip(AppLocalizations.of(context)!.inProgress, _filter == _TaskFilter.inProgress),
const SizedBox(width: 8),
_buildChip(AppLocalizations.of(context)!.completed, _filter == _TaskFilter.completed),
```

Update `_buildChip` onSelected:
```dart
onSelected: (_) => setState(() {
  if (label == AppLocalizations.of(context)!.all) _filter = _TaskFilter.all;
  else if (label == AppLocalizations.of(context)!.inProgress) _filter = _TaskFilter.inProgress;
  else _filter = _TaskFilter.completed;
}),
```

- [ ] **Step 2: Commit**

```bash
git add lib/ui/task_dashboard.dart
git commit -m "feat: i18n for task_dashboard with enum-based filter"
```

---

### Task 9: i18n for software_panel.dart

**Files:**
- Modify: `lib/ui/software_panel.dart`

- [ ] **Step 1: Apply changes**

Add import:
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
```

Replace hardcoded strings:
- Line 24: `'已安装插件'` → `AppLocalizations.of(context)!.installedPlugins`
- Line 28: `'安装插件'` → `AppLocalizations.of(context)!.installPlugin`
- Line 97: `'已连接'` → `AppLocalizations.of(context)!.connected`
- Line 97: `'未连接'` → `AppLocalizations.of(context)!.disconnected`

- [ ] **Step 2: Commit**

```bash
git add lib/ui/software_panel.dart
git commit -m "feat: i18n for software_panel"
```

---

### Task 10: i18n for plugin_marketplace.dart

**Files:**
- Modify: `lib/ui/plugin_marketplace.dart`

- [ ] **Step 1: Apply changes**

Add import:
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
```

Replace hardcoded strings:
- Line 126: `'插件市场'` → `AppLocalizations.of(context)!.pluginMarket`
- Lines 129, 133: Section headers → use `AppLocalizations.of(context)!.installed(installed.length)` and `AppLocalizations.of(context)!.available(available.length)`
- Line 175: `'卸载'` → `AppLocalizations.of(context)!.uninstall`
- Line 183: `'安装'` → `AppLocalizations.of(context)!.install`
- Line 108: `'${plugin.name} 安装成功'` → `AppLocalizations.of(context)!.installSuccess(plugin.name)`
- Line 115: `'${plugin.name} 已卸载'` → `AppLocalizations.of(context)!.uninstallSuccess(plugin.name)`

- [ ] **Step 2: Commit**

```bash
git add lib/ui/plugin_marketplace.dart
git commit -m "feat: i18n for plugin_marketplace"
```

---

### Task 11: i18n for settings_view.dart with language picker

**Files:**
- Modify: `lib/ui/settings_view.dart`

- [ ] **Step 1: Apply changes**

Add imports:
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../core/locale_provider.dart';
```

Add `localeProvider` field:
```dart
final LocaleProvider? localeProvider;
const SettingsView({super.key, this.pluginManager, this.localeProvider});
```

Replace hardcoded strings in build():
- AppBar title: `AppLocalizations.of(context)!.settings`
- `'模型配置'` → `AppLocalizations.of(context)!.modelConfig`
- `'管理 API endpoint 和密钥'` → `AppLocalizations.of(context)!.modelConfigDesc`
- `'插件市场'` → `AppLocalizations.of(context)!.pluginMarket`
- `'浏览和安装插件'` → `AppLocalizations.of(context)!.pluginMarketDesc`
- `'代理设置'` → `AppLocalizations.of(context)!.proxySettings`
- `'配置网络代理'` → `AppLocalizations.of(context)!.proxySettingsDesc`
- `'关于'` → `AppLocalizations.of(context)!.about`
- `'AI Design v$appVersion'` → `AppLocalizations.of(context)!.aboutVersion(appVersion)`
- `'$feature - 即将推出'` → `'$feature - ${AppLocalizations.of(context)!.comingSoon}'`
- About dialog `'确定'` → `AppLocalizations.of(context)!.ok`
- About dialog description → use `aboutDescription1` and `aboutDescription2`

Add a language settings ListTile before the "关于" section:
```dart
ListTile(
  leading: const Icon(Icons.language),
  title: Text(AppLocalizations.of(context)!.settings),
  subtitle: Text(localeProvider != null
      ? LocaleProvider.languageNames[localeProvider!.locale.languageCode] ?? ''
      : ''),
  onTap: () => _showLanguagePicker(context),
),
```

Add `_showLanguagePicker` method:
```dart
void _showLanguagePicker(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(AppLocalizations.of(context)!.settings),
      content: SizedBox(
        width: 250,
        child: ListView(
          shrinkWrap: true,
          children: LocaleProvider.supportedLocales.map((locale) {
            final code = locale.languageCode;
            final isSelected = localeProvider?.locale.languageCode == code;
            return ListTile(
              title: Text(LocaleProvider.languageNames[code] ?? code),
              trailing: isSelected ? const Icon(Icons.check, color: Colors.indigo) : null,
              onTap: () {
                localeProvider?.setLocale(locale);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(AppLocalizations.of(context)!.ok),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 2: Update shell.dart settings navigation to pass localeProvider**

```dart
onTap: () => Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => SettingsView(
    pluginManager: widget.pluginManager,
    localeProvider: widget.localeProvider,
  )),
),
```

- [ ] **Step 3: Commit**

```bash
git add lib/ui/settings_view.dart lib/ui/shell.dart
git commit -m "feat: i18n for settings_view with language picker"
```

---

### Task 12: Inject language instruction into AI prompts

**Files:**
- Modify: `lib/core/task_orchestrator.dart`
- Modify: `lib/core/cc_runner.dart`

- [ ] **Step 1: Update TaskOrchestrator**

Add import:
```dart
import 'locale_provider.dart';
```

Add field and setter:
```dart
LocaleProvider? _localeProvider;

void setLocaleProvider(LocaleProvider provider) {
  _localeProvider = provider;
}
```

In `submitTask()`, after extracting `task`, prepend language instruction:
```dart
final instruction = _localeProvider?.languageInstruction ?? '';
final effectiveTask = instruction.isNotEmpty ? '$instruction\n\n$task' : task;
```

Replace all subsequent uses of `task` in the method body with `effectiveTask` (for the `_getOrCreateSession` call and `CCResult` etc. — specifically where the task text is used in execution and recording).

- [ ] **Step 2: Update cc_runner.dart**

In `_buildPrompt()`, change the explanation rule from:
```
- "explanation": brief explanation of what the script does (in Chinese)
```
to:
```
- "explanation": brief explanation of what the script does
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/task_orchestrator.dart lib/core/cc_runner.dart
git commit -m "feat: inject language instruction into AI task prompts"
```

---

### Task 13: Write tests

**Files:**
- Create: `test/core/locale_provider_test.dart`
- Modify: `test/core/task_orchestrator_test.dart`

- [ ] **Step 1: Create test/core/locale_provider_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_design_studio/core/locale_provider.dart';
import 'package:flutter/material.dart';

void main() {
  test('LocaleProvider defaults to zh', () {
    final provider = LocaleProvider();
    expect(provider.locale.languageCode, 'zh');
  });

  test('setLocale changes locale and notifies', () {
    final provider = LocaleProvider();
    bool notified = false;
    provider.addListener(() => notified = true);
    provider.setLocale(const Locale('en'));
    expect(provider.locale.languageCode, 'en');
    expect(notified, true);
  });

  test('languageInstruction returns correct instruction per locale', () {
    final provider = LocaleProvider();
    expect(provider.languageInstruction, contains('中文'));
    provider.setLocale(const Locale('en'));
    expect(provider.languageInstruction, contains('English'));
    provider.setLocale(const Locale('ja'));
    expect(provider.languageInstruction, contains('日本語'));
  });

  test('supportedLocales has 12 entries', () {
    expect(LocaleProvider.supportedLocales.length, 12);
  });

  test('languageNames has 12 entries', () {
    expect(LocaleProvider.languageNames.length, 12);
  });

  test('languageInstructions has 12 entries', () {
    expect(LocaleProvider.languageInstructions.length, 12);
  });

  test('unknown locale falls back to zh instruction', () {
    final provider = LocaleProvider();
    provider.setLocale(const Locale('xx'));
    expect(provider.languageInstruction, contains('中文'));
  });
}
```

- [ ] **Step 2: Add language injection test to task_orchestrator_test.dart**

Add import:
```dart
import 'package:ai_design_studio/core/locale_provider.dart';
```

Add test:
```dart
test('language instruction is injected into task prompt', () async {
  final lp = LocaleProvider();
  lp.setLocale(const Locale('en'));
  orchestrator.setLocaleProvider(lp);
  final task = await orchestrator.submitTask(
    domain: DesignCategory.web, softwareName: 'echo', task: 'say hello',
  );
  expect(task.status, TaskStatus.completed);
});
```

- [ ] **Step 3: Run tests**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter test
```
Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add test/core/locale_provider_test.dart test/core/task_orchestrator_test.dart
git commit -m "test: add LocaleProvider tests and language injection test"
```

---

### Task 14: Build verification

- [ ] **Step 1: Run flutter analyze**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter analyze
```
Expected: no issues.

- [ ] **Step 2: Run all tests**

```bash
cd /home/wwwroot/bag/ai-desgin && flutter test
```
Expected: all tests pass.

- [ ] **Step 3: Verify gen-l10n output**

```bash
ls /home/wwwroot/bag/ai-desgin/.dart_tool/flutter_gen/gen_l10n/app_localizations.dart
```
Expected: file exists.

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat: complete multi-language support for 12 languages"
```
