import 'package:flutter/material.dart';
import 'package:agentlib/agentlib.dart';

/// Detailed view and configuration for individual agents
class AgentDetailScreen extends StatefulWidget {
  final RepetitiveTaskAgent agent;

  const AgentDetailScreen({Key? key, required this.agent}) : super(key: key);

  @override
  State<AgentDetailScreen> createState() => _AgentDetailScreenState();
}

class _AgentDetailScreenState extends State<AgentDetailScreen> {
  bool _isLoading = false;
  Map<String, dynamic> _agentStats = {};
  List<Map<String, dynamic>> _executionHistory = [];

  @override
  void initState() {
    super.initState();
    _loadAgentData();
  }

  Future<void> _loadAgentData() async {
    setState(() => _isLoading = true);

    try {
      _agentStats = widget.agent.getStats();
      // Load execution history (mock data for now)
      _executionHistory = _generateMockHistory();
    } catch (e) {
      debugPrint('Error loading agent data: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildStatusCard(),
                _buildQuickActions(),
                _buildConfigurationCard(),
                _buildExecutionHistory(),
                _buildAdvancedSettings(),
                const SizedBox(height: 100), // Space for FAB
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildActionButtons(),
    );
  }

  Widget _buildAppBar() {
    final isActive = _agentStats['is_running'] as bool? ?? false;

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _getAgentColor(),
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.agent.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getAgentColor(),
                _getAgentColor().withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _getAgentIcon(),
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 30), // Space for title
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                isActive ? 'Active' : 'Paused',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final executionCount = _agentStats['execution_count'] as int? ?? 0;
    final lastExecution = _agentStats['last_execution'] as String?;
    final intervalHours = _agentStats['interval_hours'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Agent Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.analytics,
                  label: 'Total Runs',
                  value: '$executionCount',
                  color: const Color(0xFF8B5CF6),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.schedule,
                  label: 'Interval',
                  value: '${intervalHours}h',
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatItem(
            icon: Icons.access_time,
            label: 'Last Execution',
            value: lastExecution != null
                ? _formatDateTime(lastExecution)
                : 'Never',
            color: const Color(0xFF10B981),
            fullWidth: true,
          ),
          const SizedBox(height: 16),
          _buildStatItem(
            icon: Icons.description,
            label: 'Description',
            value: 'Automated ${widget.agent.name.toLowerCase()} tasks',
            color: const Color(0xFF6B7280),
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: fullWidth
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Icon(icon, size: 24, color: color),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }

  Widget _buildQuickActions() {
    final isActive = _agentStats['is_running'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: isActive ? Icons.pause_circle : Icons.play_circle,
              label: isActive ? 'Pause Agent' : 'Start Agent',
              color: isActive ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              onTap: () => _toggleAgent(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.play_arrow,
              label: 'Run Now',
              color: const Color(0xFF3B82F6),
              onTap: () => _runAgentNow(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, size: 32, color: color),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigurationCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Configuration',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _editConfiguration,
                child: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildConfigItem(
            icon: Icons.schedule,
            label: 'Run Interval',
            value: _formatInterval(widget.agent.interval),
          ),
          const SizedBox(height: 12),
          _buildConfigItem(
            icon: Icons.calendar_today,
            label: 'Active Days',
            value: _formatActiveDays(widget.agent.activeDays),
          ),
          const SizedBox(height: 12),
          _buildConfigItem(
            icon: Icons.apps,
            label: 'Required Apps',
            value: '${widget.agent.requiredApps.length} apps',
          ),
          const SizedBox(height: 12),
          _buildConfigItem(
            icon: Icons.battery_charging_full,
            label: 'Run on Low Battery',
            value: widget.agent.runOnLowBattery ? 'Yes' : 'No',
          ),
        ],
      ),
    );
  }

  Widget _buildConfigItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildExecutionHistory() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          if (_executionHistory.isEmpty)
            _buildEmptyHistory()
          else
            ..._executionHistory.take(5).map((execution) => _buildHistoryItem(execution)),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'No execution history yet',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> execution) {
    final isSuccess = execution['success'] as bool;
    final timestamp = execution['timestamp'] as DateTime;
    final message = execution['message'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            size: 20,
            color: isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateTime(timestamp.toIso8601String()),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Advanced Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          _buildAdvancedOption(
            icon: Icons.notifications,
            title: 'Notification Settings',
            subtitle: 'Configure when to notify',
            onTap: _configureNotifications,
          ),
          _buildAdvancedOption(
            icon: Icons.data_usage,
            title: 'Data Usage',
            subtitle: 'WiFi only, mobile data settings',
            onTap: _configureDataUsage,
          ),
          _buildAdvancedOption(
            icon: Icons.security,
            title: 'Permissions',
            subtitle: 'Manage app permissions',
            onTap: _managePermissions,
          ),
          _buildAdvancedOption(
            icon: Icons.delete_outline,
            title: 'Remove Agent',
            subtitle: 'Permanently delete this agent',
            onTap: _confirmDeleteAgent,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? const Color(0xFFEF4444) : const Color(0xFF6B7280);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF1F2937),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  Widget _buildActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'test',
          onPressed: _runAgentNow,
          backgroundColor: const Color(0xFF3B82F6),
          child: const Icon(Icons.play_arrow, color: Colors.white),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'settings',
          onPressed: _editConfiguration,
          backgroundColor: const Color(0xFF6B7280),
          child: const Icon(Icons.settings, color: Colors.white),
        ),
      ],
    );
  }

  // Helper methods
  Color _getAgentColor() {
    if (widget.agent.capabilities.contains('social_media')) {
      return const Color(0xFFEF4444);
    } else if (widget.agent.capabilities.contains('communication')) {
      return const Color(0xFF3B82F6);
    } else if (widget.agent.capabilities.contains('shopping')) {
      return const Color(0xFF10B981);
    }
    return const Color(0xFF6366F1);
  }

  IconData _getAgentIcon() {
    if (widget.agent.capabilities.contains('social_media')) {
      return Icons.people;
    } else if (widget.agent.capabilities.contains('communication')) {
      return Icons.email;
    } else if (widget.agent.capabilities.contains('shopping')) {
      return Icons.shopping_bag;
    }
    return Icons.smart_toy;
  }

  String _formatInterval(Duration interval) {
    if (interval.inDays > 0) {
      return 'Every ${interval.inDays} day${interval.inDays > 1 ? 's' : ''}';
    } else if (interval.inHours > 0) {
      return 'Every ${interval.inHours} hour${interval.inHours > 1 ? 's' : ''}';
    } else {
      return 'Every ${interval.inMinutes} minute${interval.inMinutes > 1 ? 's' : ''}';
    }
  }

  String _formatActiveDays(List<int> days) {
    if (days.isEmpty) return 'Every day';
    if (days.length == 7) return 'Every day';

    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((d) => dayNames[d - 1]).join(', ');
  }

  String _formatDateTime(String dateTimeString) {
    final dateTime = DateTime.tryParse(dateTimeString);
    if (dateTime == null) return 'Unknown';

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  List<Map<String, dynamic>> _generateMockHistory() {
    return [
      {
        'success': true,
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        'message': 'Checked 3 Instagram accounts, found 2 new posts',
      },
      {
        'success': true,
        'timestamp': DateTime.now().subtract(const Duration(hours: 8)),
        'message': 'Processed 15 emails, flagged 2 as important',
      },
      {
        'success': false,
        'timestamp': DateTime.now().subtract(const Duration(hours: 14)),
        'message': 'Failed to access WhatsApp - permission denied',
      },
      {
        'success': true,
        'timestamp': DateTime.now().subtract(const Duration(days: 1)),
        'message': 'Price check completed, found 1 deal alert',
      },
    ];
  }

  // Action handlers
  void _toggleAgent() async {
    final isActive = _agentStats['is_running'] as bool? ?? false;

    try {
      await TaskScheduler.instance.setAgentEnabled(widget.agent.id, !isActive);
      await _loadAgentData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Agent ${!isActive ? 'started' : 'paused'} successfully'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to ${!isActive ? 'start' : 'pause'} agent: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _runAgentNow() async {
    setState(() => _isLoading = true);

    try {
      final result = await TaskScheduler.instance.executeAgentNow(widget.agent.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success ? 'Agent executed successfully' : 'Agent execution failed'),
          backgroundColor: result.success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        ),
      );

      await _loadAgentData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to execute agent: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  void _editConfiguration() {
    // Navigate to configuration screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration screen coming soon...')),
    );
  }

  void _configureNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification settings coming soon...')),
    );
  }

  void _configureDataUsage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data usage settings coming soon...')),
    );
  }

  void _managePermissions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Permission management coming soon...')),
    );
  }

  void _confirmDeleteAgent() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Agent'),
        content: Text('Are you sure you want to delete "${widget.agent.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAgent();
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteAgent() async {
    try {
      await TaskScheduler.instance.unregisterAgent(widget.agent.id);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agent deleted successfully'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete agent: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }
}