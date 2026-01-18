// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Retro1';

  @override
  String get timeline => 'Línea de tiempo';

  @override
  String get settings => 'Configuración';

  @override
  String get generateVideos => 'Generar Videos';

  @override
  String get editTodayEntry => 'Editar Entrada de Hoy';

  @override
  String get recordToday => 'Grabar Hoy';

  @override
  String get view => 'Ver';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Eliminar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get yes => 'Sí';

  @override
  String get replace => 'Reemplazar';

  @override
  String get confirmDeletion => 'Confirmar eliminación';

  @override
  String get confirmDeletionMessage =>
      '¿Está seguro de que desea eliminar esta entrada?';

  @override
  String get entryDeleted => 'Entrada eliminada';

  @override
  String get entrySaved => '¡Entrada guardada con éxito!';

  @override
  String addEntryFor(String date) {
    return 'Agregar entrada para $date';
  }

  @override
  String get captureOrImport => '¿Desea capturar o importar medios?';

  @override
  String get recordVideo => 'Grabar Video';

  @override
  String get takePhoto => 'Tomar Foto';

  @override
  String get videoFromGallery => 'Video de la Galería';

  @override
  String get photoFromGallery => 'Foto de la Galería';

  @override
  String get chooseHowToRecord => 'Elija cómo desea grabar su momento:';

  @override
  String get entryAlreadyExists => 'Ya existe una entrada';

  @override
  String get entryAlreadyExistsMessage =>
      'Ya existe una entrada para este día. ¿Desea reemplazarla?';

  @override
  String get editorChooseSecond => 'Editor - Elija 1 Segundo';

  @override
  String get playing => 'Reproduciendo...';

  @override
  String get preview1s => 'Vista previa (1s)';

  @override
  String errorLoadingVideo(String error) {
    return 'Error al cargar video: $error';
  }

  @override
  String errorSaving(String error) {
    return 'Error al guardar: $error';
  }

  @override
  String get video => 'Video';

  @override
  String get photo => 'Foto';

  @override
  String get all => 'Todos';

  @override
  String get videosOnly => 'Solo Videos';

  @override
  String get photosOnly => 'Solo Fotos';

  @override
  String get noCaption => 'Sin leyenda';

  @override
  String get generateByPeriod => 'Generar por Período';

  @override
  String get currentMonth => 'Mes Actual';

  @override
  String get currentYear => 'Año Actual';

  @override
  String get customRange => 'Rango Personalizado';

  @override
  String get chooseDates => 'Elija las fechas';

  @override
  String get generatingVideo =>
      'Generando video... Esto puede tardar unos minutos.';

  @override
  String get videoGeneratedSuccess => '¡Video generado con éxito!';

  @override
  String get share => 'Compartir';

  @override
  String get newButton => 'Nuevo';

  @override
  String errorSharing(String error) {
    return 'Error al compartir: $error';
  }

  @override
  String get noEntriesFound => 'No se encontraron entradas para este período.';

  @override
  String errorGeneratingVideo(String error) {
    return 'Error al generar video: $error';
  }

  @override
  String get enableNotifications => 'Activar notificaciones';

  @override
  String get notificationTime => 'Hora de notificación';

  @override
  String get reminderAfter => 'Recordatorio después (horas)';

  @override
  String get weeklySummary => 'Resumen semanal';

  @override
  String get videoQuality => 'Calidad del video';

  @override
  String get showDateInVideo => 'Mostrar fecha en video';

  @override
  String get autoExportEndOfYear => 'Exportación automática al final del año';

  @override
  String get autoBackup => 'Copia de seguridad automática';

  @override
  String get totalEntries => 'Total de entradas';

  @override
  String get entriesThisYear => 'Entradas de este año';

  @override
  String get entries => 'entradas';

  @override
  String get settingsSaved => 'Configuración guardada';

  @override
  String get quality720p => '720p';

  @override
  String get quality1080p => '1080p';

  @override
  String get quality4k => '4K';

  @override
  String get language => 'Idioma';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languagePortuguese => 'Portugués';

  @override
  String get appLanguage => 'Idioma de la aplicación';

  @override
  String get testNotification => 'Probar notificación';

  @override
  String get testNotificationDescription =>
      'Enviar una notificación de prueba ahora';

  @override
  String get testNotificationSent => '¡Notificación de prueba enviada!';

  @override
  String get testNotificationError => 'Error al enviar notificación de prueba';

  @override
  String get today => 'Hoy';

  @override
  String get useExternalAudio => 'Usar audio externo';

  @override
  String get selectAudioFile => 'Seleccionar archivo de audio';

  @override
  String get audioFileSelected => 'Archivo de audio seleccionado';

  @override
  String get removeAudio => 'Quitar audio';

  @override
  String get noAudio => 'Sin audio';

  @override
  String get externalAudio => 'Audio externo';

  @override
  String get originalAudio => 'Audio original';

  @override
  String get projects => 'Proyectos';

  @override
  String get freeProjects => 'Proyectos Libres';

  @override
  String get noProjectsYet => 'Aún no hay proyectos';

  @override
  String get createFirstProject => 'Cree su primer proyecto para comenzar';

  @override
  String get newProject => 'Nuevo Proyecto';

  @override
  String get projectName => 'Nombre del Proyecto';

  @override
  String get enterProjectName => 'Ingrese el nombre del proyecto';

  @override
  String get description => 'Descripción';

  @override
  String get descriptionOptional => 'Descripción (opcional)';

  @override
  String get enterDescription => 'Ingrese la descripción';

  @override
  String get create => 'Crear';

  @override
  String get deleteProject => 'Eliminar Proyecto';

  @override
  String deleteProjectConfirm(String name) {
    return '¿Está seguro de que desea eliminar \"$name\"?';
  }

  @override
  String get items => 'elementos';

  @override
  String get yesterday => 'Ayer';

  @override
  String daysAgo(int count) {
    return 'Hace $count días';
  }

  @override
  String get addMedia => 'Agregar Medios';

  @override
  String get deleteItem => 'Eliminar Elemento';

  @override
  String get deleteItemConfirm =>
      '¿Está seguro de que desea eliminar este elemento?';

  @override
  String get noMediaItemsYet => 'Aún no hay elementos de medios';

  @override
  String errorAddingMedia(String error) {
    return 'Error al agregar medios: $error';
  }

  @override
  String get renderProjectVideo => 'Renderizar Video del Proyecto';

  @override
  String renderProjectVideoConfirm(int count) {
    return '¿Renderizar todos los $count elementos en un video?';
  }

  @override
  String get render => 'Renderizar';

  @override
  String get edited => 'Editado';

  @override
  String get original => 'Original';

  @override
  String get photoAdded => 'Foto Agregada';

  @override
  String get doYouWantToEdit => '¿Desea editar la foto ahora?';

  @override
  String get skip => 'Omitir';

  @override
  String get editPhoto => 'Editar Foto';

  @override
  String get editVideo => 'Editar Video';

  @override
  String get rotate => 'Rotar';

  @override
  String get filter => 'Filtro';

  @override
  String get animation => 'Animación';

  @override
  String get speed => 'Velocidad';

  @override
  String get muteAudio => 'Silenciar Audio';

  @override
  String get save => 'Guardar';

  @override
  String get editPhotoDaily => 'Editar Foto';

  @override
  String get record => 'Record';

  @override
  String recordFor(String date) {
    return 'Record - $date';
  }

  @override
  String get cancelar => 'Cancel';

  @override
  String get substituir => 'Replace';

  @override
  String get entradaSalvaSucesso => 'Entry saved successfully!';

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
  String get notifications => 'Notificaciones';

  @override
  String get export => 'Exportación';

  @override
  String get backup => 'Copia de Seguridad';

  @override
  String get statistics => 'Estadísticas';

  @override
  String get generateVideosDescription => 'Generar videos compilados';

  @override
  String get hours => 'horas';

  @override
  String get reminder => 'Recordatorio';

  @override
  String get reminderChannelDescription => 'Recordatorios adicionales';

  @override
  String get haventRecordedToday => '¿Aún no has registrado hoy?';

  @override
  String get captureMomentNow => '¿Qué tal capturar un momento ahora?';

  @override
  String get dailyReminder => 'Recordatorio Diario';

  @override
  String get dailyReminderDescription =>
      'Notificaciones para recordarte de registrar tu momento del día';

  @override
  String get notificationTitle => 'Retro1';

  @override
  String get notificationBody => '¡No olvides registrar tu momento de hoy!';

  @override
  String get appearance => 'Apariencia';

  @override
  String get theme => 'Tema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeSystem => 'Sistema';
}
