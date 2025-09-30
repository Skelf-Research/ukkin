import 'package:flutter/material.dart';
import 'package:agentlib/agentlib.dart';
import 'conversational_agent_builder.dart';

/// Main dashboard for managing all repetitive agents
class AgentDashboard extends StatefulWidget {
  const AgentDashboard({Key? key}) : super(key: key);

  @override
  State<AgentDashboard> createState() => _AgentDashboardState();
}

class _AgentDashboardState extends State<AgentDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _systemStats = {};
  List<RepetitiveTaskAgent> _agents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAgentData();
  }

  Future<void> _loadAgentData() async {
    setState(() => _isLoading = true);

    try {
      final scheduler = TaskScheduler.instance;
      _systemStats = scheduler.getStats();
      _agents = scheduler.agents;
    } catch (e) {
      debugPrint('Error loading agent data: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildQuickStats(),
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
      floatingActionButton: _buildQuickActionFAB(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Agents',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  '${_agents.length} agents working for you',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadAgentData,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              foregroundColor: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final activeAgents = _agents.where((a) => _isAgentActive(a)).length;
    final totalExecutions = _systemStats['agents']?.values
        .fold<int>(0, (sum, stats) => sum + (stats['execution_count'] as int? ?? 0)) ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.play_circle_outline,
              label: 'Active',
              value: '$activeAgents',
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.schedule,
              label: 'Scheduled',
              value: '${_systemStats['scheduled_tasks'] ?? 0}',
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.analytics,
              label: 'Executions',
              value: '$totalExecutions',
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
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
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        labelColor: const Color(0xFF6366F1),
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        tabs: const [
          Tab(text: 'All Agents'),
          Tab(text: 'Social'),
          Tab(text: 'Communication'),
          Tab(text: 'Shopping'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildAgentsList(_agents),
        _buildAgentsList(_agents.where((a) => a.capabilities.contains('social_media')).toList()),
        _buildAgentsList(_agents.where((a) => a.capabilities.contains('communication')).toList()),
        _buildAgentsList(_agents.where((a) => a.capabilities.contains('shopping')).toList()),
      ],
    );
  }

  Widget _buildAgentsList(List<RepetitiveTaskAgent> agents) {
    if (agents.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: agents.length,
      itemBuilder: (context, index) {
        final agent = agents[index];
        return _buildAgentCard(agent);
      },
    );
  }

  Widget _buildAgentCard(RepetitiveTaskAgent agent) {
    final stats = agent.getStats();
    final isActive = _isAgentActive(agent);
    final lastExecution = stats['last_execution'] as String?;
    final executionCount = stats['execution_count'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        onTap: () => _showAgentDetails(agent),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  _buildAgentIcon(agent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                agent.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                            _buildStatusBadge(isActive),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          agent.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isActive,
                    onChanged: (value) => _toggleAgent(agent, value),
                    activeColor: const Color(0xFF10B981),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.schedule,
                    label: _formatInterval(agent.interval),
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.analytics,
                    label: '$executionCount runs',
                    color: Colors.purple,
                  ),
                  const Spacer(),
                  if (lastExecution != null)
                    Text(
                      'Last: ${_formatLastExecution(lastExecution)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgentIcon(RepetitiveTaskAgent agent) {
    IconData icon;
    Color color;

    if (agent.capabilities.contains('social_media')) {
      icon = Icons.people;
      color = const Color(0xFFEF4444);
    } else if (agent.capabilities.contains('communication')) {
      icon = Icons.email;
      color = const Color(0xFF3B82F6);
    } else if (agent.capabilities.contains('shopping')) {
      icon = Icons.shopping_bag;
      color = const Color(0xFF10B981);
    } else {
      icon = Icons.smart_toy;
      color = const Color(0xFF6366F1);
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF10B981).withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Active' : 'Paused',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive ? const Color(0xFF10B981) : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No agents in this category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agents will appear here once configured',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionFAB() {
    return FloatingActionButton.extended(
      onPressed: _showQuickActions,
      backgroundColor: const Color(0xFF6366F1),
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'Quick Setup',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildQuickActionsSheet(),
    );
  }

  Widget _buildQuickActionsSheet() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          _buildQuickActionTile(
            icon: Icons.chat_bubble,
            title: 'Create Agent with AI Chat',
            subtitle: 'Describe what you want, AI creates the agent',
            color: const Color(0xFF8B5CF6),
            onTap: () => _openConversationalBuilder(),
          ),
          _buildQuickActionTile(
            icon: Icons.people,
            title: 'Setup Social Media Monitoring',
            subtitle: 'Instagram, Twitter, LinkedIn agents',
            color: const Color(0xFFEF4444),
            onTap: () => _setupSocialMediaAgents(),
          ),
          _buildQuickActionTile(
            icon: Icons.email,
            title: 'Setup Communication Management',
            subtitle: 'Email, WhatsApp, SMS automation',
            color: const Color(0xFF3B82F6),
            onTap: () => _setupCommunicationAgents(),
          ),
          _buildQuickActionTile(
            icon: Icons.shopping_bag,
            title: 'Setup Shopping Automation',
            subtitle: 'Price tracking, deals, expenses',
            color: const Color(0xFF10B981),
            onTap: () => _setupShoppingAgents(),
          ),
          _buildQuickActionTile(
            icon: Icons.settings,
            title: 'Advanced Configuration',
            subtitle: 'Custom schedules and conditions',
            color: const Color(0xFF6366F1),
            onTap: () => _showAdvancedConfig(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
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
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _showAgentDetails(RepetitiveTaskAgent agent) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgentDetailScreen(agent: agent),
      ),
    );
  }

  void _toggleAgent(RepetitiveTaskAgent agent, bool enabled) async {
    try {
      await TaskScheduler.instance.setAgentEnabled(agent.id, enabled);
      await _loadAgentData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to ${enabled ? 'enable' : 'disable'} agent: $e')),
      );
    }
  }

  void _openConversationalBuilder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConversationalAgentBuilder(),
      ),
    ).then((_) => _loadAgentData()); // Refresh agent list when returning
  }

  void _setupSocialMediaAgents() {
    // Navigate to social media setup wizard
  }

  void _setupCommunicationAgents() {
    // Navigate to communication setup wizard
  }

  void _setupShoppingAgents() {
    // Navigate to shopping setup wizard
  }

  void _showAdvancedConfig() {
    // Navigate to advanced configuration screen
  }

  bool _isAgentActive(RepetitiveTaskAgent agent) {
    final stats = agent.getStats();
    return stats['is_running'] as bool? ?? false;
  }

  String _formatInterval(Duration interval) {
    if (interval.inDays > 0) {
      return '${interval.inDays}d';
    } else if (interval.inHours > 0) {
      return '${interval.inHours}h';
    } else {
      return '${interval.inMinutes}m';
    }
  }

  String _formatLastExecution(String lastExecution) {
    final date = DateTime.tryParse(lastExecution);
    if (date == null) return 'Never';

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

/// Placeholder for agent detail screen
class AgentDetailScreen extends StatelessWidget {
  final RepetitiveTaskAgent agent;

  const AgentDetailScreen({Key? key, required this.agent}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(agent.name),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Agent details coming soon...'),
      ),
    );
  }
}