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
  String get preview1s => 'Preview (1s)';

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
}
