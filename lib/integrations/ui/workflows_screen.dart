import 'package:flutter/material.dart';
import '../workflow_builder.dart';
import '../app_integration_service.dart';

class WorkflowsScreen extends StatefulWidget {
  @override
  _WorkflowsScreenState createState() => _WorkflowsScreenState();
}

class _WorkflowsScreenState extends State<WorkflowsScreen> {
  final WorkflowBuilder _workflowBuilder = WorkflowBuilder.instance;
  List<AppWorkflow> _savedWorkflows = [];
  List<WorkflowTemplate> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadWorkflows();
  }

  void _loadWorkflows() {
    setState(() {
      _savedWorkflows = _workflowBuilder.savedWorkflows;
      _templates = _workflowBuilder.templates;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Workflows'),
          backgroundColor: Colors.purple[600],
          foregroundColor: Colors.white,
          bottom: TabBar(
            tabs: [
              Tab(text: 'My Workflows'),
              Tab(text: 'Templates'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMyWorkflowsTab(),
            _buildTemplatesTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _createNewWorkflow,
          backgroundColor: Colors.purple[600],
          child: Icon(Icons.add, color: Colors.white),
          tooltip: 'Create Workflow',
        ),
      ),
    );
  }

  Widget _buildMyWorkflowsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_savedWorkflows.isEmpty)
            Center(
              child: Column(
                children: [
                  SizedBox(height: 60),
                  Icon(
                    Icons.auto_awesome,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No workflows yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create a workflow or choose from templates',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          else
            ..._savedWorkflows.map((workflow) => _buildWorkflowCard(workflow)),
        ],
      ),
    );
  }

  Widget _buildTemplatesTab() {
    final categories = _templates.map((t) => t.category).toSet().toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: categories.map((category) {
          final categoryTemplates = _templates.where((t) => t.category == category).toList();
          return _buildTemplateCategory(category, categoryTemplates);
        }).toList(),
      ),
    );
  }

  Widget _buildWorkflowCard(AppWorkflow workflow) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple[100],
          child: Icon(Icons.auto_awesome, color: Colors.purple[600]),
        ),
        title: Text(workflow.name),
        subtitle: Text('${workflow.steps.length} steps'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleWorkflowAction(workflow, value),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'run', child: Text('Run')),
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => _runWorkflow(workflow),
      ),
    );
  }

  Widget _buildTemplateCategory(String category, List<WorkflowTemplate> templates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            category,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        ...templates.map((template) => _buildTemplateCard(template)),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTemplateCard(WorkflowTemplate template) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(Icons.description_outlined, color: Colors.blue[600]),
        ),
        title: Text(template.name),
        subtitle: Text(template.description),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _useTemplate(template),
      ),
    );
  }

  void _handleWorkflowAction(AppWorkflow workflow, String action) async {
    switch (action) {
      case 'run':
        await _runWorkflow(workflow);
        break;
      case 'edit':
        _editWorkflow(workflow);
        break;
      case 'duplicate':
        _duplicateWorkflow(workflow);
        break;
      case 'delete':
        _deleteWorkflow(workflow);
        break;
    }
  }

  Future<void> _runWorkflow(AppWorkflow workflow) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Running workflow...'),
          ],
        ),
      ),
    );

    try {
      final result = await _workflowBuilder.executeWorkflow(workflow.id);
      Navigator.pop(context); // Close loading dialog

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workflow completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workflow failed: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Workflow error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editWorkflow(AppWorkflow workflow) {
    // TODO: Implement workflow editor
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Workflow editor coming soon')),
    );
  }

  void _duplicateWorkflow(AppWorkflow workflow) async {
    final duplicatedWorkflow = AppWorkflow(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${workflow.name} (Copy)',
      steps: workflow.steps,
    );

    await _workflowBuilder.saveWorkflow(duplicatedWorkflow);
    _loadWorkflows();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Workflow duplicated')),
    );
  }

  void _deleteWorkflow(AppWorkflow workflow) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Workflow'),
        content: Text('Are you sure you want to delete "${workflow.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _workflowBuilder.deleteWorkflow(workflow.id);
              _loadWorkflows();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Workflow deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _createNewWorkflow() {
    showDialog(
      context: context,
      builder: (context) {
        String workflowName = '';
        return AlertDialog(
          title: Text('Create New Workflow'),
          content: TextField(
            decoration: InputDecoration(
              hintText: 'Enter workflow name',
            ),
            onChanged: (value) => workflowName = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (workflowName.isNotEmpty) {
                  Navigator.pop(context);
                  _createWorkflow(workflowName);
                }
              },
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _createWorkflow(String name) {
    // TODO: Implement workflow creation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Workflow builder coming soon')),
    );
  }

  void _useTemplate(WorkflowTemplate template) {
    showDialog(
      context: context,
      builder: (context) => _TemplateParametersDialog(
        template: template,
        onUse: (parameters) {
          final editor = _workflowBuilder.createFromTemplate(template.id, parameters);
          editor.save().then((workflow) {
            _loadWorkflows();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Workflow created from template')),
            );
          });
        },
      ),
    );
  }
}

class _TemplateParametersDialog extends StatefulWidget {
  final WorkflowTemplate template;
  final Function(Map<String, dynamic>) onUse;

  _TemplateParametersDialog({
    required this.template,
    required this.onUse,
  });

  @override
  _TemplateParametersDialogState createState() => _TemplateParametersDialogState();
}

class _TemplateParametersDialogState extends State<_TemplateParametersDialog> {
  final Map<String, TextEditingController> _controllers = {};
  final Set<String> _requiredParameters = {};

  @override
  void initState() {
    super.initState();
    _extractParameters();
  }

  void _extractParameters() {
    for (final step in widget.template.steps) {
      step.parameters.forEach((key, value) {
        if (value is String && value.contains('{') && value.contains('}')) {
          final regex = RegExp(r'\{([^}]+)\}');
          final matches = regex.allMatches(value);
          for (final match in matches) {
            final param = match.group(1)!;
            if (!_controllers.containsKey(param) &&
                !param.startsWith('today') &&
                !param.startsWith('tomorrow') &&
                !param.startsWith('user_')) {
              _controllers[param] = TextEditingController();
              _requiredParameters.add(param);
            }
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Configure ${widget.template.name}'),
      content: _controllers.isEmpty
          ? Text('This template is ready to use without additional parameters.')
          : Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _controllers.entries.map((entry) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: TextField(
                      controller: entry.value,
                      decoration: InputDecoration(
                        labelText: entry.key.replaceAll('_', ' ').toUpperCase(),
                        hintText: 'Enter ${entry.key}',
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final parameters = <String, dynamic>{};
            _controllers.forEach((key, controller) {
              parameters[key] = controller.text;
            });

            Navigator.pop(context);
            widget.onUse(parameters);
          },
          child: Text('Create Workflow'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }
}