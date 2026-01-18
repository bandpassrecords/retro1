import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:retro1/l10n/app_localizations.dart';
import 'package:retro1/main.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../models/app_settings.dart';
import 'video_generator_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _settings = HiveService.getSettings();
    });
  }

  Future<void> _saveSettings() async {
    await HiveService.saveSettings(_settings);
    await NotificationService.scheduleNotifications();
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsSaved)),
      );
    }
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
          SwitchListTile(
            title: Text(l10n.weeklySummary),
            value: _settings.weeklySummaryEnabled,
            onChanged: (value) {
              setState(() {
                _settings.weeklySummaryEnabled = value;
              });
              _saveSettings();
            },
          ),
          ListTile(
            title: Text(l10n.testNotification),
            subtitle: Text(l10n.testNotificationDescription),
            trailing: const Icon(Icons.notifications_active),
            onTap: () async {
              try {
                await NotificationService.sendTestNotification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.testNotificationSent),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
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
              setState(() {
                _settings.showDateOverlay = value;
              });
              _saveSettings();
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
          SwitchListTile(
            title: Text(l10n.autoExportEndOfYear),
            value: _settings.autoExportYearEnd,
            onChanged: (value) {
              setState(() {
                _settings.autoExportYearEnd = value;
              });
              _saveSettings();
            },
          ),

          // Backup
          _buildSectionHeader(l10n.backup),
          SwitchListTile(
            title: Text(l10n.autoBackup),
            value: _settings.autoBackup,
            onChanged: (value) {
              setState(() {
                _settings.autoBackup = value;
              });
              _saveSettings();
            },
          ),

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
