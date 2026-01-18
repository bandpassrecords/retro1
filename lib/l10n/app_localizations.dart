import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt')
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'Retro1'**
  String get appTitle;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @generateVideos.
  ///
  /// In en, this message translates to:
  /// **'Generate Videos'**
  String get generateVideos;

  /// No description provided for @editTodayEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit Today\'s Entry'**
  String get editTodayEntry;

  /// No description provided for @recordToday.
  ///
  /// In en, this message translates to:
  /// **'Record Today'**
  String get recordToday;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @confirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm deletion'**
  String get confirmDeletion;

  /// No description provided for @confirmDeletionMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this entry?'**
  String get confirmDeletionMessage;

  /// No description provided for @entryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Entry deleted'**
  String get entryDeleted;

  /// No description provided for @entrySaved.
  ///
  /// In en, this message translates to:
  /// **'Entry saved successfully!'**
  String get entrySaved;

  /// No description provided for @addEntryFor.
  ///
  /// In en, this message translates to:
  /// **'Add entry for {date}'**
  String addEntryFor(String date);

  /// No description provided for @captureOrImport.
  ///
  /// In en, this message translates to:
  /// **'Do you want to capture or import media?'**
  String get captureOrImport;

  /// No description provided for @recordVideo.
  ///
  /// In en, this message translates to:
  /// **'Record Video'**
  String get recordVideo;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @videoFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Video from Gallery'**
  String get videoFromGallery;

  /// No description provided for @photoFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Photo from Gallery'**
  String get photoFromGallery;

  /// No description provided for @chooseHowToRecord.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to record your moment:'**
  String get chooseHowToRecord;

  /// No description provided for @entryAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Entry already exists'**
  String get entryAlreadyExists;

  /// No description provided for @entryAlreadyExistsMessage.
  ///
  /// In en, this message translates to:
  /// **'An entry already exists for this day. Do you want to replace it?'**
  String get entryAlreadyExistsMessage;

  /// No description provided for @editorChooseSecond.
  ///
  /// In en, this message translates to:
  /// **'Editor - Choose 1 Second'**
  String get editorChooseSecond;

  /// No description provided for @playing.
  ///
  /// In en, this message translates to:
  /// **'Playing...'**
  String get playing;

  /// No description provided for @preview1s.
  ///
  /// In en, this message translates to:
  /// **'Preview (1s)'**
  String get preview1s;

  /// No description provided for @errorLoadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Error loading video: {error}'**
  String errorLoadingVideo(String error);

  /// No description provided for @errorSaving.
  ///
  /// In en, this message translates to:
  /// **'Error saving: {error}'**
  String errorSaving(String error);

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @videosOnly.
  ///
  /// In en, this message translates to:
  /// **'Videos Only'**
  String get videosOnly;

  /// No description provided for @photosOnly.
  ///
  /// In en, this message translates to:
  /// **'Photos Only'**
  String get photosOnly;

  /// No description provided for @noCaption.
  ///
  /// In en, this message translates to:
  /// **'No caption'**
  String get noCaption;

  /// No description provided for @generateByPeriod.
  ///
  /// In en, this message translates to:
  /// **'Generate by Period'**
  String get generateByPeriod;

  /// No description provided for @currentMonth.
  ///
  /// In en, this message translates to:
  /// **'Current Month'**
  String get currentMonth;

  /// No description provided for @currentYear.
  ///
  /// In en, this message translates to:
  /// **'Current Year'**
  String get currentYear;

  /// No description provided for @customRange.
  ///
  /// In en, this message translates to:
  /// **'Custom Range'**
  String get customRange;

  /// No description provided for @chooseDates.
  ///
  /// In en, this message translates to:
  /// **'Choose dates'**
  String get chooseDates;

  /// No description provided for @generatingVideo.
  ///
  /// In en, this message translates to:
  /// **'Generating video... This may take a few minutes.'**
  String get generatingVideo;

  /// No description provided for @videoGeneratedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Video generated successfully!'**
  String get videoGeneratedSuccess;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Button label for creating a new video
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newButton;

  /// No description provided for @errorSharing.
  ///
  /// In en, this message translates to:
  /// **'Error sharing: {error}'**
  String errorSharing(String error);

  /// No description provided for @noEntriesFound.
  ///
  /// In en, this message translates to:
  /// **'No entries found for this period.'**
  String get noEntriesFound;

  /// No description provided for @errorGeneratingVideo.
  ///
  /// In en, this message translates to:
  /// **'Error generating video: {error}'**
  String errorGeneratingVideo(String error);

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get enableNotifications;

  /// No description provided for @notificationTime.
  ///
  /// In en, this message translates to:
  /// **'Notification time'**
  String get notificationTime;

  /// No description provided for @reminderAfter.
  ///
  /// In en, this message translates to:
  /// **'Reminder after (hours)'**
  String get reminderAfter;

  /// No description provided for @weeklySummary.
  ///
  /// In en, this message translates to:
  /// **'Weekly summary'**
  String get weeklySummary;

  /// No description provided for @videoQuality.
  ///
  /// In en, this message translates to:
  /// **'Video quality'**
  String get videoQuality;

  /// No description provided for @showDateInVideo.
  ///
  /// In en, this message translates to:
  /// **'Show date in video'**
  String get showDateInVideo;

  /// No description provided for @autoExportEndOfYear.
  ///
  /// In en, this message translates to:
  /// **'Auto export at end of year'**
  String get autoExportEndOfYear;

  /// No description provided for @autoBackup.
  ///
  /// In en, this message translates to:
  /// **'Auto backup'**
  String get autoBackup;

  /// No description provided for @totalEntries.
  ///
  /// In en, this message translates to:
  /// **'Total entries'**
  String get totalEntries;

  /// No description provided for @entriesThisYear.
  ///
  /// In en, this message translates to:
  /// **'Entries this year'**
  String get entriesThisYear;

  /// No description provided for @entries.
  ///
  /// In en, this message translates to:
  /// **'entries'**
  String get entries;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @quality720p.
  ///
  /// In en, this message translates to:
  /// **'720p'**
  String get quality720p;

  /// No description provided for @quality1080p.
  ///
  /// In en, this message translates to:
  /// **'1080p'**
  String get quality1080p;

  /// No description provided for @quality4k.
  ///
  /// In en, this message translates to:
  /// **'4K'**
  String get quality4k;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languagePortuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get languagePortuguese;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguage;

  /// No description provided for @testNotification.
  ///
  /// In en, this message translates to:
  /// **'Test notification'**
  String get testNotification;

  /// No description provided for @testNotificationDescription.
  ///
  /// In en, this message translates to:
  /// **'Send a test notification now'**
  String get testNotificationDescription;

  /// No description provided for @testNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent!'**
  String get testNotificationSent;

  /// No description provided for @testNotificationError.
  ///
  /// In en, this message translates to:
  /// **'Error sending test notification'**
  String get testNotificationError;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @useExternalAudio.
  ///
  /// In en, this message translates to:
  /// **'Use external audio'**
  String get useExternalAudio;

  /// No description provided for @selectAudioFile.
  ///
  /// In en, this message translates to:
  /// **'Select audio file'**
  String get selectAudioFile;

  /// No description provided for @audioFileSelected.
  ///
  /// In en, this message translates to:
  /// **'Audio file selected'**
  String get audioFileSelected;

  /// No description provided for @removeAudio.
  ///
  /// In en, this message translates to:
  /// **'Remove audio'**
  String get removeAudio;

  /// No description provided for @noAudio.
  ///
  /// In en, this message translates to:
  /// **'No audio'**
  String get noAudio;

  /// No description provided for @externalAudio.
  ///
  /// In en, this message translates to:
  /// **'External audio'**
  String get externalAudio;

  /// No description provided for @originalAudio.
  ///
  /// In en, this message translates to:
  /// **'Original audio'**
  String get originalAudio;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
