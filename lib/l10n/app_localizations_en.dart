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
  String get preview1s => 'Preview (1s)';

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
  String get share => 'Share';

  @override
  String get newButton => 'New';

  @override
  String errorSharing(String error) {
    return 'Error sharing: $error';
  }

  @override
  String get noEntriesFound => 'No entries found for this period.';

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
}
