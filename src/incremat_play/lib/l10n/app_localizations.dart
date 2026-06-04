import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Lightweight, code-based localization for the Play app. Each string is a
/// getter carrying both English and Chinese via [_t]; access anywhere with
/// `AppLocalizations.of(context)`. The active language is driven by
/// `MaterialApp.locale` (see `localeProvider`).
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [Locale('en'), Locale('zh')];

  bool get isZh => locale.languageCode == 'zh';
  String _t(String en, String zh) => isZh ? zh : en;

  // ── Bottom navigation ───────────────────────────────────────────────────────
  String get navHome => _t('Home', '主页');
  String get navSanctuary => _t('Sanctuary', '乐园');
  String get navHistory => _t('History', '历史');
  String get navProfile => _t('Profile', '我的');

  // ── Common ──────────────────────────────────────────────────────────────────
  String get or => _t('or', '或');

  // ── Login ───────────────────────────────────────────────────────────────────
  String get appTagline => _t('Your daily exercise companion', '您的每日锻炼伙伴');
  String get enterPlayCode => _t('Enter your play code', '输入您的 Play 代码');
  String get caregiverGivesCode =>
      _t('Your caregiver will give you this code.', '您的护理人会提供此代码。');
  String get getStarted => _t('Get Started', '开始');
  String get tapNfcTag => _t('Tap NFC Tag', '轻触 NFC 标签');
  String get holdTagToPhone => _t('Hold tag to phone…', '将标签靠近手机…');
  String get askCaregiverForCode => _t(
      "Ask your caregiver for your play code\nif you don't have one yet.",
      '如果还没有 Play 代码，\n请向您的护理人索取。');
  // Auth error/status messages (returned by AuthService).
  String get couldNotSignIn =>
      _t('Could not sign in. Please try again.', '无法登录，请重试。');
  String get couldNotReadCard =>
      _t('Could not read card. Try again.', '无法读取卡片，请重试。');
  String get somethingWentWrong =>
      _t('Something went wrong. Please try again.', '出了点问题，请重试。');
  String get codeNotFound =>
      _t('Code not found. Check the code and try again.', '未找到代码，请检查后重试。');
  String get codeNotSetUp => _t(
      'This code is not set up correctly. Ask your caregiver.',
      '此代码设置不正确，请咨询您的护理人。');
  String get cardNotEnrolled => _t(
      'This card has not been enrolled. Ask your caregiver to set it up.',
      '此卡片尚未登记，请让您的护理人设置。');
  String get invalidCardData =>
      _t('Invalid card data. Ask your caregiver.', '卡片数据无效，请咨询您的护理人。');
  String get connectionTimedOut => _t(
      'Connection timed out. Check your internet and try again.',
      '连接超时，请检查网络后重试。');
  String get codeLinkedOtherDevice => _t(
      'This code is linked to another device. Ask your caregiver.',
      '此代码已关联到其他设备，请咨询您的护理人。');
  String get signInNotEnabled => _t(
      'Sign-in is not enabled for this app. Ask your caregiver.',
      '此应用未启用登录，请咨询您的护理人。');
  String get noInternet =>
      _t('No internet connection. Please try again.', '无网络连接，请重试。');
  String errorWithCode(String code) =>
      _t('Something went wrong ($code). Please try again.',
          '出了点问题（$code），请重试。');

  // ── Home / Play tab ─────────────────────────────────────────────────────────
  String get helloPlain => _t('Hello!', '你好！');
  String get helloPrefix => _t('Hello, ', '你好，');
  String get exerciseTogether => _t('Exercise Together', '一起锻炼');
  String get pairCountLive => _t('Pair up & count reps live', '配对并实时计数');
  String get weeklyProgressPath => _t('Weekly Progress Path', '每周进度路径');
  String streakDays(int n) => _t('$n day${n == 1 ? '' : 's'}', '$n 天');
  String get allGoalsMet =>
      _t('All 7 goals met this week — amazing!', '本周 7 个目标全部达成 — 太棒了！');
  String goalsMetThisWeek(int n) =>
      _t('$n of 7 goals met this week', '本周已达成 $n / 7 个目标');
  String get todaysGoalComplete => _t("Today's Goal — Complete!", '今日目标 — 已完成！');
  String get todaysGoal => _t("Today's Goal", '今日目标');
  String get liveBadge => _t('LIVE', '实时');
  String repsGoal(int goal) => _t('/ $goal reps', '/ $goal 次');
  String get eggReadyToHatch =>
      _t('You have an egg ready to hatch!', '您有一枚蛋可以孵化了！');
  String get hatchNow => _t('Hatch Now!', '立即孵化！');
  String get noCompanionsYet => _t('No companions yet', '还没有伙伴');
  String get earnFirstEgg => _t(
      'Complete your daily exercise goal\nconsistently to earn your first egg!',
      '坚持完成每日锻炼目标，\n即可获得第一枚蛋！');
  String get mysteryEgg => _t('Mystery Egg', '神秘蛋');
  String get companion => _t('Companion', '伙伴');
  String expProgress(int exp, int next) => _t('$exp / $next EXP', '$exp / $next 经验');
  String get fullyGrown => _t('Fully Grown!', '已完全成长！');

  // ── Celebration / evolution / hatching ──────────────────────────────────────
  String get youEarnedEgg => _t('You earned an egg!', '您获得了一枚蛋！');
  String get companionWaiting => _t(
      'A new companion is waiting inside.\nVisit Home to hatch it!',
      '一个新伙伴正在里面等待。\n回到主页孵化它吧！');
  String get wonderful => _t('Wonderful!', '太好了！');
  String get amazing => _t('Amazing!', '太棒了！');
  String get itsHatching => _t("It's hatching!", '正在孵化！');
  String get eggIsReady => _t('Your egg is ready!', '您的蛋准备好了！');
  String get somethingComingOut =>
      _t("Something's coming out...", '有东西要出来了…');
  String get getReady => _t('Get ready...', '准备好…');
  String get itHatched => _t('It hatched!', '孵化成功！');
  String get newCompanionAppeared =>
      _t('A new companion appeared!', '一个新伙伴出现了！');
  String get letsGo => _t("Let's go!", '出发吧！');
  String evolvedInto(String prev, String next) =>
      _t('$prev evolved into $next!', '$prev 进化成了 $next！');

  // ── History ─────────────────────────────────────────────────────────────────
  String get historyTitle => _t('History', '历史');
  String get historySubtitle =>
      _t("Your companions' growth journey", '您的伙伴的成长之旅');
  String get receivedMysteryEgg => _t('Received a Mystery Egg', '获得了一枚神秘蛋');
  String get newEggReadyToHatch =>
      _t('A new egg, ready to hatch!', '一枚新蛋，准备孵化！');
  String hatchedInto(String name) => _t('Hatched into $name!', '孵化成了 $name！');
  String get aNewCompanion => _t('a new companion', '一个新伙伴');
  String expDailyGoalMet(int amount) =>
      _t('+$amount EXP — Daily Goal Met', '+$amount 经验 — 已达成每日目标');
  String evolvedTo(String name) => _t('Evolved to $name!', '进化为 $name！');
  String get noExpEvents => _t('No EXP events yet', '暂无经验记录');
  String get noExpEventsSubtitle => _t(
      'When your companion gains EXP,\nit will appear here.',
      '当您的伙伴获得经验时，\n将显示在这里。');

  // ── Sanctuary ───────────────────────────────────────────────────────────────
  String get sanctuaryTitle => _t('Sanctuary', '乐园');
  String get sanctuarySubtitle =>
      _t('Your journey & companions', '您的旅程与伙伴');
  String get activeLineage => _t('1. ACTIVE LINEAGE', '1. 当前血统');
  String get discoveries => _t('2. DISCOVERIES', '2. 图鉴发现');
  String get chooseCompanion => _t('Choose companion', '选择伙伴');
  String get undiscovered => _t('Undiscovered', '未发现');
  String get nowBadge => _t('NOW', '当前');
  String get reachToReveal => _t(
      'Reach this evolution to reveal its story.', '达到此进化阶段以揭示它的故事。');
  String get fullyGrownLower => _t('Fully grown!', '已完全成长！');
  String get evolvedShort => _t('Evolved', '已进化');
  String get notYetReached => _t('Not yet reached', '尚未达到');
  String get futureEvolution => _t(
      'A future evolution — keep growing to reveal it.',
      '未来的进化 — 继续成长以揭示它。');
  String get hatchFirstEgg =>
      _t('Hatch your first egg to begin your lineage!', '孵化您的第一枚蛋，开启血统之旅！');
  String evolutionsUnlocked(String label, int unlocked, int total) => _t(
      '$label · $unlocked of $total evolutions unlocked',
      '$label · $total 个进化中已解锁 $unlocked 个');
  String speciesProgress(String label, int unlocked, int total) =>
      _t('$label · $unlocked/$total', '$label · $unlocked/$total');
  String expBadge(int exp, int next) => _t('$exp / $next EXP', '$exp / $next 经验');

  // ── Duet ────────────────────────────────────────────────────────────────────
  String get couldNotCreateDuet =>
      _t('Could not create a duet. Try again.', '无法创建二人组，请重试。');
  String get couldNotJoinDuet =>
      _t('Could not join. Check the code.', '无法加入，请检查代码。');
  String get workOutAsPair => _t('Work out as a pair', '两人一起锻炼');
  String get duetIntro => _t(
      'Exercise at the same time as a friend or family member — your reps add together on one live meter.',
      '与朋友或家人同时锻炼 — 你们的次数会合并到一个实时计数器上。');
  String get createDuet => _t('Create a Duet', '创建二人组');
  String get orJoinOne => _t('or join one', '或加入一个');
  String get enterDuetCode => _t('Enter duet code', '输入二人组代码');
  String get joinDuet => _t('Join Duet', '加入二人组');
  String get couldntLoadDuet => _t("Couldn't load this duet.", '无法加载此二人组。');
  String get duetEnded => _t('This duet has ended.', '此二人组已结束。');
  String get partner => _t('Partner', '伙伴');
  String get shareCodeWithPartner =>
      _t('Share this code with your partner', '将此代码分享给您的伙伴');
  String get duetCodeCopied => _t('Duet code copied', '二人组代码已复制');
  String get waitingForPartner =>
      _t('Waiting for your partner to join…', '正在等待伙伴加入…');
  String get youWord => _t('You', '您');
  String get amazingTeamwork => _t('Amazing teamwork! 🎉', '团队合作太棒了！🎉');
  String get repsTogether => _t('Reps together', '共同次数');
  String combinedGoal(int total, int target) =>
      _t('$total / $target combined goal', '$total / $target 共同目标');
  String get endDuet => _t('End Duet', '结束二人组');
  String get back => _t('Back', '返回');
  String nameYou(String name) => _t('$name (you)', '$name（您）');
  String get exercisingNow => _t('Exercising now', '正在锻炼');
  String get waitingToStart => _t('Waiting to start…', '等待开始…');

  // ── Profile ─────────────────────────────────────────────────────────────────
  String get profileTitle => _t('Profile', '我的');
  String get profileSubtitle =>
      _t('Your settings & accessibility', '您的设置与无障碍');
  String get exerciser => _t('Exerciser', '锻炼者');
  String get accessibility => _t('Accessibility', '无障碍');
  String get textSize => _t('Text Size', '文字大小');
  String get appearance => _t('Appearance', '外观');
  String get themeLight => _t('Light', '浅色');
  String get themeDark => _t('Dark', '深色');
  String get themeSystem => _t('System', '跟随系统');
  String get highContrast => _t('High Contrast', '高对比度');
  String get enableHighContrast => _t('Enable high contrast', '启用高对比度');
  String get signOut => _t('Sign Out', '退出登录');
  String get signOutQ => _t('Sign out?', '退出登录？');
  String get signOutBody => _t(
      'You can sign back in with your play code.', '您可以使用 Play 代码重新登录。');
  String get cancel => _t('Cancel', '取消');
  String get language => _t('Language', '语言');
  String get english => _t('English', 'English');
  String get chinese => _t('中文', '中文');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
