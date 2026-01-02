import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/material.dart' as flutter show TimeOfDay;

/// Wizard for setting up different types of agents
class AgentSetupWizard extends StatefulWidget {
  final AgentType agentType;

  const AgentSetupWizard({Key? key, required this.agentType}) : super(key: key);

  @override
  State<AgentSetupWizard> createState() => _AgentSetupWizardState();
}

enum AgentType { socialMedia, communication, shopping }

class _AgentSetupWizardState extends State<AgentSetupWizard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Map<String, dynamic> _configuration = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Setup ${_getAgentTypeName()} Agent'),
        backgroundColor: _getAgentColor(),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: _buildPages(),
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final totalPages = _getTotalPages();

    return Container(
      padding: const EdgeInsets.all(16),
      color: _getAgentColor(),
      child: Column(
        children: [
          Row(
            children: List.generate(totalPages, (index) {
              final isCompleted = index < _currentPage;
              final isCurrent = index == _currentPage;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < totalPages - 1 ? 8 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            'Step ${_currentPage + 1} of $totalPages',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPages() {
    switch (widget.agentType) {
      case AgentType.socialMedia:
        return _buildSocialMediaPages();
      case AgentType.communication:
        return _buildCommunicationPages();
      case AgentType.shopping:
        return _buildShoppingPages();
    }
  }

  List<Widget> _buildSocialMediaPages() {
    return [
      _buildWelcomePage(
        icon: Icons.people,
        title: 'Social Media Monitoring',
        subtitle: 'Keep track of your social presence automatically',
        description: 'Monitor Instagram accounts, Twitter mentions, LinkedIn updates, and more. Get notified about important social media activity.',
      ),
      _buildMultiSelectPage(
        title: 'Select Platforms',
        subtitle: 'Choose which social media platforms to monitor',
        options: [
          {'id': 'instagram', 'name': 'Instagram', 'icon': Icons.photo_camera},
          {'id': 'twitter', 'name': 'Twitter/X', 'icon': Icons.alternate_email},
          {'id': 'linkedin', 'name': 'LinkedIn', 'icon': Icons.business},
          {'id': 'facebook', 'name': 'Facebook', 'icon': Icons.facebook},
        ],
        configKey: 'platforms',
      ),
      _buildTextListPage(
        title: 'Accounts to Monitor',
        subtitle: 'Add usernames or accounts you want to track',
        hint: 'Enter username (e.g., @competitor, @influencer)',
        configKey: 'accounts',
      ),
      _buildTextListPage(
        title: 'Keywords & Hashtags',
        subtitle: 'Track mentions of specific keywords or hashtags',
        hint: 'Enter keyword or hashtag (e.g., #AI, your brand name)',
        configKey: 'keywords',
      ),
      _buildSchedulePage(
        title: 'Monitoring Schedule',
        subtitle: 'How often should we check for updates?',
        defaultInterval: 2,
      ),
      _buildSummaryPage(),
    ];
  }

  List<Widget> _buildCommunicationPages() {
    return [
      _buildWelcomePage(
        icon: Icons.email,
        title: 'Communication Automation',
        subtitle: 'Automatically organize your messages and emails',
        description: 'Smart email filtering, WhatsApp management, SMS organization, and auto-replies when you\'re busy.',
      ),
      _buildMultiSelectPage(
        title: 'Select Apps',
        subtitle: 'Choose which communication apps to manage',
        options: [
          {'id': 'gmail', 'name': 'Gmail', 'icon': Icons.email},
          {'id': 'whatsapp', 'name': 'WhatsApp', 'icon': Icons.chat},
          {'id': 'sms', 'name': 'SMS Messages', 'icon': Icons.sms},
          {'id': 'telegram', 'name': 'Telegram', 'icon': Icons.send},
        ],
        configKey: 'apps',
      ),
      _buildTextListPage(
        title: 'Important Contacts',
        subtitle: 'Emails/contacts that should be prioritized',
        hint: 'Enter email or contact name',
        configKey: 'important_contacts',
      ),
      _buildTextListPage(
        title: 'Auto-Reply Messages',
        subtitle: 'Set up automatic responses',
        hint: 'Enter: trigger_word = response message',
        configKey: 'auto_replies',
      ),
      _buildTogglePage(
        title: 'Automation Options',
        subtitle: 'Choose what to automate',
        options: [
          {'id': 'archive_old', 'name': 'Archive old messages', 'description': 'Automatically archive messages older than 30 days'},
          {'id': 'delete_spam', 'name': 'Delete spam', 'description': 'Remove suspected spam messages'},
          {'id': 'organize_folders', 'name': 'Organize into folders', 'description': 'Sort messages by type (work, personal, etc.)'},
          {'id': 'calendar_events', 'name': 'Create calendar events', 'description': 'Add meetings from emails to calendar'},
        ],
        configKey: 'automation_options',
      ),
      _buildSchedulePage(
        title: 'Processing Schedule',
        subtitle: 'How often should we organize your messages?',
        defaultInterval: 4,
      ),
      _buildSummaryPage(),
    ];
  }

  List<Widget> _buildShoppingPages() {
    return [
      _buildWelcomePage(
        icon: Icons.shopping_bag,
        title: 'Shopping Automation',
        subtitle: 'Never miss a deal or price drop again',
        description: 'Track prices, hunt for deals, monitor wishlists, and manage your shopping budget automatically.',
      ),
      _buildMultiSelectPage(
        title: 'Shopping Platforms',
        subtitle: 'Choose which apps to monitor',
        options: [
          {'id': 'amazon', 'name': 'Amazon', 'icon': Icons.shopping_cart},
          {'id': 'flipkart', 'name': 'Flipkart', 'icon': Icons.local_mall},
          {'id': 'myntra', 'name': 'Myntra', 'icon': Icons.checkroom},
          {'id': 'ebay', 'name': 'eBay', 'icon': Icons.gavel},
        ],
        configKey: 'platforms',
      ),
      _buildTextListPage(
        title: 'Products to Track',
        subtitle: 'Add products you want price alerts for',
        hint: 'Enter product name or URL',
        configKey: 'products',
      ),
      _buildMultiSelectPage(
        title: 'Deal Categories',
        subtitle: 'Which categories interest you?',
        options: [
          {'id': 'electronics', 'name': 'Electronics', 'icon': Icons.devices},
          {'id': 'fashion', 'name': 'Fashion', 'icon': Icons.checkroom},
          {'id': 'books', 'name': 'Books', 'icon': Icons.book},
          {'id': 'home', 'name': 'Home & Kitchen', 'icon': Icons.home},
          {'id': 'sports', 'name': 'Sports & Fitness', 'icon': Icons.fitness_center},
          {'id': 'beauty', 'name': 'Beauty & Health', 'icon': Icons.spa},
        ],
        configKey: 'categories',
      ),
      _buildNumberInputPage(
        title: 'Budget Settings',
        subtitle: 'Set your shopping preferences',
        fields: [
          {'key': 'max_budget', 'label': 'Maximum budget per item', 'hint': '5000', 'prefix': '₹'},
          {'key': 'min_discount', 'label': 'Minimum discount to notify', 'hint': '20', 'suffix': '%'},
        ],
      ),
      _buildSchedulePage(
        title: 'Check Schedule',
        subtitle: 'How often should we check for deals?',
        defaultInterval: 6,
      ),
      _buildSummaryPage(),
    ];
  }

  Widget _buildWelcomePage({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: _getAgentColor().withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 60,
              color: _getAgentColor(),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          _buildFeatureList(),
        ],
      ),
    );
  }

  Widget _buildFeatureList() {
    final features = _getFeatures();

    return Column(
      children: features.map((feature) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: _getAgentColor(),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                feature,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildMultiSelectPage({
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> options,
    required String configKey,
  }) {
    final selectedItems = _configuration[configKey] as List<String>? ?? [];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = selectedItems.contains(option['id']);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedItems.remove(option['id']);
                      } else {
                        selectedItems.add(option['id']);
                      }
                      _configuration[configKey] = selectedItems;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? _getAgentColor().withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? _getAgentColor() : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          option['icon'] as IconData,
                          size: 40,
                          color: isSelected ? _getAgentColor() : Colors.grey[600],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          option['name'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? _getAgentColor() : Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (isSelected)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getAgentColor(),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Selected',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextListPage({
    required String title,
    required String subtitle,
    required String hint,
    required String configKey,
  }) {
    final items = _configuration[configKey] as List<String>? ?? [];
    final textController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    hintText: hint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _getAgentColor(), width: 2),
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      setState(() {
                        items.add(value.trim());
                        _configuration[configKey] = items;
                        textController.clear();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              FloatingActionButton(
                onPressed: () {
                  final value = textController.text.trim();
                  if (value.isNotEmpty) {
                    setState(() {
                      items.add(value);
                      _configuration[configKey] = items;
                      textController.clear();
                    });
                  }
                },
                backgroundColor: _getAgentColor(),
                mini: true,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (items.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            items[index],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              items.removeAt(index);
                              _configuration[configKey] = items;
                            });
                          },
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.grey[600],
                          iconSize: 20,
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          else
            Expanded(
              child: Center(
                child: Text(
                  'No items added yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTogglePage({
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> options,
    required String configKey,
  }) {
    final selectedOptions = _configuration[configKey] as List<String>? ?? [];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = selectedOptions.contains(option['id']);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SwitchListTile(
                    title: Text(
                      option['name'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    subtitle: Text(
                      option['description'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value) {
                          selectedOptions.add(option['id']);
                        } else {
                          selectedOptions.remove(option['id']);
                        }
                        _configuration[configKey] = selectedOptions;
                      });
                    },
                    activeColor: _getAgentColor(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInputPage({
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> fields,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ...fields.map((field) => Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field['label'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: field['hint'] as String?,
                    prefixText: field['prefix'] as String?,
                    suffixText: field['suffix'] as String?,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _getAgentColor(), width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    _configuration[field['key']] = double.tryParse(value) ?? 0.0;
                  },
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildSchedulePage({
    required String title,
    required String subtitle,
    required int defaultInterval,
  }) {
    final currentInterval = _configuration['interval_hours'] as int? ?? defaultInterval;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Check every $currentInterval hour${currentInterval > 1 ? 's' : ''}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Slider(
            value: currentInterval.toDouble(),
            min: 1,
            max: 24,
            divisions: 23,
            activeColor: _getAgentColor(),
            onChanged: (value) {
              setState(() {
                _configuration['interval_hours'] = value.round();
              });
            },
          ),
          const SizedBox(height: 32),
          _buildTimePreferences(),
        ],
      ),
    );
  }

  Widget _buildTimePreferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preferred Time (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Run at specific time'),
                value: _configuration['use_preferred_time'] as bool? ?? false,
                onChanged: (value) {
                  setState(() {
                    _configuration['use_preferred_time'] = value;
                  });
                },
                activeColor: _getAgentColor(),
                contentPadding: EdgeInsets.zero,
              ),
              if (_configuration['use_preferred_time'] == true) ...[
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Time'),
                  subtitle: Text(_configuration['preferred_time'] as String? ?? '9:00 AM'),
                  trailing: const Icon(Icons.access_time),
                  onTap: _selectTime,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ready to Create Agent',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Review your configuration and create the agent',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: _buildConfigurationSummary(),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuration Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _getAgentColor(),
            ),
          ),
          const SizedBox(height: 16),
          ..._configuration.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatConfigKey(entry.key)}:',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatConfigValue(entry.value),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final totalPages = _getTotalPages();
    final isLastPage = _currentPage == totalPages - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: _getAgentColor()),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(color: _getAgentColor()),
                ),
              ),
            )
          else
            const Expanded(child: SizedBox()),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isLastPage ? _createAgent : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: _getAgentColor(),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                isLastPage ? 'Create Agent' : 'Continue',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getAgentTypeName() {
    switch (widget.agentType) {
      case AgentType.socialMedia:
        return 'Social Media';
      case AgentType.communication:
        return 'Communication';
      case AgentType.shopping:
        return 'Shopping';
    }
  }

  Color _getAgentColor() {
    switch (widget.agentType) {
      case AgentType.socialMedia:
        return const Color(0xFFEF4444);
      case AgentType.communication:
        return const Color(0xFF3B82F6);
      case AgentType.shopping:
        return const Color(0xFF10B981);
    }
  }

  List<String> _getFeatures() {
    switch (widget.agentType) {
      case AgentType.socialMedia:
        return [
          'Monitor competitor accounts automatically',
          'Track hashtags and keywords',
          'Get alerts for important mentions',
          'Save content before it expires',
        ];
      case AgentType.communication:
        return [
          'Smart email organization and filtering',
          'Automatic spam and newsletter management',
          'WhatsApp and SMS automation',
          'Auto-reply when you\'re busy',
        ];
      case AgentType.shopping:
        return [
          'Track prices across multiple platforms',
          'Get instant deal alerts',
          'Monitor your budget automatically',
          'Never miss a price drop again',
        ];
    }
  }

  int _getTotalPages() {
    switch (widget.agentType) {
      case AgentType.socialMedia:
        return 6;
      case AgentType.communication:
        return 7;
      case AgentType.shopping:
        return 7;
    }
  }

  String _formatConfigKey(String key) {
    return key.replaceAll('_', ' ').split(' ').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  String _formatConfigValue(dynamic value) {
    if (value is List) {
      return value.isEmpty ? 'None' : value.join(', ');
    }
    return value.toString();
  }

  void _nextPage() {
    if (_currentPage < _getTotalPages() - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: flutter.TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        _configuration['preferred_time'] = time.format(context);
      });
    }
  }

  void _createAgent() async {
    try {
      // Create agent based on type and configuration
      // This would integrate with AgentLib to create the actual agent

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_getAgentTypeName()} agent created successfully!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );

      Navigator.pop(context, true); // Return success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create agent: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}