import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:retro1/l10n/app_localizations.dart';
import '../models/free_project.dart';
import '../services/hive_service.dart';
import 'project_edit_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<FreeProject> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  void _loadProjects() {
    setState(() {
      _projects = HiveService.getAllProjects();
    });
  }

  Future<void> _createNewProject() async {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => _CreateProjectDialog(),
    );

    if (result != null && result['name'] != null && result['name']!.isNotEmpty) {
      final project = FreeProject(
        id: const Uuid().v4(),
        name: result['name']!,
        description: result['description'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await HiveService.saveProject(project);
      _loadProjects();

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectEditScreen(projectId: project.id),
          ),
        );
      }
    }
  }

  Future<void> _deleteProject(FreeProject project) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteProject),
        content: Text(l10n.deleteProjectConfirm(project.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await HiveService.deleteProject(project.id);
      _loadProjects();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.freeProjects),
      ),
      body: _projects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noProjectsYet,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.createFirstProject,
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _projects.length,
              itemBuilder: (context, index) {
                final project = _projects[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.folder, color: Colors.white),
                  ),
                  title: Text(project.name),
                  subtitle: Text(
                    '${project.mediaItemIds.length} ${l10n.items} • ${_formatDate(project.updatedAt, l10n)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteProject(project),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProjectEditScreen(projectId: project.id),
                      ),
                    ).then((_) => _loadProjects());
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewProject,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return l10n.today;
    } else if (difference.inDays == 1) {
      return l10n.yesterday;
    } else if (difference.inDays < 7) {
      return l10n.daysAgo(difference.inDays);
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _CreateProjectDialog extends StatefulWidget {
  @override
  State<_CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<_CreateProjectDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.newProject),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.projectName,
              hintText: l10n.enterProjectName,
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: l10n.descriptionOptional,
              hintText: l10n.enterDescription,
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isNotEmpty) {
              final description = _descriptionController.text.trim();
              Navigator.pop(
                context,
                <String, String?>{
                  'name': name,
                  'description': description.isEmpty ? null : description,
                },
              );
            }
          },
          child: Text(l10n.create),
        ),
      ],
    );
  }
}
