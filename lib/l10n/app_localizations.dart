import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
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

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

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
  /// **'Preview 1s'**
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

  /// No description provided for @selectMonth.
  ///
  /// In en, this message translates to:
  /// **'Select Month'**
  String get selectMonth;

  /// No description provided for @selectYear.
  ///
  /// In en, this message translates to:
  /// **'Select Year'**
  String get selectYear;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

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

  /// No description provided for @noEntriesForMonth.
  ///
  /// In en, this message translates to:
  /// **'No entries found for this month.'**
  String get noEntriesForMonth;

  /// No description provided for @noEntriesForYear.
  ///
  /// In en, this message translates to:
  /// **'No entries found for this year.'**
  String get noEntriesForYear;

  /// No description provided for @renderedVideo.
  ///
  /// In en, this message translates to:
  /// **'Retro1 Rendered Video'**
  String get renderedVideo;

  /// No description provided for @renderedVideosHistory.
  ///
  /// In en, this message translates to:
  /// **'Rendered Videos History'**
  String get renderedVideosHistory;

  /// No description provided for @noRenderedVideos.
  ///
  /// In en, this message translates to:
  /// **'No rendered videos yet'**
  String get noRenderedVideos;

  /// No description provided for @confirmDeleteRenderedVideo.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this rendered video?'**
  String get confirmDeleteRenderedVideo;

  /// No description provided for @videoDeleted.
  ///
  /// In en, this message translates to:
  /// **'Video deleted'**
  String get videoDeleted;

  /// No description provided for @videoFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Video file not found'**
  String get videoFileNotFound;

  /// No description provided for @fileNotFound.
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get fileNotFound;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

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

  /// No description provided for @noVideoCaptured.
  ///
  /// In en, this message translates to:
  /// **'No video was captured'**
  String get noVideoCaptured;

  /// No description provided for @errorCapturingVideo.
  ///
  /// In en, this message translates to:
  /// **'Error capturing video: {error}'**
  String errorCapturingVideo(String error);

  /// No description provided for @noPhotoCaptured.
  ///
  /// In en, this message translates to:
  /// **'No photo was captured'**
  String get noPhotoCaptured;

  /// No description provided for @errorCapturingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Error capturing photo: {error}'**
  String errorCapturingPhoto(String error);

  /// No description provided for @noVideoSelected.
  ///
  /// In en, this message translates to:
  /// **'No video was selected'**
  String get noVideoSelected;

  /// No description provided for @errorSelectingVideo.
  ///
  /// In en, this message translates to:
  /// **'Error selecting video: {error}'**
  String errorSelectingVideo(String error);

  /// No description provided for @noPhotoSelected.
  ///
  /// In en, this message translates to:
  /// **'No photo was selected'**
  String get noPhotoSelected;

  /// No description provided for @errorSelectingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Error selecting photo: {error}'**
  String errorSelectingPhoto(String error);

  /// No description provided for @errorProcessingMedia.
  ///
  /// In en, this message translates to:
  /// **'Error processing media: {error}'**
  String errorProcessingMedia(String error);

  /// No description provided for @noEntriesFound.
  ///
  /// In en, this message translates to:
  /// **'No entries found for this period.'**
  String get noEntriesFound;

  /// No description provided for @noMediaFound.
  ///
  /// In en, this message translates to:
  /// **'No media found'**
  String get noMediaFound;

  /// No description provided for @noMediaFoundForDate.
  ///
  /// In en, this message translates to:
  /// **'No media found for selected date'**
  String get noMediaFoundForDate;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;

  /// No description provided for @errorLoadingMedia.
  ///
  /// In en, this message translates to:
  /// **'Error loading media: {error}'**
  String errorLoadingMedia(String error);

  /// No description provided for @errorSelectingMedia.
  ///
  /// In en, this message translates to:
  /// **'Error selecting media: {error}'**
  String errorSelectingMedia(String error);

  /// No description provided for @removeDateFilter.
  ///
  /// In en, this message translates to:
  /// **'Remove date filter'**
  String get removeDateFilter;

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

  /// No description provided for @freeProjects.
  ///
  /// In en, this message translates to:
  /// **'Free Projects'**
  String get freeProjects;

  /// No description provided for @noProjectsYet.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get noProjectsYet;

  /// No description provided for @createFirstProject.
  ///
  /// In en, this message translates to:
  /// **'Create your first project to get started'**
  String get createFirstProject;

  /// No description provided for @newProject.
  ///
  /// In en, this message translates to:
  /// **'New Project'**
  String get newProject;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get projectName;

  /// No description provided for @enterProjectName.
  ///
  /// In en, this message translates to:
  /// **'Enter project name'**
  String get enterProjectName;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @enterDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter description'**
  String get enterDescription;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @deleteProject.
  ///
  /// In en, this message translates to:
  /// **'Delete Project'**
  String get deleteProject;

  /// No description provided for @deleteProjectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteProjectConfirm(String name);

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get items;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @addMedia.
  ///
  /// In en, this message translates to:
  /// **'Add Media'**
  String get addMedia;

  /// No description provided for @deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete Item'**
  String get deleteItem;

  /// No description provided for @deleteItemConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get deleteItemConfirm;

  /// No description provided for @noMediaItemsYet.
  ///
  /// In en, this message translates to:
  /// **'No media items yet'**
  String get noMediaItemsYet;

  /// No description provided for @errorAddingMedia.
  ///
  /// In en, this message translates to:
  /// **'Error adding media: {error}'**
  String errorAddingMedia(String error);

  /// No description provided for @renderProjectVideo.
  ///
  /// In en, this message translates to:
  /// **'Render Project Video'**
  String get renderProjectVideo;

  /// No description provided for @renderProjectVideoConfirm.
  ///
  /// In en, this message translates to:
  /// **'Render all {count} items into a video?'**
  String renderProjectVideoConfirm(int count);

  /// No description provided for @render.
  ///
  /// In en, this message translates to:
  /// **'Render'**
  String get render;

  /// No description provided for @edited.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get edited;

  /// No description provided for @original.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get original;

  /// No description provided for @photoAdded.
  ///
  /// In en, this message translates to:
  /// **'Photo Added'**
  String get photoAdded;

  /// No description provided for @doYouWantToEdit.
  ///
  /// In en, this message translates to:
  /// **'Do you want to edit the photo now?'**
  String get doYouWantToEdit;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @editPhoto.
  ///
  /// In en, this message translates to:
  /// **'Edit Photo'**
  String get editPhoto;

  /// No description provided for @editVideo.
  ///
  /// In en, this message translates to:
  /// **'Edit Video'**
  String get editVideo;

  /// No description provided for @rotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get rotate;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @animation.
  ///
  /// In en, this message translates to:
  /// **'Animation'**
  String get animation;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed: '**
  String get speed;

  /// No description provided for @muteAudio.
  ///
  /// In en, this message translates to:
  /// **'Mute Audio'**
  String get muteAudio;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @editPhotoDaily.
  ///
  /// In en, this message translates to:
  /// **'Edit Photo'**
  String get editPhotoDaily;

  /// No description provided for @convertToLandscape.
  ///
  /// In en, this message translates to:
  /// **'Convert to Landscape'**
  String get convertToLandscape;

  /// No description provided for @convertWithCrop.
  ///
  /// In en, this message translates to:
  /// **'Convert with Crop'**
  String get convertWithCrop;

  /// No description provided for @convertWithoutCrop.
  ///
  /// In en, this message translates to:
  /// **'Convert without Crop (Rotate)'**
  String get convertWithoutCrop;

  /// No description provided for @imageAlreadyLandscape.
  ///
  /// In en, this message translates to:
  /// **'Image is already in landscape orientation'**
  String get imageAlreadyLandscape;

  /// No description provided for @errorConvertingImage.
  ///
  /// In en, this message translates to:
  /// **'Error converting image: {error}'**
  String errorConvertingImage(String error);

  /// No description provided for @cropImage.
  ///
  /// In en, this message translates to:
  /// **'Crop Image'**
  String get cropImage;

  /// No description provided for @record.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get record;

  /// No description provided for @recordFor.
  ///
  /// In en, this message translates to:
  /// **'Record - {date}'**
  String recordFor(String date);

  /// No description provided for @imageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Image not found'**
  String get imageNotFound;

  /// No description provided for @errorLoadingImage.
  ///
  /// In en, this message translates to:
  /// **'Error loading image'**
  String get errorLoadingImage;

  /// No description provided for @errorRotatingImage.
  ///
  /// In en, this message translates to:
  /// **'Error rotating image: {error}'**
  String errorRotatingImage(String error);

  /// No description provided for @errorApplyingFilter.
  ///
  /// In en, this message translates to:
  /// **'Error applying filter: {error}'**
  String errorApplyingFilter(String error);

  /// No description provided for @editsSaved.
  ///
  /// In en, this message translates to:
  /// **'Edits saved'**
  String get editsSaved;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time: {ms}ms'**
  String startTime(int ms);

  /// No description provided for @errorSelectingAudio.
  ///
  /// In en, this message translates to:
  /// **'Error selecting audio: {error}'**
  String errorSelectingAudio(String error);

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get languageSpanish;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get languageFrench;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get languageGerman;

  /// No description provided for @languageItalian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get languageItalian;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @generateVideosDescription.
  ///
  /// In en, this message translates to:
  /// **'Generate compiled videos'**
  String get generateVideosDescription;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @reminderChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Additional reminders'**
  String get reminderChannelDescription;

  /// No description provided for @haventRecordedToday.
  ///
  /// In en, this message translates to:
  /// **'Haven\'t recorded today?'**
  String get haventRecordedToday;

  /// No description provided for @captureMomentNow.
  ///
  /// In en, this message translates to:
  /// **'How about capturing a moment now?'**
  String get captureMomentNow;

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get dailyReminder;

  /// No description provided for @dailyReminderDescription.
  ///
  /// In en, this message translates to:
  /// **'Notifications to remind you to record your moment of the day'**
  String get dailyReminderDescription;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Retro1'**
  String get notificationTitle;

  /// No description provided for @notificationBody.
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget to record your moment today!'**
  String get notificationBody;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @loadMoreDays.
  ///
  /// In en, this message translates to:
  /// **'Load More Days'**
  String get loadMoreDays;

  /// No description provided for @mondayShort.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mondayShort;

  /// No description provided for @tuesdayShort.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tuesdayShort;

  /// No description provided for @wednesdayShort.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wednesdayShort;

  /// No description provided for @thursdayShort.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thursdayShort;

  /// No description provided for @fridayShort.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fridayShort;

  /// No description provided for @saturdayShort.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get saturdayShort;

  /// No description provided for @sundayShort.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sundayShort;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fr',
        'it',
        'pt'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
