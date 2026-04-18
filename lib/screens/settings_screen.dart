import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:retro1/l10n/app_localizations.dart';
import 'package:retro1/main.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../services/backup_service.dart';
import '../services/timeline_prefs.dart';
import '../models/app_settings.dart';
import 'video_generator_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;
  GoogleSignInAccount? _googleAccount;
  String? _lastBackupLabel;
  bool _backupInProgress = false;
  bool _restoreInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadBackupState();
  }

  void _loadSettings() {
    setState(() {
      _settings = HiveService.getSettings();
    });
  }

  Future<void> _loadBackupState() async {
    final account = await BackupService.currentUser;
    final backupFile = await BackupService.getLatestBackupInfo();
    if (!mounted) return;
    setState(() {
      _googleAccount = account;
      _lastBackupLabel = _settings.lastBackupTime != null
          ? _formatDateTime(_settings.lastBackupTime!)
          : (backupFile != null ? 'Available on Drive' : 'No backup found');
    });
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveSettings() async {
    await HiveService.saveSettings(_settings);
    await NotificationService.scheduleNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          // Aparência
          _buildSectionHeader(l10n.appearance),
          ListTile(
            title: Text(l10n.theme),
            subtitle: Text(_getThemeName(_settings.themeMode, l10n)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.theme),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<String>(
                        title: Text(l10n.themeLight),
                        value: 'light',
                        groupValue: _settings.themeMode,
                        onChanged: (value) async {
                          setState(() {
                            _settings.themeMode = value!;
                          });
                          Navigator.pop(context);
                          await _saveSettings();
                          MyApp.updateTheme();
                        },
                      ),
                      RadioListTile<String>(
                        title: Text(l10n.themeDark),
                        value: 'dark',
                        groupValue: _settings.themeMode,
                        onChanged: (value) async {
                          setState(() {
                            _settings.themeMode = value!;
                          });
                          Navigator.pop(context);
                          await _saveSettings();
                          MyApp.updateTheme();
                        },
                      ),
                      RadioListTile<String>(
                        title: Text(l10n.themeSystem),
                        value: 'system',
                        groupValue: _settings.themeMode,
                        onChanged: (value) async {
                          setState(() {
                            _settings.themeMode = value!;
                          });
                          Navigator.pop(context);
                          await _saveSettings();
                          MyApp.updateTheme();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Vista da timeline
          ValueListenableBuilder<String?>(
            valueListenable: TimelinePrefs.notifier,
            builder: (context, view, _) {
              final current = view ?? TimelinePrefs.calendarView;
              return ListTile(
                title: Text(l10n.timelineViewTitle),
                subtitle: Text(current == TimelinePrefs.gridView
                    ? l10n.gridView
                    : l10n.calendarView),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.timelineViewTitle),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<String>(
                            title: Text(l10n.calendarView),
                            value: TimelinePrefs.calendarView,
                            groupValue: TimelinePrefs.current,
                            onChanged: (value) {
                              Navigator.pop(context);
                              TimelinePrefs.set(value!);
                            },
                          ),
                          RadioListTile<String>(
                            title: Text(l10n.gridView),
                            value: TimelinePrefs.gridView,
                            groupValue: TimelinePrefs.current,
                            onChanged: (value) {
                              Navigator.pop(context);
                              TimelinePrefs.set(value!);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // Seletor de mídia
          ValueListenableBuilder<String?>(
            valueListenable: MediaPickerPrefs.notifier,
            builder: (context, style, _) {
              final current = style ?? MediaPickerPrefs.customPicker;
              return ListTile(
                title: Text(l10n.mediaPickerTitle),
                subtitle: Text(current == MediaPickerPrefs.systemPicker
                    ? l10n.systemPicker
                    : l10n.customPicker),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.mediaPickerTitle),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<String>(
                            title: Text(l10n.customPicker),
                            subtitle: Text(l10n.customPickerDescription),
                            value: MediaPickerPrefs.customPicker,
                            groupValue: MediaPickerPrefs.current,
                            onChanged: (value) {
                              Navigator.pop(context);
                              MediaPickerPrefs.set(value!);
                            },
                          ),
                          RadioListTile<String>(
                            title: Text(l10n.systemPicker),
                            subtitle: Text(l10n.systemPickerDescription),
                            value: MediaPickerPrefs.systemPicker,
                            groupValue: MediaPickerPrefs.current,
                            onChanged: (value) {
                              Navigator.pop(context);
                              MediaPickerPrefs.set(value!);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // Tamanho das miniaturas
          ValueListenableBuilder<String?>(
            valueListenable: ThumbnailSizePrefs.notifier,
            builder: (context, size, _) {
              final current = size ?? ThumbnailSizePrefs.small;
              return ListTile(
                title: Text(l10n.thumbnailSizeTitle),
                subtitle: Text(current == ThumbnailSizePrefs.large
                    ? l10n.largeThumbnails
                    : l10n.smallThumbnails),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.thumbnailSizeTitle),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<String>(
                            title: Text(l10n.smallThumbnails),
                            value: ThumbnailSizePrefs.small,
                            groupValue: ThumbnailSizePrefs.current,
                            onChanged: (value) {
                              Navigator.pop(context);
                              ThumbnailSizePrefs.set(value!);
                            },
                          ),
                          RadioListTile<String>(
                            title: Text(l10n.largeThumbnails),
                            value: ThumbnailSizePrefs.large,
                            groupValue: ThumbnailSizePrefs.current,
                            onChanged: (value) {
                              Navigator.pop(context);
                              ThumbnailSizePrefs.set(value!);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // Idioma
          _buildSectionHeader(l10n.language),
          ListTile(
            title: Text(l10n.appLanguage),
            subtitle: Text(_getLanguageName(_settings.language, l10n)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.language),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<String>(
                        title: Text(l10n.languageEnglish),
                        value: 'en',
                        groupValue: _settings.language,
                        onChanged: (value) async {
                          Navigator.pop(context);
                          // Atualizar e salvar
                          _settings.language = value!;
                          await _saveSettings();
                          // Atualizar idioma do app (isso vai fazer o rebuild)
                          MyApp.updateLanguage();
                          // Recarregar configurações do Hive para garantir sincronização
                          // Aguardar um pouco para o rebuild acontecer
                          await Future.delayed(const Duration(milliseconds: 50));
                          if (mounted) {
                            setState(() {
                              _settings = HiveService.getSettings();
                            });
                          }
                        },
                      ),
                      RadioListTile<String>(
                        title: Text(l10n.languagePortuguese),
                        value: 'pt',
                        groupValue: _settings.language,
                        onChanged: (value) async {
                          Navigator.pop(context);
                          // Atualizar e salvar
                          _settings.language = value!;
                          await _saveSettings();
                          // Atualizar idioma do app (isso vai fazer o rebuild)
                          MyApp.updateLanguage();
                          // Recarregar configurações do Hive para garantir sincronização
                          // Aguardar um pouco para o rebuild acontecer
                          await Future.delayed(const Duration(milliseconds: 50));
                          if (mounted) {
                            setState(() {
                              _settings = HiveService.getSettings();
                            });
                          }
                        },
                      ),
                      RadioListTile<String>(
                        title: Text(l10n.languageSpanish),
                        value: 'es',
                        groupValue: _settings.language,
                        onChanged: (value) async {
                          Navigator.pop(context);
                          // Atualizar e salvar
                          _settings.language = value!;
                          await _saveSettings();
                          // Atualizar idioma do app (isso vai fazer o rebuild)
                          MyApp.updateLanguage();
                          // Recarregar configurações do Hive para garantir sincronização
                          // Aguardar um pouco para o rebuild acontecer
                          await Future.delayed(const Duration(milliseconds: 50));
                          if (mounted) {
                            setState(() {
                              _settings = HiveService.getSettings();
                            });
                          }
                        },
                      ),
                      RadioListTile<String>(
                        title: Text(l10n.languageFrench),
                        value: 'fr',
                        groupValue: _settings.language,
                        onChanged: (value) async {
                          Navigator.pop(context);
                          // Atualizar e salvar
                          _settings.language = value!;
                          await _saveSettings();
                          // Atualizar idioma do app (isso vai fazer o rebuild)
                          MyApp.updateLanguage();
                          // Recarregar configurações do Hive para garantir sincronização
                          // Aguardar um pouco para o rebuild acontecer
                          await Future.delayed(const Duration(milliseconds: 50));
                          if (mounted) {
                            setState(() {
                              _settings = HiveService.getSettings();
                            });
                          }
                        },
                      ),
                      RadioListTile<String>(
                        title: Text(l10n.languageGerman),
                        value: 'de',
                        groupValue: _settings.language,
                        onChanged: (value) async {
                          Navigator.pop(context);
                          // Atualizar e salvar
                          _settings.language = value!;
                          await _saveSettings();
                          // Atualizar idioma do app (isso vai fazer o rebuild)
                          MyApp.updateLanguage();
                          // Recarregar configurações do Hive para garantir sincronização
                          // Aguardar um pouco para o rebuild acontecer
                          await Future.delayed(const Duration(milliseconds: 50));
                          if (mounted) {
                            setState(() {
                              _settings = HiveService.getSettings();
                            });
                          }
                        },
                      ),
                      RadioListTile<String>(
                        title: Text(l10n.languageItalian),
                        value: 'it',
                        groupValue: _settings.language,
                        onChanged: (value) async {
                          Navigator.pop(context);
                          // Atualizar e salvar
                          _settings.language = value!;
                          await _saveSettings();
                          // Atualizar idioma do app (isso vai fazer o rebuild)
                          MyApp.updateLanguage();
                          // Recarregar configurações do Hive para garantir sincronização
                          // Aguardar um pouco para o rebuild acontecer
                          await Future.delayed(const Duration(milliseconds: 50));
                          if (mounted) {
                            setState(() {
                              _settings = HiveService.getSettings();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Notificações
          _buildSectionHeader(l10n.notifications),
          SwitchListTile(
            title: Text(l10n.enableNotifications),
            value: _settings.notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _settings.notificationsEnabled = value;
              });
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: Text(l10n.notificationUseQuotes),
            subtitle: Text(l10n.notificationUseQuotesDescription),
            value: _settings.notificationUseQuotes,
            onChanged: _settings.notificationsEnabled
                ? (value) {
                    setState(() {
                      _settings.notificationUseQuotes = value;
                    });
                    _saveSettings();
                  }
                : null,
          ),
          ListTile(
            title: Text(l10n.notificationTime),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_settings.notificationTime.hour.toString().padLeft(2, '0')}:'
                  '${_settings.notificationTime.minute.toString().padLeft(2, '0')}',
                ),
                const SizedBox(height: 4),
                Text(
                  _getTimezoneInfo(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _settings.notificationTime,
              );
              if (time != null) {
                setState(() {
                  _settings.notificationTime = time;
                });
                await _saveSettings();
              }
            },
          ),
          ListTile(
            title: Text(l10n.reminderAfter),
            subtitle: Text('${_settings.reminderDelayHours} ${l10n.hours}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (_settings.reminderDelayHours > 0) {
                      setState(() {
                        _settings.reminderDelayHours--;
                      });
                      _saveSettings();
                    }
                  },
                ),
                Text('${_settings.reminderDelayHours}'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _settings.reminderDelayHours++;
                    });
                    _saveSettings();
                  },
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(l10n.testNotification),
            subtitle: Text(l10n.testNotificationDescription),
            trailing: const Icon(Icons.notifications_active),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await NotificationService.sendTestNotification();
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('${l10n.testNotificationError}: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          ListTile(
            title: Text(l10n.testProductionNotification),
            subtitle: Text(l10n.testProductionNotificationDescription),
            trailing: const Icon(Icons.preview_outlined),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await NotificationService.sendProductionPreviewNotification();
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('${l10n.testNotificationError}: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),

          // Vídeo
          _buildSectionHeader(l10n.video),
          ListTile(
            title: Text(l10n.videoQuality),
            subtitle: Text(_settings.videoQuality),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.videoQuality),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<String>(
                        title: Text(l10n.quality720p),
                        value: '720p',
                        groupValue: _settings.videoQuality,
                        onChanged: (value) {
                          setState(() {
                            _settings.videoQuality = value!;
                          });
                          Navigator.pop(context);
                          _saveSettings();
                        },
                      ),
                      RadioListTile<String>(
                        title: Text(l10n.quality1080p),
                        value: '1080p',
                        groupValue: _settings.videoQuality,
                        onChanged: (value) {
                          setState(() {
                            _settings.videoQuality = value!;
                          });
                          Navigator.pop(context);
                          _saveSettings();
                        },
                      ),
                      RadioListTile<String>(
                        title: Text(l10n.quality4k),
                        value: '4K',
                        groupValue: _settings.videoQuality,
                        onChanged: (value) {
                          setState(() {
                            _settings.videoQuality = value!;
                          });
                          Navigator.pop(context);
                          _saveSettings();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          SwitchListTile(
            title: Text(l10n.showDateInVideo),
            value: _settings.showDateOverlay,
            onChanged: (value) {
              setState(() => _settings.showDateOverlay = value);
              _saveSettings();
            },
          ),
          if (_settings.showDateOverlay)
            ListTile(
              title: Text(l10n.dateFormatLabel),
              subtitle: Text(_settings.dateFormat),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.dateFormatLabel),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<String>(
                          title: const Text('dd/MM/yyyy'),
                          subtitle: const Text('31/12/2024'),
                          value: 'dd/MM/yyyy',
                          groupValue: _settings.dateFormat,
                          onChanged: (value) {
                            setState(() => _settings.dateFormat = value!);
                            Navigator.pop(context);
                            _saveSettings();
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('MM/dd/yyyy'),
                          subtitle: const Text('12/31/2024'),
                          value: 'MM/dd/yyyy',
                          groupValue: _settings.dateFormat,
                          onChanged: (value) {
                            setState(() => _settings.dateFormat = value!);
                            Navigator.pop(context);
                            _saveSettings();
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('yyyy/MM/dd'),
                          subtitle: const Text('2024/12/31'),
                          value: 'yyyy/MM/dd',
                          groupValue: _settings.dateFormat,
                          onChanged: (value) {
                            setState(() => _settings.dateFormat = value!);
                            Navigator.pop(context);
                            _saveSettings();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Exportação
          _buildSectionHeader(l10n.export),
          ListTile(
            title: Text(l10n.generateVideos),
            subtitle: Text(l10n.generateVideosDescription),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VideoGeneratorScreen(),
                ),
              );
            },
          ),

          // Backup
          _buildSectionHeader('Google Drive Backup'),
          if (_googleAccount == null) ...[
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text('Sign in with Google'),
              subtitle: const Text('Required to enable backup'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final account = await BackupService.signIn();
                if (!mounted) return;
                setState(() => _googleAccount = account);
                if (account != null) _loadBackupState();
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: Text(_googleAccount!.displayName ?? _googleAccount!.email),
              subtitle: Text(_googleAccount!.email),
              trailing: TextButton(
                child: const Text('Sign out'),
                onPressed: () async {
                  await BackupService.signOut();
                  if (!mounted) return;
                  setState(() {
                    _googleAccount = null;
                    _settings.autoBackup = false;
                  });
                  await _saveSettings();
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: const Text('Back up now'),
              subtitle: Text(_lastBackupLabel ?? 'Never backed up'),
              trailing: _backupInProgress
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.chevron_right),
              onTap: _backupInProgress ? null : () async {
                final messenger = ScaffoldMessenger.of(context);
                setState(() => _backupInProgress = true);
                try {
                  await BackupService.performBackup();
                  if (!mounted) return;
                  setState(() => _lastBackupLabel = _formatDateTime(DateTime.now()));
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Backup completed successfully')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('Backup failed: $e')),
                  );
                } finally {
                  if (mounted) setState(() => _backupInProgress = false);
                }
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.autorenew),
              title: const Text('Automatic backup'),
              value: _settings.autoBackup,
              onChanged: (value) async {
                setState(() => _settings.autoBackup = value);
                await _saveSettings();
              },
            ),
            if (_settings.autoBackup)
              ListTile(
                leading: const SizedBox(width: 24),
                title: const Text('Frequency'),
                subtitle: Text(_settings.backupFrequency == 'daily' ? 'Daily' : 'Weekly'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final selected = await showDialog<String>(
                    context: context,
                    builder: (ctx) => StatefulBuilder(
                      builder: (ctx, setDialogState) => AlertDialog(
                        title: const Text('Backup frequency'),
                        content: RadioGroup<String>(
                          groupValue: _settings.backupFrequency,
                          onChanged: (v) => setDialogState(() {}),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RadioListTile<String>(
                                title: Text('Daily'),
                                value: 'daily',
                              ),
                              RadioListTile<String>(
                                title: Text('Weekly'),
                                value: 'weekly',
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(
                              ctx,
                              _settings.backupFrequency,
                            ),
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ),
                  );
                  if (selected == null || !mounted) return;
                  setState(() => _settings.backupFrequency = selected);
                  await _saveSettings();
                },
              ),
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined),
              title: const Text('Restore from backup'),
              subtitle: const Text('Replaces all current data'),
              trailing: _restoreInProgress
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.chevron_right),
              onTap: _restoreInProgress ? null : () async {
                final messenger = ScaffoldMessenger.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Restore backup?'),
                    content: const Text(
                      'This will replace all your current data with the latest backup. This cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Restore'),
                      ),
                    ],
                  ),
                );
                if (confirm != true) return;
                setState(() => _restoreInProgress = true);
                try {
                  await BackupService.performRestore();
                  if (!mounted) return;
                  _loadSettings();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Restore completed. Please restart the app.')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('Restore failed: $e')),
                  );
                } finally {
                  if (mounted) setState(() => _restoreInProgress = false);
                }
              },
            ),
          ],

          // Estatísticas
          _buildSectionHeader(l10n.statistics),
          ListTile(
            title: Text(l10n.totalEntries),
            subtitle: Text('${HiveService.getTotalEntries()} ${l10n.entries}'),
          ),
          ListTile(
            title: Text(l10n.entriesThisYear),
            subtitle: Text(
              '${HiveService.getEntriesCountForYear(DateTime.now().year)} ${l10n.entries}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  String _getLanguageName(String languageCode, AppLocalizations l10n) {
    // Retornar o nome do idioma baseado no código
    // O l10n já está no idioma correto após o rebuild
    switch (languageCode) {
      case 'en':
        return l10n.languageEnglish;
      case 'pt':
        return l10n.languagePortuguese;
      case 'es':
        return l10n.languageSpanish;
      case 'fr':
        return l10n.languageFrench;
      case 'de':
        return l10n.languageGerman;
      case 'it':
        return l10n.languageItalian;
      default:
        return l10n.languageEnglish;
    }
  }

  String _getThemeName(String themeMode, AppLocalizations l10n) {
    switch (themeMode) {
      case 'light':
        return l10n.themeLight;
      case 'dark':
        return l10n.themeDark;
      case 'system':
      default:
        return l10n.themeSystem;
    }
  }

  String _getTimezoneInfo() {
    try {
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      final offsetHours = offset.inHours;
      final offsetMinutes = (offset.inMinutes % 60).abs();
      
      String offsetString;
      if (offsetHours >= 0) {
        if (offsetMinutes > 0) {
          offsetString = 'UTC+$offsetHours:${offsetMinutes.toString().padLeft(2, '0')}';
        } else {
          offsetString = 'UTC+$offsetHours';
        }
      } else {
        if (offsetMinutes > 0) {
          offsetString = 'UTC$offsetHours:${offsetMinutes.toString().padLeft(2, '0')}';
        } else {
          offsetString = 'UTC$offsetHours';
        }
      }
      
      final timezoneName = now.timeZoneName;
      return '$timezoneName ($offsetString)';
    } catch (e) {
      return 'Timezone: ${DateTime.now().timeZoneName}';
    }
  }
}
