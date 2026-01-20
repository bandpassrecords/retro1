// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Retro1';

  @override
  String get timeline => 'Timeline';

  @override
  String get settings => 'Settings';

  @override
  String get generateVideos => 'Generate Videos';

  @override
  String get editTodayEntry => 'Edit Today\'s Entry';

  @override
  String get recordToday => 'Record Today';

  @override
  String get view => 'View';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get yes => 'Yes';

  @override
  String get replace => 'Replace';

  @override
  String get confirmDeletion => 'Confirm deletion';

  @override
  String get confirmDeletionMessage =>
      'Are you sure you want to delete this entry?';

  @override
  String get entryDeleted => 'Entry deleted';

  @override
  String get entrySaved => 'Entry saved successfully!';

  @override
  String addEntryFor(String date) {
    return 'Add entry for $date';
  }

  @override
  String get captureOrImport => 'Do you want to capture or import media?';

  @override
  String get recordVideo => 'Record Video';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get videoFromGallery => 'Video from Gallery';

  @override
  String get photoFromGallery => 'Photo from Gallery';

  @override
  String get chooseHowToRecord => 'Choose how you want to record your moment:';

  @override
  String get entryAlreadyExists => 'Entry already exists';

  @override
  String get entryAlreadyExistsMessage =>
      'An entry already exists for this day. Do you want to replace it?';

  @override
  String get editorChooseSecond => 'Editor - Choose 1 Second';

  @override
  String get playing => 'Playing...';

  @override
  String get preview1s => 'Preview 1s';

  @override
  String errorLoadingVideo(String error) {
    return 'Error loading video: $error';
  }

  @override
  String errorSaving(String error) {
    return 'Error saving: $error';
  }

  @override
  String get video => 'Video';

  @override
  String get photo => 'Photo';

  @override
  String get all => 'All';

  @override
  String get videosOnly => 'Videos Only';

  @override
  String get photosOnly => 'Photos Only';

  @override
  String get noCaption => 'No caption';

  @override
  String get generateByPeriod => 'Generate by Period';

  @override
  String get currentMonth => 'Current Month';

  @override
  String get currentYear => 'Current Year';

  @override
  String get customRange => 'Custom Range';

  @override
  String get chooseDates => 'Choose dates';

  @override
  String get generatingVideo =>
      'Generating video... This may take a few minutes.';

  @override
  String get videoGeneratedSuccess => 'Video generated successfully!';

  @override
  String get noEntriesForMonth => 'No entries found for this month.';

  @override
  String get noEntriesForYear => 'No entries found for this year.';

  @override
  String get renderedVideo => 'Retro1 Rendered Video';

  @override
  String get share => 'Share';

  @override
  String get newButton => 'New';

  @override
  String errorSharing(String error) {
    return 'Error sharing: $error';
  }

  @override
  String get noVideoCaptured => 'No video was captured';

  @override
  String errorCapturingVideo(String error) {
    return 'Error capturing video: $error';
  }

  @override
  String get noPhotoCaptured => 'No photo was captured';

  @override
  String errorCapturingPhoto(String error) {
    return 'Error capturing photo: $error';
  }

  @override
  String get noVideoSelected => 'No video was selected';

  @override
  String errorSelectingVideo(String error) {
    return 'Error selecting video: $error';
  }

  @override
  String get noPhotoSelected => 'No photo was selected';

  @override
  String errorSelectingPhoto(String error) {
    return 'Error selecting photo: $error';
  }

  @override
  String errorProcessingMedia(String error) {
    return 'Error processing media: $error';
  }

  @override
  String get noEntriesFound => 'No entries found for this period.';

  @override
  String get noMediaFound => 'No media found';

  @override
  String get noMediaFoundForDate => 'No media found for selected date';

  @override
  String get permissionDenied => 'Permission denied';

  @override
  String errorLoadingMedia(String error) {
    return 'Error loading media: $error';
  }

  @override
  String errorSelectingMedia(String error) {
    return 'Error selecting media: $error';
  }

  @override
  String get removeDateFilter => 'Remove date filter';

  @override
  String errorGeneratingVideo(String error) {
    return 'Error generating video: $error';
  }

  @override
  String get enableNotifications => 'Enable notifications';

  @override
  String get notificationTime => 'Notification time';

  @override
  String get reminderAfter => 'Reminder after (hours)';

  @override
  String get weeklySummary => 'Weekly summary';

  @override
  String get videoQuality => 'Video quality';

  @override
  String get showDateInVideo => 'Show date in video';

  @override
  String get autoExportEndOfYear => 'Auto export at end of year';

  @override
  String get autoBackup => 'Auto backup';

  @override
  String get totalEntries => 'Total entries';

  @override
  String get entriesThisYear => 'Entries this year';

  @override
  String get entries => 'entries';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get quality720p => '720p';

  @override
  String get quality1080p => '1080p';

  @override
  String get quality4k => '4K';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePortuguese => 'Portuguese';

  @override
  String get appLanguage => 'App language';

  @override
  String get testNotification => 'Test notification';

  @override
  String get testNotificationDescription => 'Send a test notification now';

  @override
  String get testNotificationSent => 'Test notification sent!';

  @override
  String get testNotificationError => 'Error sending test notification';

  @override
  String get today => 'Today';

  @override
  String get useExternalAudio => 'Use external audio';

  @override
  String get selectAudioFile => 'Select audio file';

  @override
  String get audioFileSelected => 'Audio file selected';

  @override
  String get removeAudio => 'Remove audio';

  @override
  String get noAudio => 'No audio';

  @override
  String get externalAudio => 'External audio';

  @override
  String get originalAudio => 'Original audio';

  @override
  String get projects => 'Projects';

  @override
  String get freeProjects => 'Free Projects';

  @override
  String get noProjectsYet => 'No projects yet';

  @override
  String get createFirstProject => 'Create your first project to get started';

  @override
  String get newProject => 'New Project';

  @override
  String get projectName => 'Project Name';

  @override
  String get enterProjectName => 'Enter project name';

  @override
  String get description => 'Description';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get enterDescription => 'Enter description';

  @override
  String get create => 'Create';

  @override
  String get deleteProject => 'Delete Project';

  @override
  String deleteProjectConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get items => 'items';

  @override
  String get yesterday => 'Yesterday';

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get addMedia => 'Add Media';

  @override
  String get deleteItem => 'Delete Item';

  @override
  String get deleteItemConfirm => 'Are you sure you want to delete this item?';

  @override
  String get noMediaItemsYet => 'No media items yet';

  @override
  String errorAddingMedia(String error) {
    return 'Error adding media: $error';
  }

  @override
  String get renderProjectVideo => 'Render Project Video';

  @override
  String renderProjectVideoConfirm(int count) {
    return 'Render all $count items into a video?';
  }

  @override
  String get render => 'Render';

  @override
  String get edited => 'Edited';

  @override
  String get original => 'Original';

  @override
  String get photoAdded => 'Photo Added';

  @override
  String get doYouWantToEdit => 'Do you want to edit the photo now?';

  @override
  String get skip => 'Skip';

  @override
  String get editPhoto => 'Edit Photo';

  @override
  String get editVideo => 'Edit Video';

  @override
  String get rotate => 'Rotate';

  @override
  String get filter => 'Filter';

  @override
  String get animation => 'Animation';

  @override
  String get speed => 'Speed: ';

  @override
  String get muteAudio => 'Mute Audio';

  @override
  String get save => 'Save';

  @override
  String get editPhotoDaily => 'Edit Photo';

  @override
  String get convertToLandscape => 'Convert to Landscape';

  @override
  String get convertWithCrop => 'Convert with Crop';

  @override
  String get convertWithoutCrop => 'Convert without Crop (Rotate)';

  @override
  String get imageAlreadyLandscape =>
      'Image is already in landscape orientation';

  @override
  String errorConvertingImage(String error) {
    return 'Error converting image: $error';
  }

  @override
  String get cropImage => 'Crop Image';

  @override
  String get record => 'Record';

  @override
  String recordFor(String date) {
    return 'Record - $date';
  }

  @override
  String get imageNotFound => 'Image not found';

  @override
  String get errorLoadingImage => 'Error loading image';

  @override
  String errorRotatingImage(String error) {
    return 'Error rotating image: $error';
  }

  @override
  String errorApplyingFilter(String error) {
    return 'Error applying filter: $error';
  }

  @override
  String get editsSaved => 'Edits saved';

  @override
  String startTime(int ms) {
    return 'Start Time: ${ms}ms';
  }

  @override
  String errorSelectingAudio(String error) {
    return 'Error selecting audio: $error';
  }

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get languageFrench => 'French';

  @override
  String get languageGerman => 'German';

  @override
  String get languageItalian => 'Italian';

  @override
  String get notifications => 'Notifications';

  @override
  String get export => 'Export';

  @override
  String get backup => 'Backup';

  @override
  String get statistics => 'Statistics';

  @override
  String get generateVideosDescription => 'Generate compiled videos';

  @override
  String get hours => 'hours';

  @override
  String get reminder => 'Reminder';

  @override
  String get reminderChannelDescription => 'Additional reminders';

  @override
  String get haventRecordedToday => 'Haven\'t recorded today?';

  @override
  String get captureMomentNow => 'How about capturing a moment now?';

  @override
  String get dailyReminder => 'Daily Reminder';

  @override
  String get dailyReminderDescription =>
      'Notifications to remind you to record your moment of the day';

  @override
  String get notificationTitle => 'Retro1';

  @override
  String get notificationBody => 'Don\'t forget to record your moment today!';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get loadMoreDays => 'Load More Days';

  @override
  String get mondayShort => 'Mon';

  @override
  String get tuesdayShort => 'Tue';

  @override
  String get wednesdayShort => 'Wed';

  @override
  String get thursdayShort => 'Thu';

  @override
  String get fridayShort => 'Fri';

  @override
  String get saturdayShort => 'Sat';

  @override
  String get sundayShort => 'Sun';
}
