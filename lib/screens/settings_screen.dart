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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas')),
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
          // Idioma
          _buildSectionHeader(l10n.language),
          ListTile(
            title: Text(l10n.appLanguage),
            subtitle: Text(_settings.language == 'en' ? l10n.languageEnglish : l10n.languagePortuguese),
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
                          setState(() {
                            _settings.language = value!;
                          });
                          Navigator.pop(context);
                          await _saveSettings();
                          // Atualizar idioma do app
                          MyApp.updateLanguage();
                        },
                      ),
                      RadioListTile<String>(
                        title: Text(l10n.languagePortuguese),
                        value: 'pt',
                        groupValue: _settings.language,
                        onChanged: (value) async {
                          setState(() {
                            _settings.language = value!;
                          });
                          Navigator.pop(context);
                          await _saveSettings();
                          // Atualizar idioma do app
                          MyApp.updateLanguage();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Notificações
          _buildSectionHeader('Notificações'),
          SwitchListTile(
            title: const Text('Ativar notificações'),
            value: _settings.notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _settings.notificationsEnabled = value;
              });
              _saveSettings();
            },
          ),
          ListTile(
            title: const Text('Horário da notificação'),
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
            title: const Text('Lembrete após (horas)'),
            subtitle: Text('${_settings.reminderDelayHours} horas'),
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
            title: const Text('Resumo semanal'),
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
          _buildSectionHeader('Vídeo'),
          ListTile(
            title: const Text('Qualidade do vídeo'),
            subtitle: Text(_settings.videoQuality),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Qualidade do vídeo'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<String>(
                        title: const Text('720p'),
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
                        title: const Text('1080p'),
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
                        title: const Text('4K'),
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
            title: const Text('Mostrar data no vídeo'),
            value: _settings.showDateOverlay,
            onChanged: (value) {
              setState(() {
                _settings.showDateOverlay = value;
              });
              _saveSettings();
            },
          ),

          // Exportação
          _buildSectionHeader('Exportação'),
          ListTile(
            title: const Text('Gerar vídeos'),
            subtitle: const Text('Gerar vídeos compilados'),
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
            title: const Text('Exportação automática no fim do ano'),
            value: _settings.autoExportYearEnd,
            onChanged: (value) {
              setState(() {
                _settings.autoExportYearEnd = value;
              });
              _saveSettings();
            },
          ),

          // Backup
          _buildSectionHeader('Backup'),
          SwitchListTile(
            title: const Text('Backup automático'),
            value: _settings.autoBackup,
            onChanged: (value) {
              setState(() {
                _settings.autoBackup = value;
              });
              _saveSettings();
            },
          ),

          // Estatísticas
          _buildSectionHeader('Estatísticas'),
          ListTile(
            title: const Text('Total de entradas'),
            subtitle: Text('${HiveService.getTotalEntries()} entradas'),
          ),
          ListTile(
            title: const Text('Entradas deste ano'),
            subtitle: Text(
              '${HiveService.getEntriesCountForYear(DateTime.now().year)} entradas',
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
