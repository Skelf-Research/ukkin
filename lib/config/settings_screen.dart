import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_config.dart';
import 'config_manager.dart';

/// Main settings screen for app configuration
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ConfigManager _configManager = ConfigManager.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'export', child: Text('Export Config')),
              const PopupMenuItem(value: 'import', child: Text('Import Config')),
              const PopupMenuItem(value: 'reset', child: Text('Reset to Defaults')),
            ],
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _configManager,
        builder: (context, _) {
          final config = _configManager.config;
          return ListView(
            children: [
              _buildModelSection(config.model),
              _buildAutomationSection(config.automation),
              _buildPrivacySection(config.privacy),
              _buildNotificationSection(config.notifications),
              _buildAgentSection(config.agents),
              _buildUISection(config.ui),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelSection(ModelConfig model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Model Settings', Icons.memory),
        ListTile(
          title: const Text('Model Name'),
          subtitle: Text(model.modelName),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showModelNameDialog(model),
        ),
        SwitchListTile(
          title: const Text('Use GPU Acceleration'),
          subtitle: const Text('Faster inference when available'),
          value: model.useGPU,
          onChanged: (value) {
            _configManager.updateModel(model.copyWith(useGPU: value));
          },
        ),
        ListTile(
          title: const Text('Context Length'),
          subtitle: Text('${model.contextLength} tokens'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showSliderDialog(
            'Context Length',
            model.contextLength.toDouble(),
            512,
            8192,
            (value) => _configManager.updateModel(
              model.copyWith(contextLength: value.toInt()),
            ),
          ),
        ),
        ListTile(
          title: const Text('Temperature'),
          subtitle: Text(model.temperature.toStringAsFixed(2)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showSliderDialog(
            'Temperature',
            model.temperature,
            0.0,
            2.0,
            (value) => _configManager.updateModel(
              model.copyWith(temperature: value),
            ),
            divisions: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildAutomationSection(AutomationConfig automation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Automation', Icons.auto_awesome),
        SwitchListTile(
          title: const Text('Require Confirmation'),
          subtitle: const Text('Ask before executing actions'),
          value: automation.requireConfirmation,
          onChanged: (value) {
            _configManager.updateAutomation(
              AutomationConfig(
                requireConfirmation: value,
                confirmationTimeoutSeconds: automation.confirmationTimeoutSeconds,
                allowBackgroundExecution: automation.allowBackgroundExecution,
                maxConcurrentAgents: automation.maxConcurrentAgents,
                respectBatteryOptimization: automation.respectBatteryOptimization,
                minBatteryPercent: automation.minBatteryPercent,
                wifiOnlyForHeavyTasks: automation.wifiOnlyForHeavyTasks,
              ),
            );
          },
        ),
        SwitchListTile(
          title: const Text('Background Execution'),
          subtitle: const Text('Run agents when app is in background'),
          value: automation.allowBackgroundExecution,
          onChanged: (value) {
            _configManager.updateAutomation(
              AutomationConfig(
                requireConfirmation: automation.requireConfirmation,
                confirmationTimeoutSeconds: automation.confirmationTimeoutSeconds,
                allowBackgroundExecution: value,
                maxConcurrentAgents: automation.maxConcurrentAgents,
                respectBatteryOptimization: automation.respectBatteryOptimization,
                minBatteryPercent: automation.minBatteryPercent,
                wifiOnlyForHeavyTasks: automation.wifiOnlyForHeavyTasks,
              ),
            );
          },
        ),
        SwitchListTile(
          title: const Text('Battery Optimization'),
          subtitle: Text('Pause when battery below ${automation.minBatteryPercent}%'),
          value: automation.respectBatteryOptimization,
          onChanged: (value) {
            _configManager.updateAutomation(
              AutomationConfig(
                requireConfirmation: automation.requireConfirmation,
                confirmationTimeoutSeconds: automation.confirmationTimeoutSeconds,
                allowBackgroundExecution: automation.allowBackgroundExecution,
                maxConcurrentAgents: automation.maxConcurrentAgents,
                respectBatteryOptimization: value,
                minBatteryPercent: automation.minBatteryPercent,
                wifiOnlyForHeavyTasks: automation.wifiOnlyForHeavyTasks,
              ),
            );
          },
        ),
        SwitchListTile(
          title: const Text('WiFi Only for Heavy Tasks'),
          subtitle: const Text('Use WiFi for data-intensive operations'),
          value: automation.wifiOnlyForHeavyTasks,
          onChanged: (value) {
            _configManager.updateAutomation(
              AutomationConfig(
                requireConfirmation: automation.requireConfirmation,
                confirmationTimeoutSeconds: automation.confirmationTimeoutSeconds,
                allowBackgroundExecution: automation.allowBackgroundExecution,
                maxConcurrentAgents: automation.maxConcurrentAgents,
                respectBatteryOptimization: automation.respectBatteryOptimization,
                minBatteryPercent: automation.minBatteryPercent,
                wifiOnlyForHeavyTasks: value,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPrivacySection(PrivacyConfig privacy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Privacy & Security', Icons.security),
        SwitchListTile(
          title: const Text('Local Processing Only'),
          subtitle: const Text('All AI runs on-device'),
          value: privacy.localProcessingOnly,
          onChanged: null, // Always enabled
        ),
        SwitchListTile(
          title: const Text('Encrypt Local Data'),
          subtitle: const Text('Secure storage for sensitive data'),
          value: privacy.encryptLocalData,
          onChanged: (value) {
            _configManager.updatePrivacy(
              PrivacyConfig(
                localProcessingOnly: privacy.localProcessingOnly,
                encryptLocalData: value,
                anonymizeAnalytics: privacy.anonymizeAnalytics,
                dataRetentionDays: privacy.dataRetentionDays,
                allowScreenCapture: privacy.allowScreenCapture,
                sensitiveAppPackages: privacy.sensitiveAppPackages,
              ),
            );
          },
        ),
        ListTile(
          title: const Text('Data Retention'),
          subtitle: Text('${privacy.dataRetentionDays} days'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showSliderDialog(
            'Data Retention (days)',
            privacy.dataRetentionDays.toDouble(),
            7,
            365,
            (value) => _configManager.updatePrivacy(
              PrivacyConfig(
                localProcessingOnly: privacy.localProcessingOnly,
                encryptLocalData: privacy.encryptLocalData,
                anonymizeAnalytics: privacy.anonymizeAnalytics,
                dataRetentionDays: value.toInt(),
                allowScreenCapture: privacy.allowScreenCapture,
                sensitiveAppPackages: privacy.sensitiveAppPackages,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSection(NotificationConfig notifications) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Notifications', Icons.notifications),
        SwitchListTile(
          title: const Text('Enable Notifications'),
          value: notifications.enableNotifications,
          onChanged: (value) {
            _configManager.updateNotifications(
              NotificationConfig(
                enableNotifications: value,
                showAgentProgress: notifications.showAgentProgress,
                showTaskCompletion: notifications.showTaskCompletion,
                showErrors: notifications.showErrors,
                quietHoursEnabled: notifications.quietHoursEnabled,
                quietHoursStart: notifications.quietHoursStart,
                quietHoursEnd: notifications.quietHoursEnd,
                vibrateOnComplete: notifications.vibrateOnComplete,
              ),
            );
          },
        ),
        SwitchListTile(
          title: const Text('Show Agent Progress'),
          value: notifications.showAgentProgress,
          onChanged: notifications.enableNotifications
              ? (value) {
                  _configManager.updateNotifications(
                    NotificationConfig(
                      enableNotifications: notifications.enableNotifications,
                      showAgentProgress: value,
                      showTaskCompletion: notifications.showTaskCompletion,
                      showErrors: notifications.showErrors,
                      quietHoursEnabled: notifications.quietHoursEnabled,
                      quietHoursStart: notifications.quietHoursStart,
                      quietHoursEnd: notifications.quietHoursEnd,
                      vibrateOnComplete: notifications.vibrateOnComplete,
                    ),
                  );
                }
              : null,
        ),
        SwitchListTile(
          title: const Text('Quiet Hours'),
          subtitle: Text(notifications.quietHoursEnabled
              ? '${notifications.quietHoursStart}:00 - ${notifications.quietHoursEnd}:00'
              : 'Disabled'),
          value: notifications.quietHoursEnabled,
          onChanged: (value) {
            _configManager.updateNotifications(
              NotificationConfig(
                enableNotifications: notifications.enableNotifications,
                showAgentProgress: notifications.showAgentProgress,
                showTaskCompletion: notifications.showTaskCompletion,
                showErrors: notifications.showErrors,
                quietHoursEnabled: value,
                quietHoursStart: notifications.quietHoursStart,
                quietHoursEnd: notifications.quietHoursEnd,
                vibrateOnComplete: notifications.vibrateOnComplete,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAgentSection(AgentConfig agents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Agent Behavior', Icons.smart_toy),
        SwitchListTile(
          title: const Text('Auto-start on Boot'),
          subtitle: const Text('Resume agents when device restarts'),
          value: agents.autoStartOnBoot,
          onChanged: (value) {
            _configManager.updateAgents(
              AgentConfig(
                autoStartOnBoot: value,
                learnFromFeedback: agents.learnFromFeedback,
                memoryRetentionDays: agents.memoryRetentionDays,
                shareMemoryAcrossAgents: agents.shareMemoryAcrossAgents,
                enabledAgentTypes: agents.enabledAgentTypes,
              ),
            );
          },
        ),
        SwitchListTile(
          title: const Text('Learn from Feedback'),
          subtitle: const Text('Improve based on your corrections'),
          value: agents.learnFromFeedback,
          onChanged: (value) {
            _configManager.updateAgents(
              AgentConfig(
                autoStartOnBoot: agents.autoStartOnBoot,
                learnFromFeedback: value,
                memoryRetentionDays: agents.memoryRetentionDays,
                shareMemoryAcrossAgents: agents.shareMemoryAcrossAgents,
                enabledAgentTypes: agents.enabledAgentTypes,
              ),
            );
          },
        ),
        SwitchListTile(
          title: const Text('Share Memory'),
          subtitle: const Text('Agents learn from each other'),
          value: agents.shareMemoryAcrossAgents,
          onChanged: (value) {
            _configManager.updateAgents(
              AgentConfig(
                autoStartOnBoot: agents.autoStartOnBoot,
                learnFromFeedback: agents.learnFromFeedback,
                memoryRetentionDays: agents.memoryRetentionDays,
                shareMemoryAcrossAgents: value,
                enabledAgentTypes: agents.enabledAgentTypes,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUISection(UIConfig ui) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Appearance', Icons.palette),
        ListTile(
          title: const Text('Theme'),
          subtitle: Text(ui.themeMode.substring(0, 1).toUpperCase() +
              ui.themeMode.substring(1)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showThemeDialog(ui),
        ),
        SwitchListTile(
          title: const Text('Compact Mode'),
          subtitle: const Text('Denser UI layout'),
          value: ui.compactMode,
          onChanged: (value) {
            _configManager.updateUI(
              UIConfig(
                themeMode: ui.themeMode,
                compactMode: value,
                showAdvancedOptions: ui.showAdvancedOptions,
                hapticFeedback: ui.hapticFeedback,
                textScale: ui.textScale,
                accentColor: ui.accentColor,
              ),
            );
          },
        ),
        SwitchListTile(
          title: const Text('Haptic Feedback'),
          value: ui.hapticFeedback,
          onChanged: (value) {
            _configManager.updateUI(
              UIConfig(
                themeMode: ui.themeMode,
                compactMode: ui.compactMode,
                showAdvancedOptions: ui.showAdvancedOptions,
                hapticFeedback: value,
                textScale: ui.textScale,
                accentColor: ui.accentColor,
              ),
            );
          },
        ),
        SwitchListTile(
          title: const Text('Show Advanced Options'),
          subtitle: const Text('Display developer features'),
          value: ui.showAdvancedOptions,
          onChanged: (value) {
            _configManager.updateUI(
              UIConfig(
                themeMode: ui.themeMode,
                compactMode: ui.compactMode,
                showAdvancedOptions: value,
                hapticFeedback: ui.hapticFeedback,
                textScale: ui.textScale,
                accentColor: ui.accentColor,
              ),
            );
          },
        ),
      ],
    );
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'export':
        final result = await _configManager.exportConfig();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message)),
          );
        }
        break;
      case 'import':
        _showImportDialog();
        break;
      case 'reset':
        _showResetConfirmation();
        break;
    }
  }

  void _showModelNameDialog(ModelConfig model) {
    final controller = TextEditingController(text: model.modelName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Model Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter model name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _configManager.updateModel(model.copyWith(modelName: controller.text));
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSliderDialog(
    String title,
    double currentValue,
    double min,
    double max,
    Function(double) onChanged, {
    int? divisions,
  }) {
    double value = currentValue;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                divisions != null
                    ? value.toStringAsFixed(2)
                    : value.toInt().toString(),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions ?? (max - min).toInt(),
                onChanged: (v) => setState(() => value = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                onChanged(value);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(UIConfig ui) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Theme'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              _configManager.updateUI(UIConfig(
                themeMode: 'system',
                compactMode: ui.compactMode,
                showAdvancedOptions: ui.showAdvancedOptions,
                hapticFeedback: ui.hapticFeedback,
                textScale: ui.textScale,
                accentColor: ui.accentColor,
              ));
              Navigator.pop(context);
            },
            child: const Text('System Default'),
          ),
          SimpleDialogOption(
            onPressed: () {
              _configManager.updateUI(UIConfig(
                themeMode: 'light',
                compactMode: ui.compactMode,
                showAdvancedOptions: ui.showAdvancedOptions,
                hapticFeedback: ui.hapticFeedback,
                textScale: ui.textScale,
                accentColor: ui.accentColor,
              ));
              Navigator.pop(context);
            },
            child: const Text('Light'),
          ),
          SimpleDialogOption(
            onPressed: () {
              _configManager.updateUI(UIConfig(
                themeMode: 'dark',
                compactMode: ui.compactMode,
                showAdvancedOptions: ui.showAdvancedOptions,
                hapticFeedback: ui.hapticFeedback,
                textScale: ui.textScale,
                accentColor: ui.accentColor,
              ));
              Navigator.pop(context);
            },
            child: const Text('Dark'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Configuration'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Paste configuration JSON here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final result = await _configManager.importFromString(controller.text);
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result.message)),
                );
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults?'),
        content: const Text(
          'This will reset all settings to their default values. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _configManager.resetToDefaults();
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings reset to defaults')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
