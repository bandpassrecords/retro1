// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Retro1';

  @override
  String get timeline => 'Timeline';

  @override
  String get settings => 'Configurações';

  @override
  String get generateVideos => 'Gerar Vídeos';

  @override
  String get editTodayEntry => 'Editar Entrada de Hoje';

  @override
  String get recordToday => 'Registrar Hoje';

  @override
  String get view => 'Visualizar';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Excluir';

  @override
  String get cancel => 'Cancelar';

  @override
  String get yes => 'Sim';

  @override
  String get replace => 'Substituir';

  @override
  String get confirmDeletion => 'Confirmar exclusão';

  @override
  String get confirmDeletionMessage =>
      'Tem certeza que deseja excluir esta entrada?';

  @override
  String get entryDeleted => 'Entrada excluída';

  @override
  String get entrySaved => 'Entrada salva com sucesso!';

  @override
  String addEntryFor(String date) {
    return 'Adicionar entrada para $date';
  }

  @override
  String get captureOrImport => 'Deseja capturar ou importar uma mídia?';

  @override
  String get recordVideo => 'Gravar Vídeo';

  @override
  String get takePhoto => 'Tirar Foto';

  @override
  String get videoFromGallery => 'Vídeo da Galeria';

  @override
  String get photoFromGallery => 'Foto da Galeria';

  @override
  String get chooseHowToRecord => 'Escolha como deseja registrar seu momento:';

  @override
  String get entryAlreadyExists => 'Já existe uma entrada';

  @override
  String get entryAlreadyExistsMessage =>
      'Já existe uma entrada para este dia. Deseja substituir?';

  @override
  String get editorChooseSecond => 'Editor - Escolha 1 Segundo';

  @override
  String get playing => 'Reproduzindo...';

  @override
  String get preview1s => 'Preview 1s';

  @override
  String errorLoadingVideo(String error) {
    return 'Erro ao carregar vídeo: $error';
  }

  @override
  String errorSaving(String error) {
    return 'Erro ao salvar: $error';
  }

  @override
  String get video => 'Vídeo';

  @override
  String get photo => 'Foto';

  @override
  String get all => 'Todos';

  @override
  String get videosOnly => 'Apenas Vídeos';

  @override
  String get photosOnly => 'Apenas Fotos';

  @override
  String get noCaption => 'Sem legenda';

  @override
  String get generateByPeriod => 'Gerar por Período';

  @override
  String get currentMonth => 'Mês Atual';

  @override
  String get currentYear => 'Ano Atual';

  @override
  String get customRange => 'Intervalo Customizado';

  @override
  String get chooseDates => 'Escolha as datas';

  @override
  String get generatingVideo =>
      'Gerando vídeo... Isso pode levar alguns minutos.';

  @override
  String get videoGeneratedSuccess => 'Vídeo gerado com sucesso!';

  @override
  String get share => 'Compartilhar';

  @override
  String get newButton => 'Novo';

  @override
  String errorSharing(String error) {
    return 'Erro ao compartilhar: $error';
  }

  @override
  String get noVideoCaptured => 'Nenhum vídeo foi capturado';

  @override
  String errorCapturingVideo(String error) {
    return 'Erro ao capturar vídeo: $error';
  }

  @override
  String get noPhotoCaptured => 'Nenhuma foto foi capturada';

  @override
  String errorCapturingPhoto(String error) {
    return 'Erro ao capturar foto: $error';
  }

  @override
  String get noVideoSelected => 'Nenhum vídeo foi selecionado';

  @override
  String errorSelectingVideo(String error) {
    return 'Erro ao selecionar vídeo: $error';
  }

  @override
  String get noPhotoSelected => 'Nenhuma foto foi selecionada';

  @override
  String errorSelectingPhoto(String error) {
    return 'Erro ao selecionar foto: $error';
  }

  @override
  String errorProcessingMedia(String error) {
    return 'Erro ao processar mídia: $error';
  }

  @override
  String get noEntriesFound => 'Nenhuma entrada encontrada para este período.';

  @override
  String errorGeneratingVideo(String error) {
    return 'Erro ao gerar vídeo: $error';
  }

  @override
  String get enableNotifications => 'Ativar notificações';

  @override
  String get notificationTime => 'Horário da notificação';

  @override
  String get reminderAfter => 'Lembrete após (horas)';

  @override
  String get weeklySummary => 'Resumo semanal';

  @override
  String get videoQuality => 'Qualidade do vídeo';

  @override
  String get showDateInVideo => 'Mostrar data no vídeo';

  @override
  String get autoExportEndOfYear => 'Exportação automática no fim do ano';

  @override
  String get autoBackup => 'Backup automático';

  @override
  String get totalEntries => 'Total de entradas';

  @override
  String get entriesThisYear => 'Entradas deste ano';

  @override
  String get entries => 'entradas';

  @override
  String get settingsSaved => 'Configurações salvas';

  @override
  String get quality720p => '720p';

  @override
  String get quality1080p => '1080p';

  @override
  String get quality4k => '4K';

  @override
  String get language => 'Idioma';

  @override
  String get languageEnglish => 'Inglês';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get appLanguage => 'Idioma do aplicativo';

  @override
  String get testNotification => 'Testar notificação';

  @override
  String get testNotificationDescription =>
      'Enviar uma notificação de teste agora';

  @override
  String get testNotificationSent => 'Notificação de teste enviada!';

  @override
  String get testNotificationError => 'Erro ao enviar notificação de teste';

  @override
  String get today => 'Hoje';

  @override
  String get useExternalAudio => 'Usar áudio externo';

  @override
  String get selectAudioFile => 'Selecionar arquivo de áudio';

  @override
  String get audioFileSelected => 'Arquivo de áudio selecionado';

  @override
  String get removeAudio => 'Remover áudio';

  @override
  String get noAudio => 'Sem áudio';

  @override
  String get externalAudio => 'Áudio externo';

  @override
  String get originalAudio => 'Áudio original';

  @override
  String get projects => 'Projetos';

  @override
  String get freeProjects => 'Projetos Livres';

  @override
  String get noProjectsYet => 'Nenhum projeto ainda';

  @override
  String get createFirstProject => 'Crie seu primeiro projeto para começar';

  @override
  String get newProject => 'Novo Projeto';

  @override
  String get projectName => 'Nome do Projeto';

  @override
  String get enterProjectName => 'Digite o nome do projeto';

  @override
  String get description => 'Descrição';

  @override
  String get descriptionOptional => 'Descrição (opcional)';

  @override
  String get enterDescription => 'Digite a descrição';

  @override
  String get create => 'Criar';

  @override
  String get deleteProject => 'Excluir Projeto';

  @override
  String deleteProjectConfirm(String name) {
    return 'Tem certeza que deseja excluir \"$name\"?';
  }

  @override
  String get items => 'itens';

  @override
  String get yesterday => 'Ontem';

  @override
  String daysAgo(int count) {
    return '$count dias atrás';
  }

  @override
  String get addMedia => 'Adicionar Mídia';

  @override
  String get deleteItem => 'Excluir Item';

  @override
  String get deleteItemConfirm => 'Tem certeza que deseja excluir este item?';

  @override
  String get noMediaItemsYet => 'Nenhum item de mídia ainda';

  @override
  String errorAddingMedia(String error) {
    return 'Erro ao adicionar mídia: $error';
  }

  @override
  String get renderProjectVideo => 'Renderizar Vídeo do Projeto';

  @override
  String renderProjectVideoConfirm(int count) {
    return 'Renderizar todos os $count itens em um vídeo?';
  }

  @override
  String get render => 'Renderizar';

  @override
  String get edited => 'Editado';

  @override
  String get original => 'Original';

  @override
  String get photoAdded => 'Foto Adicionada';

  @override
  String get doYouWantToEdit => 'Deseja editar a foto agora?';

  @override
  String get skip => 'Pular';

  @override
  String get editPhoto => 'Editar Foto';

  @override
  String get editVideo => 'Editar Vídeo';

  @override
  String get rotate => 'Rotacionar';

  @override
  String get filter => 'Filtro';

  @override
  String get animation => 'Animação';

  @override
  String get speed => 'Velocidade: ';

  @override
  String get muteAudio => 'Mutear Áudio';

  @override
  String get save => 'Salvar';

  @override
  String get editPhotoDaily => 'Editar Foto';

  @override
  String get record => 'Registrar';

  @override
  String recordFor(String date) {
    return 'Registrar - $date';
  }

  @override
  String get imageNotFound => 'Imagem não encontrada';

  @override
  String get errorLoadingImage => 'Erro ao carregar imagem';

  @override
  String errorRotatingImage(String error) {
    return 'Erro ao rotacionar imagem: $error';
  }

  @override
  String errorApplyingFilter(String error) {
    return 'Erro ao aplicar filtro: $error';
  }

  @override
  String get editsSaved => 'Edições salvas';

  @override
  String startTime(int ms) {
    return 'Tempo de Início: ${ms}ms';
  }

  @override
  String errorSelectingAudio(String error) {
    return 'Erro ao selecionar áudio: $error';
  }

  @override
  String get languageSpanish => 'Espanhol';

  @override
  String get languageFrench => 'Francês';

  @override
  String get languageGerman => 'Alemão';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get notifications => 'Notificações';

  @override
  String get export => 'Exportação';

  @override
  String get backup => 'Backup';

  @override
  String get statistics => 'Estatísticas';

  @override
  String get generateVideosDescription => 'Gerar vídeos compilados';

  @override
  String get hours => 'horas';

  @override
  String get reminder => 'Lembrete';

  @override
  String get reminderChannelDescription => 'Lembretes adicionais';

  @override
  String get haventRecordedToday => 'Ainda não registrou hoje?';

  @override
  String get captureMomentNow => 'Que tal capturar um momento agora?';

  @override
  String get dailyReminder => 'Lembrete Diário';

  @override
  String get dailyReminderDescription =>
      'Notificações para lembrar de registrar seu segundo do dia';

  @override
  String get notificationTitle => 'Retro1';

  @override
  String get notificationBody =>
      'Não se esqueça de registrar seu momento de hoje!';

  @override
  String get appearance => 'Aparência';

  @override
  String get theme => 'Tema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get loadMoreDays => 'Carregar Mais Dias';

  @override
  String get mondayShort => 'Seg';

  @override
  String get tuesdayShort => 'Ter';

  @override
  String get wednesdayShort => 'Qua';

  @override
  String get thursdayShort => 'Qui';

  @override
  String get fridayShort => 'Sex';

  @override
  String get saturdayShort => 'Sáb';

  @override
  String get sundayShort => 'Dom';
}
