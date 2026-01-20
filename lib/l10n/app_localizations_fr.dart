// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Retro1';

  @override
  String get timeline => 'Chronologie';

  @override
  String get settings => 'Paramètres';

  @override
  String get generateVideos => 'Générer des Vidéos';

  @override
  String get editTodayEntry => 'Modifier l\'Entrée d\'Aujourd\'hui';

  @override
  String get recordToday => 'Enregistrer Aujourd\'hui';

  @override
  String get view => 'Voir';

  @override
  String get edit => 'Modifier';

  @override
  String get delete => 'Supprimer';

  @override
  String get cancel => 'Annuler';

  @override
  String get yes => 'Oui';

  @override
  String get replace => 'Remplacer';

  @override
  String get confirmDeletion => 'Confirmer la suppression';

  @override
  String get confirmDeletionMessage =>
      'Êtes-vous sûr de vouloir supprimer cette entrée?';

  @override
  String get entryDeleted => 'Entrée supprimée';

  @override
  String get entrySaved => 'Entrée enregistrée avec succès!';

  @override
  String addEntryFor(String date) {
    return 'Ajouter une entrée pour $date';
  }

  @override
  String get captureOrImport => 'Voulez-vous capturer ou importer des médias?';

  @override
  String get recordVideo => 'Enregistrer une Vidéo';

  @override
  String get takePhoto => 'Prendre une Photo';

  @override
  String get videoFromGallery => 'Vidéo de la Galerie';

  @override
  String get photoFromGallery => 'Photo de la Galerie';

  @override
  String get chooseHowToRecord =>
      'Choisissez comment vous voulez enregistrer votre moment:';

  @override
  String get entryAlreadyExists => 'Une entrée existe déjà';

  @override
  String get entryAlreadyExistsMessage =>
      'Une entrée existe déjà pour ce jour. Voulez-vous la remplacer?';

  @override
  String get editorChooseSecond => 'Éditeur - Choisir 1 Seconde';

  @override
  String get playing => 'Lecture...';

  @override
  String get preview1s => 'Aperçu 1s';

  @override
  String errorLoadingVideo(String error) {
    return 'Erreur lors du chargement de la vidéo: $error';
  }

  @override
  String errorSaving(String error) {
    return 'Erreur lors de l\'enregistrement: $error';
  }

  @override
  String get video => 'Vidéo';

  @override
  String get photo => 'Photo';

  @override
  String get all => 'Tous';

  @override
  String get videosOnly => 'Vidéos Seulement';

  @override
  String get photosOnly => 'Photos Seulement';

  @override
  String get noCaption => 'Sans légende';

  @override
  String get generateByPeriod => 'Générer par Période';

  @override
  String get currentMonth => 'Mois Actuel';

  @override
  String get currentYear => 'Année Actuelle';

  @override
  String get customRange => 'Plage Personnalisée';

  @override
  String get chooseDates => 'Choisir les dates';

  @override
  String get generatingVideo =>
      'Génération de la vidéo... Cela peut prendre quelques minutes.';

  @override
  String get videoGeneratedSuccess => 'Vidéo générée avec succès!';

  @override
  String get noEntriesForMonth => 'Aucune entrée trouvée pour ce mois.';

  @override
  String get noEntriesForYear => 'Aucune entrée trouvée pour cette année.';

  @override
  String get renderedVideo => 'Vidéo Rendu Retro1';

  @override
  String get share => 'Partager';

  @override
  String get newButton => 'Nouveau';

  @override
  String errorSharing(String error) {
    return 'Erreur lors du partage: $error';
  }

  @override
  String get noVideoCaptured => 'Aucune vidéo n\'a été capturée';

  @override
  String errorCapturingVideo(String error) {
    return 'Erreur lors de la capture de la vidéo: $error';
  }

  @override
  String get noPhotoCaptured => 'Aucune photo n\'a été capturée';

  @override
  String errorCapturingPhoto(String error) {
    return 'Erreur lors de la capture de la photo: $error';
  }

  @override
  String get noVideoSelected => 'Aucune vidéo n\'a été sélectionnée';

  @override
  String errorSelectingVideo(String error) {
    return 'Erreur lors de la sélection de la vidéo: $error';
  }

  @override
  String get noPhotoSelected => 'Aucune photo n\'a été sélectionnée';

  @override
  String errorSelectingPhoto(String error) {
    return 'Erreur lors de la sélection de la photo: $error';
  }

  @override
  String errorProcessingMedia(String error) {
    return 'Erreur lors du traitement des médias: $error';
  }

  @override
  String get noEntriesFound => 'Aucune entrée trouvée pour cette période.';

  @override
  String get noMediaFound => 'Aucun média trouvé';

  @override
  String get noMediaFoundForDate =>
      'Aucun média trouvé pour la date sélectionnée';

  @override
  String get permissionDenied => 'Permission refusée';

  @override
  String errorLoadingMedia(String error) {
    return 'Erreur lors du chargement des médias: $error';
  }

  @override
  String errorSelectingMedia(String error) {
    return 'Erreur lors de la sélection des médias: $error';
  }

  @override
  String get removeDateFilter => 'Retirer le filtre de date';

  @override
  String errorGeneratingVideo(String error) {
    return 'Erreur lors de la génération de la vidéo: $error';
  }

  @override
  String get enableNotifications => 'Activer les notifications';

  @override
  String get notificationTime => 'Heure de notification';

  @override
  String get reminderAfter => 'Rappel après (heures)';

  @override
  String get weeklySummary => 'Résumé hebdomadaire';

  @override
  String get videoQuality => 'Qualité vidéo';

  @override
  String get showDateInVideo => 'Afficher la date dans la vidéo';

  @override
  String get autoExportEndOfYear => 'Exportation automatique en fin d\'année';

  @override
  String get autoBackup => 'Sauvegarde automatique';

  @override
  String get totalEntries => 'Total des entrées';

  @override
  String get entriesThisYear => 'Entrées cette année';

  @override
  String get entries => 'entrées';

  @override
  String get settingsSaved => 'Paramètres enregistrés';

  @override
  String get quality720p => '720p';

  @override
  String get quality1080p => '1080p';

  @override
  String get quality4k => '4K';

  @override
  String get language => 'Langue';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get languagePortuguese => 'Portugais';

  @override
  String get appLanguage => 'Langue de l\'application';

  @override
  String get testNotification => 'Tester la notification';

  @override
  String get testNotificationDescription =>
      'Envoyer une notification de test maintenant';

  @override
  String get testNotificationSent => 'Notification de test envoyée!';

  @override
  String get testNotificationError =>
      'Erreur lors de l\'envoi de la notification de test';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get useExternalAudio => 'Utiliser l\'audio externe';

  @override
  String get selectAudioFile => 'Sélectionner un fichier audio';

  @override
  String get audioFileSelected => 'Fichier audio sélectionné';

  @override
  String get removeAudio => 'Supprimer l\'audio';

  @override
  String get noAudio => 'Pas d\'audio';

  @override
  String get externalAudio => 'Audio externe';

  @override
  String get originalAudio => 'Audio original';

  @override
  String get projects => 'Projets';

  @override
  String get freeProjects => 'Projets Libres';

  @override
  String get noProjectsYet => 'Aucun projet pour le moment';

  @override
  String get createFirstProject => 'Créez votre premier projet pour commencer';

  @override
  String get newProject => 'Nouveau Projet';

  @override
  String get projectName => 'Nom du Projet';

  @override
  String get enterProjectName => 'Entrez le nom du projet';

  @override
  String get description => 'Description';

  @override
  String get descriptionOptional => 'Description (optionnel)';

  @override
  String get enterDescription => 'Entrez la description';

  @override
  String get create => 'Créer';

  @override
  String get deleteProject => 'Supprimer le Projet';

  @override
  String deleteProjectConfirm(String name) {
    return 'Êtes-vous sûr de vouloir supprimer \"$name\"?';
  }

  @override
  String get items => 'éléments';

  @override
  String get yesterday => 'Hier';

  @override
  String daysAgo(int count) {
    return 'Il y a $count jours';
  }

  @override
  String get addMedia => 'Ajouter des Médias';

  @override
  String get deleteItem => 'Supprimer l\'Élément';

  @override
  String get deleteItemConfirm =>
      'Êtes-vous sûr de vouloir supprimer cet élément?';

  @override
  String get noMediaItemsYet => 'Aucun élément média pour le moment';

  @override
  String errorAddingMedia(String error) {
    return 'Erreur lors de l\'ajout de médias: $error';
  }

  @override
  String get renderProjectVideo => 'Rendre la Vidéo du Projet';

  @override
  String renderProjectVideoConfirm(int count) {
    return 'Rendre tous les $count éléments en une vidéo?';
  }

  @override
  String get render => 'Rendre';

  @override
  String get edited => 'Modifié';

  @override
  String get original => 'Original';

  @override
  String get photoAdded => 'Photo Ajoutée';

  @override
  String get doYouWantToEdit => 'Voulez-vous modifier la photo maintenant?';

  @override
  String get skip => 'Passer';

  @override
  String get editPhoto => 'Modifier la Photo';

  @override
  String get editVideo => 'Modifier la Vidéo';

  @override
  String get rotate => 'Tourner';

  @override
  String get filter => 'Filtre';

  @override
  String get animation => 'Animation';

  @override
  String get speed => 'Vitesse: ';

  @override
  String get muteAudio => 'Couper l\'Audio';

  @override
  String get save => 'Enregistrer';

  @override
  String get editPhotoDaily => 'Modifier la Photo';

  @override
  String get convertToLandscape => 'Convertir en Paysage';

  @override
  String get convertWithCrop => 'Convertir avec Recadrage';

  @override
  String get convertWithoutCrop => 'Convertir sans Recadrage (Rotation)';

  @override
  String get imageAlreadyLandscape =>
      'L\'image est déjà en orientation paysage';

  @override
  String errorConvertingImage(String error) {
    return 'Erreur lors de la conversion de l\'image: $error';
  }

  @override
  String get cropImage => 'Recadrer l\'Image';

  @override
  String get record => 'Enregistrer';

  @override
  String recordFor(String date) {
    return 'Enregistrer - $date';
  }

  @override
  String get imageNotFound => 'Image introuvable';

  @override
  String get errorLoadingImage => 'Erreur lors du chargement de l\'image';

  @override
  String errorRotatingImage(String error) {
    return 'Erreur lors de la rotation de l\'image: $error';
  }

  @override
  String errorApplyingFilter(String error) {
    return 'Erreur lors de l\'application du filtre: $error';
  }

  @override
  String get editsSaved => 'Modifications enregistrées';

  @override
  String startTime(int ms) {
    return 'Heure de début: ${ms}ms';
  }

  @override
  String errorSelectingAudio(String error) {
    return 'Erreur lors de la sélection de l\'audio: $error';
  }

  @override
  String get languageSpanish => 'Espagnol';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageGerman => 'Allemand';

  @override
  String get languageItalian => 'Italien';

  @override
  String get notifications => 'Notifications';

  @override
  String get export => 'Exportation';

  @override
  String get backup => 'Sauvegarde';

  @override
  String get statistics => 'Statistiques';

  @override
  String get generateVideosDescription => 'Générer des vidéos compilées';

  @override
  String get hours => 'heures';

  @override
  String get reminder => 'Rappel';

  @override
  String get reminderChannelDescription => 'Rappels supplémentaires';

  @override
  String get haventRecordedToday =>
      'Vous n\'avez pas encore enregistré aujourd\'hui ?';

  @override
  String get captureMomentNow => 'Et si vous capturiez un moment maintenant ?';

  @override
  String get dailyReminder => 'Rappel Quotidien';

  @override
  String get dailyReminderDescription =>
      'Notifications pour vous rappeler d\'enregistrer votre moment de la journée';

  @override
  String get notificationTitle => 'Retro1';

  @override
  String get notificationBody =>
      'N\'oubliez pas d\'enregistrer votre moment d\'aujourd\'hui !';

  @override
  String get appearance => 'Apparence';

  @override
  String get theme => 'Thème';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeSystem => 'Système';

  @override
  String get loadMoreDays => 'Charger Plus de Jours';

  @override
  String get mondayShort => 'Lun';

  @override
  String get tuesdayShort => 'Mar';

  @override
  String get wednesdayShort => 'Mer';

  @override
  String get thursdayShort => 'Jeu';

  @override
  String get fridayShort => 'Ven';

  @override
  String get saturdayShort => 'Sam';

  @override
  String get sundayShort => 'Dim';
}
