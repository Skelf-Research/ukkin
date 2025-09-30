import 'package:flutter/material.dart';
import '../app_integration_service.dart';

class AppIntegrationsScreen extends StatefulWidget {
  @override
  _AppIntegrationsScreenState createState() => _AppIntegrationsScreenState();
}

class _AppIntegrationsScreenState extends State<AppIntegrationsScreen> {
  final AppIntegrationService _integrationService = AppIntegrationService.instance;
  List<AppIntegration> _availableIntegrations = [];
  List<AppIntegration> _activeIntegrations = [];

  @override
  void initState() {
    super.initState();
    _loadIntegrations();
  }

  void _loadIntegrations() {
    setState(() {
      _availableIntegrations = _integrationService.availableIntegrations;
      _activeIntegrations = _integrationService.activeIntegrations;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('App Integrations'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActiveIntegrationsSection(),
            SizedBox(height: 24),
            _buildAvailableIntegrationsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveIntegrationsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Integrations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            if (_activeIntegrations.isEmpty)
              Text(
                'No active integrations. Enable some apps below to get started.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ..._activeIntegrations.map((integration) => _buildActiveIntegrationCard(integration)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveIntegrationCard(AppIntegration integration) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Icon(Icons.check, color: Colors.green[600]),
        ),
        title: Text(integration.displayName),
        subtitle: Text('${integration.supportedActions.length} actions available'),
        trailing: IconButton(
          icon: Icon(Icons.settings),
          onPressed: () => _showIntegrationSettings(integration),
        ),
      ),
    );
  }

  Widget _buildAvailableIntegrationsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Integrations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ..._availableIntegrations.map((integration) => _buildAvailableIntegrationCard(integration)),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableIntegrationCard(AppIntegration integration) {
    final isActive = _integrationService.isIntegrationActive(integration.appId);
    final isInstalled = integration.isInstalled;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive
              ? Colors.green[100]
              : isInstalled
                  ? Colors.blue[100]
                  : Colors.grey[100],
          child: Icon(
            isActive
                ? Icons.check
                : isInstalled
                    ? Icons.apps
                    : Icons.download,
            color: isActive
                ? Colors.green[600]
                : isInstalled
                    ? Colors.blue[600]
                    : Colors.grey[600],
          ),
        ),
        title: Text(integration.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(integration.description),
            if (!isInstalled)
              Text(
                'App not installed',
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: isInstalled
            ? Switch(
                value: isActive,
                onChanged: (value) => _toggleIntegration(integration, value),
              )
            : TextButton(
                onPressed: () => _installApp(integration),
                child: Text('Install'),
              ),
      ),
    );
  }

  void _toggleIntegration(AppIntegration integration, bool enable) async {
    if (enable) {
      final success = await _integrationService.activateIntegration(integration.appId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${integration.displayName} integration activated')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to activate ${integration.displayName}')),
        );
      }
    } else {
      await _integrationService.deactivateIntegration(integration.appId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${integration.displayName} integration deactivated')),
      );
    }
    _loadIntegrations();
  }

  void _installApp(AppIntegration integration) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Install ${integration.displayName}'),
        content: Text('This will redirect you to the app store to install ${integration.displayName}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Open app store
            },
            child: Text('Install'),
          ),
        ],
      ),
    );
  }

  void _showIntegrationSettings(AppIntegration integration) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${integration.displayName} Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Supported Actions:'),
            SizedBox(height: 8),
            ...integration.supportedActions.map((action) => Padding(
              padding: EdgeInsets.only(left: 16, bottom: 4),
              child: Text('• $action'),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleIntegration(integration, false);
            },
            child: Text('Disable'),
          ),
        ],
      ),
    );
  }
}