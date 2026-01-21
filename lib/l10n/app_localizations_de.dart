// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Retro1';

  @override
  String get timeline => 'Zeitleiste';

  @override
  String get settings => 'Einstellungen';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get generateVideos => 'Videos Generieren';

  @override
  String get editTodayEntry => 'Eintrag von Heute Bearbeiten';

  @override
  String get recordToday => 'Heute Aufnehmen';

  @override
  String get view => 'Ansehen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get delete => 'Löschen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get yes => 'Ja';

  @override
  String get replace => 'Ersetzen';

  @override
  String get confirmDeletion => 'Löschung bestätigen';

  @override
  String get confirmDeletionMessage =>
      'Sind Sie sicher, dass Sie diesen Eintrag löschen möchten?';

  @override
  String get entryDeleted => 'Eintrag gelöscht';

  @override
  String get entrySaved => 'Eintrag erfolgreich gespeichert!';

  @override
  String addEntryFor(String date) {
    return 'Eintrag für $date hinzufügen';
  }

  @override
  String get captureOrImport =>
      'Möchten Sie Medien aufnehmen oder importieren?';

  @override
  String get recordVideo => 'Video Aufnehmen';

  @override
  String get takePhoto => 'Foto Aufnehmen';

  @override
  String get videoFromGallery => 'Video aus Galerie';

  @override
  String get photoFromGallery => 'Foto aus Galerie';

  @override
  String get chooseHowToRecord =>
      'Wählen Sie, wie Sie Ihren Moment aufnehmen möchten:';

  @override
  String get entryAlreadyExists => 'Eintrag existiert bereits';

  @override
  String get entryAlreadyExistsMessage =>
      'Ein Eintrag existiert bereits für diesen Tag. Möchten Sie ihn ersetzen?';

  @override
  String get editorChooseSecond => 'Editor - 1 Sekunde Wählen';

  @override
  String get playing => 'Wiedergabe...';

  @override
  String get preview1s => 'Vorschau 1s';

  @override
  String errorLoadingVideo(String error) {
    return 'Fehler beim Laden des Videos: $error';
  }

  @override
  String errorSaving(String error) {
    return 'Fehler beim Speichern: $error';
  }

  @override
  String get video => 'Video';

  @override
  String get photo => 'Foto';

  @override
  String get all => 'Alle';

  @override
  String get videosOnly => 'Nur Videos';

  @override
  String get photosOnly => 'Nur Fotos';

  @override
  String get noCaption => 'Keine Beschriftung';

  @override
  String get generateByPeriod => 'Nach Zeitraum Generieren';

  @override
  String get currentMonth => 'Aktueller Monat';

  @override
  String get currentYear => 'Aktuelles Jahr';

  @override
  String get selectMonth => 'Monat Auswählen';

  @override
  String get selectYear => 'Jahr Auswählen';

  @override
  String get year => 'Jahr';

  @override
  String get generate => 'Generieren';

  @override
  String get customRange => 'Benutzerdefinierter Bereich';

  @override
  String get chooseDates => 'Daten wählen';

  @override
  String get generatingVideo =>
      'Video wird generiert... Dies kann einige Minuten dauern.';

  @override
  String get videoGeneratedSuccess => 'Video erfolgreich generiert!';

  @override
  String get noEntriesForMonth => 'Keine Einträge für diesen Monat gefunden.';

  @override
  String get noEntriesForYear => 'Keine Einträge für dieses Jahr gefunden.';

  @override
  String get renderedVideo => 'Retro1 Gerendertes Video';

  @override
  String get renderedVideosHistory => 'Historie der Gerenderten Videos';

  @override
  String get noRenderedVideos => 'Noch keine gerenderten Videos';

  @override
  String get confirmDeleteRenderedVideo =>
      'Sind Sie sicher, dass Sie dieses gerenderte Video löschen möchten?';

  @override
  String get videoDeleted => 'Video gelöscht';

  @override
  String get videoFileNotFound => 'Videodatei nicht gefunden';

  @override
  String get fileNotFound => 'Datei nicht gefunden';

  @override
  String get calendar => 'Kalender';

  @override
  String get projects => 'Projekte';

  @override
  String get share => 'Teilen';

  @override
  String get newButton => 'Neu';

  @override
  String errorSharing(String error) {
    return 'Fehler beim Teilen: $error';
  }

  @override
  String get noVideoCaptured => 'Es wurde kein Video aufgenommen';

  @override
  String errorCapturingVideo(String error) {
    return 'Fehler beim Aufnehmen des Videos: $error';
  }

  @override
  String get noPhotoCaptured => 'Es wurde kein Foto aufgenommen';

  @override
  String errorCapturingPhoto(String error) {
    return 'Fehler beim Aufnehmen des Fotos: $error';
  }

  @override
  String get noVideoSelected => 'Es wurde kein Video ausgewählt';

  @override
  String errorSelectingVideo(String error) {
    return 'Fehler beim Auswählen des Videos: $error';
  }

  @override
  String get noPhotoSelected => 'Es wurde kein Foto ausgewählt';

  @override
  String errorSelectingPhoto(String error) {
    return 'Fehler beim Auswählen des Fotos: $error';
  }

  @override
  String errorProcessingMedia(String error) {
    return 'Fehler beim Verarbeiten der Medien: $error';
  }

  @override
  String get noEntriesFound => 'Keine Einträge für diesen Zeitraum gefunden.';

  @override
  String get noMediaFound => 'Keine Medien gefunden';

  @override
  String get noMediaFoundForDate =>
      'Keine Medien für das ausgewählte Datum gefunden';

  @override
  String get permissionDenied => 'Berechtigung verweigert';

  @override
  String errorLoadingMedia(String error) {
    return 'Fehler beim Laden der Medien: $error';
  }

  @override
  String errorSelectingMedia(String error) {
    return 'Fehler beim Auswählen der Medien: $error';
  }

  @override
  String get removeDateFilter => 'Datumsfilter entfernen';

  @override
  String errorGeneratingVideo(String error) {
    return 'Fehler beim Generieren des Videos: $error';
  }

  @override
  String get enableNotifications => 'Benachrichtigungen aktivieren';

  @override
  String get notificationTime => 'Benachrichtigungszeit';

  @override
  String get reminderAfter => 'Erinnerung nach (Stunden)';

  @override
  String get weeklySummary => 'Wöchentliche Zusammenfassung';

  @override
  String get videoQuality => 'Videoqualität';

  @override
  String get showDateInVideo => 'Datum im Video anzeigen';

  @override
  String get autoExportEndOfYear => 'Automatischer Export am Jahresende';

  @override
  String get autoBackup => 'Automatisches Backup';

  @override
  String get totalEntries => 'Gesamte Einträge';

  @override
  String get entriesThisYear => 'Einträge dieses Jahr';

  @override
  String get entries => 'Einträge';

  @override
  String get settingsSaved => 'Einstellungen gespeichert';

  @override
  String get quality720p => '720p';

  @override
  String get quality1080p => '1080p';

  @override
  String get quality4k => '4K';

  @override
  String get language => 'Sprache';

  @override
  String get languageEnglish => 'Englisch';

  @override
  String get languagePortuguese => 'Portugiesisch';

  @override
  String get appLanguage => 'App-Sprache';

  @override
  String get testNotification => 'Benachrichtigung testen';

  @override
  String get testNotificationDescription =>
      'Jetzt eine Testbenachrichtigung senden';

  @override
  String get testNotificationSent => 'Testbenachrichtigung gesendet!';

  @override
  String get testNotificationError =>
      'Fehler beim Senden der Testbenachrichtigung';

  @override
  String get today => 'Heute';

  @override
  String get useExternalAudio => 'Externes Audio verwenden';

  @override
  String get selectAudioFile => 'Audiodatei auswählen';

  @override
  String get audioFileSelected => 'Audiodatei ausgewählt';

  @override
  String get removeAudio => 'Audio entfernen';

  @override
  String get noAudio => 'Kein Audio';

  @override
  String get externalAudio => 'Externes Audio';

  @override
  String get originalAudio => 'Originales Audio';

  @override
  String get freeProjects => 'Freie Projekte';

  @override
  String get noProjectsYet => 'Noch keine Projekte';

  @override
  String get createFirstProject =>
      'Erstellen Sie Ihr erstes Projekt, um zu beginnen';

  @override
  String get newProject => 'Neues Projekt';

  @override
  String get projectName => 'Projektname';

  @override
  String get enterProjectName => 'Projektname eingeben';

  @override
  String get description => 'Beschreibung';

  @override
  String get descriptionOptional => 'Beschreibung (optional)';

  @override
  String get enterDescription => 'Beschreibung eingeben';

  @override
  String get create => 'Erstellen';

  @override
  String get deleteProject => 'Projekt Löschen';

  @override
  String deleteProjectConfirm(String name) {
    return 'Sind Sie sicher, dass Sie \"$name\" löschen möchten?';
  }

  @override
  String get items => 'Elemente';

  @override
  String get yesterday => 'Gestern';

  @override
  String daysAgo(int count) {
    return 'vor $count Tagen';
  }

  @override
  String get addMedia => 'Medien Hinzufügen';

  @override
  String get deleteItem => 'Element Löschen';

  @override
  String get deleteItemConfirm =>
      'Sind Sie sicher, dass Sie dieses Element löschen möchten?';

  @override
  String get noMediaItemsYet => 'Noch keine Medienelemente';

  @override
  String errorAddingMedia(String error) {
    return 'Fehler beim Hinzufügen von Medien: $error';
  }

  @override
  String get renderProjectVideo => 'Projektvideo Rendern';

  @override
  String renderProjectVideoConfirm(int count) {
    return 'Alle $count Elemente in ein Video rendern?';
  }

  @override
  String get render => 'Rendern';

  @override
  String get edited => 'Bearbeitet';

  @override
  String get original => 'Original';

  @override
  String get photoAdded => 'Foto Hinzugefügt';

  @override
  String get doYouWantToEdit => 'Möchten Sie das Foto jetzt bearbeiten?';

  @override
  String get skip => 'Überspringen';

  @override
  String get editPhoto => 'Foto Bearbeiten';

  @override
  String get editVideo => 'Video Bearbeiten';

  @override
  String get rotate => 'Drehen';

  @override
  String get filter => 'Filter';

  @override
  String get animation => 'Animation';

  @override
  String get speed => 'Geschwindigkeit: ';

  @override
  String get muteAudio => 'Audio Stummschalten';

  @override
  String get save => 'Speichern';

  @override
  String get editPhotoDaily => 'Foto Bearbeiten';

  @override
  String get convertToLandscape => 'Zu Querformat konvertieren';

  @override
  String get convertWithCrop => 'Mit Zuschnitt konvertieren';

  @override
  String get convertWithoutCrop => 'Ohne Zuschnitt konvertieren (Drehen)';

  @override
  String get imageAlreadyLandscape => 'Das Bild ist bereits im Querformat';

  @override
  String errorConvertingImage(String error) {
    return 'Fehler beim Konvertieren des Bildes: $error';
  }

  @override
  String get cropImage => 'Bild zuschneiden';

  @override
  String get record => 'Aufnehmen';

  @override
  String recordFor(String date) {
    return 'Aufnehmen - $date';
  }

  @override
  String get imageNotFound => 'Bild nicht gefunden';

  @override
  String get errorLoadingImage => 'Fehler beim Laden des Bildes';

  @override
  String errorRotatingImage(String error) {
    return 'Fehler beim Drehen des Bildes: $error';
  }

  @override
  String errorApplyingFilter(String error) {
    return 'Fehler beim Anwenden des Filters: $error';
  }

  @override
  String get editsSaved => 'Änderungen gespeichert';

  @override
  String startTime(int ms) {
    return 'Startzeit: ${ms}ms';
  }

  @override
  String errorSelectingAudio(String error) {
    return 'Fehler beim Auswählen des Audios: $error';
  }

  @override
  String get languageSpanish => 'Spanisch';

  @override
  String get languageFrench => 'Französisch';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageItalian => 'Italienisch';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get export => 'Export';

  @override
  String get backup => 'Backup';

  @override
  String get statistics => 'Statistiken';

  @override
  String get generateVideosDescription => 'Kompilierte Videos generieren';

  @override
  String get hours => 'Stunden';

  @override
  String get reminder => 'Erinnerung';

  @override
  String get reminderChannelDescription => 'Zusätzliche Erinnerungen';

  @override
  String get haventRecordedToday => 'Haben Sie heute noch nicht aufgenommen?';

  @override
  String get captureMomentNow => 'Wie wäre es, jetzt einen Moment einzufangen?';

  @override
  String get dailyReminder => 'Tägliche Erinnerung';

  @override
  String get dailyReminderDescription =>
      'Benachrichtigungen, um Sie daran zu erinnern, Ihren Moment des Tages aufzunehmen';

  @override
  String get notificationTitle => 'Retro1';

  @override
  String get notificationBody =>
      'Vergessen Sie nicht, Ihren Moment von heute aufzunehmen!';

  @override
  String get appearance => 'Erscheinungsbild';

  @override
  String get theme => 'Design';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeSystem => 'System';

  @override
  String get loadMoreDays => 'Mehr Tage Laden';

  @override
  String get mondayShort => 'Mo';

  @override
  String get tuesdayShort => 'Di';

  @override
  String get wednesdayShort => 'Mi';

  @override
  String get thursdayShort => 'Do';

  @override
  String get fridayShort => 'Fr';

  @override
  String get saturdayShort => 'Sa';

  @override
  String get sundayShort => 'So';
}
