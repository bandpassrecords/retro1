// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Retro1';

  @override
  String get timeline => 'Cronologia';

  @override
  String get settings => 'Impostazioni';

  @override
  String get generateVideos => 'Genera Video';

  @override
  String get editTodayEntry => 'Modifica Voce di Oggi';

  @override
  String get recordToday => 'Registra Oggi';

  @override
  String get view => 'Visualizza';

  @override
  String get edit => 'Modifica';

  @override
  String get delete => 'Elimina';

  @override
  String get cancel => 'Annulla';

  @override
  String get yes => 'Sì';

  @override
  String get replace => 'Sostituisci';

  @override
  String get confirmDeletion => 'Conferma eliminazione';

  @override
  String get confirmDeletionMessage =>
      'Sei sicuro di voler eliminare questa voce?';

  @override
  String get entryDeleted => 'Voce eliminata';

  @override
  String get entrySaved => 'Voce salvata con successo!';

  @override
  String addEntryFor(String date) {
    return 'Aggiungi voce per $date';
  }

  @override
  String get captureOrImport => 'Vuoi catturare o importare media?';

  @override
  String get recordVideo => 'Registra Video';

  @override
  String get takePhoto => 'Scatta Foto';

  @override
  String get videoFromGallery => 'Video dalla Galleria';

  @override
  String get photoFromGallery => 'Foto dalla Galleria';

  @override
  String get chooseHowToRecord => 'Scegli come vuoi registrare il tuo momento:';

  @override
  String get entryAlreadyExists => 'Voce già esistente';

  @override
  String get entryAlreadyExistsMessage =>
      'Esiste già una voce per questo giorno. Vuoi sostituirla?';

  @override
  String get editorChooseSecond => 'Editor - Scegli 1 Secondo';

  @override
  String get playing => 'Riproduzione...';

  @override
  String get preview1s => 'Anteprima 1s';

  @override
  String errorLoadingVideo(String error) {
    return 'Errore nel caricamento del video: $error';
  }

  @override
  String errorSaving(String error) {
    return 'Errore nel salvataggio: $error';
  }

  @override
  String get video => 'Video';

  @override
  String get photo => 'Foto';

  @override
  String get all => 'Tutti';

  @override
  String get videosOnly => 'Solo Video';

  @override
  String get photosOnly => 'Solo Foto';

  @override
  String get noCaption => 'Nessuna didascalia';

  @override
  String get generateByPeriod => 'Genera per Periodo';

  @override
  String get currentMonth => 'Mese Corrente';

  @override
  String get currentYear => 'Anno Corrente';

  @override
  String get selectMonth => 'Seleziona Mese';

  @override
  String get selectYear => 'Seleziona Anno';

  @override
  String get year => 'Anno';

  @override
  String get generate => 'Genera';

  @override
  String get customRange => 'Intervallo Personalizzato';

  @override
  String get chooseDates => 'Scegli le date';

  @override
  String get generatingVideo =>
      'Generazione del video... Questo potrebbe richiedere alcuni minuti.';

  @override
  String get videoGeneratedSuccess => 'Video generato con successo!';

  @override
  String get noEntriesForMonth => 'Nessuna voce trovata per questo mese.';

  @override
  String get noEntriesForYear => 'Nessuna voce trovata per questo anno.';

  @override
  String get renderedVideo => 'Video Renderizzato Retro1';

  @override
  String get renderedVideosHistory => 'Cronologia Video Renderizzati';

  @override
  String get noRenderedVideos => 'Nessun video renderizzato ancora';

  @override
  String get confirmDeleteRenderedVideo =>
      'Sei sicuro di voler eliminare questo video renderizzato?';

  @override
  String get videoDeleted => 'Video eliminato';

  @override
  String get videoFileNotFound => 'File video non trovato';

  @override
  String get fileNotFound => 'File non trovato';

  @override
  String get calendar => 'Calendario';

  @override
  String get projects => 'Progetti';

  @override
  String get share => 'Condividi';

  @override
  String get newButton => 'Nuovo';

  @override
  String errorSharing(String error) {
    return 'Errore nella condivisione: $error';
  }

  @override
  String get noVideoCaptured => 'Nessun video è stato catturato';

  @override
  String errorCapturingVideo(String error) {
    return 'Errore durante la cattura del video: $error';
  }

  @override
  String get noPhotoCaptured => 'Nessuna foto è stata catturata';

  @override
  String errorCapturingPhoto(String error) {
    return 'Errore durante la cattura della foto: $error';
  }

  @override
  String get noVideoSelected => 'Nessun video è stato selezionato';

  @override
  String errorSelectingVideo(String error) {
    return 'Errore durante la selezione del video: $error';
  }

  @override
  String get noPhotoSelected => 'Nessuna foto è stata selezionata';

  @override
  String errorSelectingPhoto(String error) {
    return 'Errore durante la selezione della foto: $error';
  }

  @override
  String errorProcessingMedia(String error) {
    return 'Errore durante l\'elaborazione dei media: $error';
  }

  @override
  String get noEntriesFound => 'Nessuna voce trovata per questo periodo.';

  @override
  String get noMediaFound => 'Nessun media trovato';

  @override
  String get noMediaFoundForDate =>
      'Nessun media trovato per la data selezionata';

  @override
  String get permissionDenied => 'Permesso negato';

  @override
  String errorLoadingMedia(String error) {
    return 'Errore durante il caricamento dei media: $error';
  }

  @override
  String errorSelectingMedia(String error) {
    return 'Errore durante la selezione dei media: $error';
  }

  @override
  String get removeDateFilter => 'Rimuovi filtro data';

  @override
  String errorGeneratingVideo(String error) {
    return 'Errore nella generazione del video: $error';
  }

  @override
  String get enableNotifications => 'Abilita notifiche';

  @override
  String get notificationTime => 'Ora della notifica';

  @override
  String get reminderAfter => 'Promemoria dopo (ore)';

  @override
  String get weeklySummary => 'Riepilogo settimanale';

  @override
  String get videoQuality => 'Qualità video';

  @override
  String get showDateInVideo => 'Mostra data nel video';

  @override
  String get autoExportEndOfYear => 'Esportazione automatica a fine anno';

  @override
  String get autoBackup => 'Backup automatico';

  @override
  String get totalEntries => 'Totale voci';

  @override
  String get entriesThisYear => 'Voci di quest\'anno';

  @override
  String get entries => 'voci';

  @override
  String get settingsSaved => 'Impostazioni salvate';

  @override
  String get quality720p => '720p';

  @override
  String get quality1080p => '1080p';

  @override
  String get quality4k => '4K';

  @override
  String get language => 'Lingua';

  @override
  String get languageEnglish => 'Inglese';

  @override
  String get languagePortuguese => 'Portoghese';

  @override
  String get appLanguage => 'Lingua dell\'app';

  @override
  String get testNotification => 'Testa notifica';

  @override
  String get testNotificationDescription => 'Invia una notifica di test ora';

  @override
  String get testNotificationSent => 'Notifica di test inviata!';

  @override
  String get testNotificationError =>
      'Errore nell\'invio della notifica di test';

  @override
  String get today => 'Oggi';

  @override
  String get useExternalAudio => 'Usa audio esterno';

  @override
  String get selectAudioFile => 'Seleziona file audio';

  @override
  String get audioFileSelected => 'File audio selezionato';

  @override
  String get removeAudio => 'Rimuovi audio';

  @override
  String get noAudio => 'Nessun audio';

  @override
  String get externalAudio => 'Audio esterno';

  @override
  String get originalAudio => 'Audio originale';

  @override
  String get freeProjects => 'Progetti Liberi';

  @override
  String get noProjectsYet => 'Nessun progetto ancora';

  @override
  String get createFirstProject => 'Crea il tuo primo progetto per iniziare';

  @override
  String get newProject => 'Nuovo Progetto';

  @override
  String get projectName => 'Nome del Progetto';

  @override
  String get enterProjectName => 'Inserisci il nome del progetto';

  @override
  String get description => 'Descrizione';

  @override
  String get descriptionOptional => 'Descrizione (opzionale)';

  @override
  String get enterDescription => 'Inserisci la descrizione';

  @override
  String get create => 'Crea';

  @override
  String get deleteProject => 'Elimina Progetto';

  @override
  String deleteProjectConfirm(String name) {
    return 'Sei sicuro di voler eliminare \"$name\"?';
  }

  @override
  String get items => 'elementi';

  @override
  String get yesterday => 'Ieri';

  @override
  String daysAgo(int count) {
    return '$count giorni fa';
  }

  @override
  String get addMedia => 'Aggiungi Media';

  @override
  String get deleteItem => 'Elimina Elemento';

  @override
  String get deleteItemConfirm =>
      'Sei sicuro di voler eliminare questo elemento?';

  @override
  String get noMediaItemsYet => 'Nessun elemento multimediale ancora';

  @override
  String errorAddingMedia(String error) {
    return 'Errore nell\'aggiunta di media: $error';
  }

  @override
  String get renderProjectVideo => 'Renderizza Video del Progetto';

  @override
  String renderProjectVideoConfirm(int count) {
    return 'Renderizzare tutti i $count elementi in un video?';
  }

  @override
  String get render => 'Renderizza';

  @override
  String get edited => 'Modificato';

  @override
  String get original => 'Originale';

  @override
  String get photoAdded => 'Foto Aggiunta';

  @override
  String get doYouWantToEdit => 'Vuoi modificare la foto ora?';

  @override
  String get skip => 'Salta';

  @override
  String get editPhoto => 'Modifica Foto';

  @override
  String get editVideo => 'Modifica Video';

  @override
  String get rotate => 'Ruota';

  @override
  String get filter => 'Filtro';

  @override
  String get animation => 'Animazione';

  @override
  String get speed => 'Velocità: ';

  @override
  String get muteAudio => 'Disattiva Audio';

  @override
  String get save => 'Salva';

  @override
  String get editPhotoDaily => 'Modifica Foto';

  @override
  String get convertToLandscape => 'Converti in Orizzontale';

  @override
  String get convertWithCrop => 'Converti con Ritaglio';

  @override
  String get convertWithoutCrop => 'Converti senza Ritaglio (Ruota)';

  @override
  String get imageAlreadyLandscape =>
      'L\'immagine è già in orientamento orizzontale';

  @override
  String errorConvertingImage(String error) {
    return 'Errore durante la conversione dell\'immagine: $error';
  }

  @override
  String get cropImage => 'Ritaglia Immagine';

  @override
  String get record => 'Registra';

  @override
  String recordFor(String date) {
    return 'Registra - $date';
  }

  @override
  String get imageNotFound => 'Immagine non trovata';

  @override
  String get errorLoadingImage => 'Errore nel caricamento dell\'immagine';

  @override
  String errorRotatingImage(String error) {
    return 'Errore nella rotazione dell\'immagine: $error';
  }

  @override
  String errorApplyingFilter(String error) {
    return 'Errore nell\'applicazione del filtro: $error';
  }

  @override
  String get editsSaved => 'Modifiche salvate';

  @override
  String startTime(int ms) {
    return 'Tempo di inizio: ${ms}ms';
  }

  @override
  String errorSelectingAudio(String error) {
    return 'Errore nella selezione dell\'audio: $error';
  }

  @override
  String get languageSpanish => 'Spagnolo';

  @override
  String get languageFrench => 'Francese';

  @override
  String get languageGerman => 'Tedesco';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get notifications => 'Notifiche';

  @override
  String get export => 'Esportazione';

  @override
  String get backup => 'Backup';

  @override
  String get statistics => 'Statistiche';

  @override
  String get generateVideosDescription => 'Genera video compilati';

  @override
  String get hours => 'ore';

  @override
  String get reminder => 'Promemoria';

  @override
  String get reminderChannelDescription => 'Promemoria aggiuntivi';

  @override
  String get haventRecordedToday => 'Non hai ancora registrato oggi?';

  @override
  String get captureMomentNow => 'Che ne dici di catturare un momento ora?';

  @override
  String get dailyReminder => 'Promemoria Giornaliero';

  @override
  String get dailyReminderDescription =>
      'Notifiche per ricordarti di registrare il tuo momento della giornata';

  @override
  String get notificationTitle => 'Retro1';

  @override
  String get notificationBody =>
      'Non dimenticare di registrare il tuo momento di oggi!';

  @override
  String get appearance => 'Aspetto';

  @override
  String get theme => 'Tema';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get loadMoreDays => 'Carica Più Giorni';

  @override
  String get mondayShort => 'Lun';

  @override
  String get tuesdayShort => 'Mar';

  @override
  String get wednesdayShort => 'Mer';

  @override
  String get thursdayShort => 'Gio';

  @override
  String get fridayShort => 'Ven';

  @override
  String get saturdayShort => 'Sab';

  @override
  String get sundayShort => 'Dom';
}
