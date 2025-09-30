import 'package:flutter/material.dart';
import '../../platform/platform_manager.dart';
import '../../platform/performance_optimizer.dart';
import '../../platform/network_optimizer.dart';

class PerformanceSettingsScreen extends StatefulWidget {
  @override
  _PerformanceSettingsScreenState createState() => _PerformanceSettingsScreenState();
}

class _PerformanceSettingsScreenState extends State<PerformanceSettingsScreen> {
  final PlatformManager _platformManager = PlatformManager.instance;
  late PerformanceOptimizer _performanceOptimizer;
  late NetworkOptimizer _networkOptimizer;

  PlatformDiagnostics? _diagnostics;
  bool _isLoadingDiagnostics = false;

  @override
  void initState() {
    super.initState();
    _performanceOptimizer = _platformManager.performanceOptimizer;
    _networkOptimizer = _platformManager.networkOptimizer;
    _loadDiagnostics();
  }

  Future<void> _loadDiagnostics() async {
    setState(() {
      _isLoadingDiagnostics = true;
    });

    try {
      final diagnostics = await _platformManager.getDiagnostics();
      setState(() {
        _diagnostics = diagnostics;
        _isLoadingDiagnostics = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDiagnostics = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load diagnostics: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Performance Settings'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDiagnostics,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDiagnosticsSection(),
            SizedBox(height: 24),
            _buildOptimizationLevelSection(),
            SizedBox(height: 24),
            _buildPerformanceSettingsSection(),
            SizedBox(height: 24),
            _buildNetworkSettingsSection(),
            SizedBox(height: 24),
            _buildAdvancedSettingsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Diagnostics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            if (_isLoadingDiagnostics)
              Center(child: CircularProgressIndicator())
            else if (_diagnostics != null)
              _buildDiagnosticsContent()
            else
              Text('Failed to load diagnostics'),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticsContent() {
    final diagnostics = _diagnostics!;

    return Column(
      children: [
        _buildDiagnosticItem(
          'Platform',
          '${diagnostics.platform} ${diagnostics.version}',
          Icons.phone_android,
        ),
        _buildDiagnosticItem(
          'Battery Level',
          '${(diagnostics.batteryLevel * 100).toInt()}%',
          Icons.battery_full,
          valueColor: _getBatteryColor(diagnostics.batteryLevel),
        ),
        _buildDiagnosticItem(
          'Memory Usage',
          _formatMemoryUsage(diagnostics.memoryUsage),
          Icons.memory,
          valueColor: _getMemoryColor(diagnostics.memoryUsage),
        ),
        _buildDiagnosticItem(
          'Network Speed',
          diagnostics.networkDiagnostics.connectionQuality,
          Icons.network_check,
        ),
        _buildDiagnosticItem(
          'Latency',
          '${diagnostics.networkDiagnostics.latency.toInt()}ms',
          Icons.speed,
        ),
      ],
    );
  }

  Widget _buildDiagnosticItem(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationLevelSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Optimization Level',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildOptimizationLevelButton(
              OptimizationLevel.battery,
              'Battery Saver',
              'Maximize battery life',
              Icons.battery_saver,
              Colors.green,
            ),
            SizedBox(height: 8),
            _buildOptimizationLevelButton(
              OptimizationLevel.balanced,
              'Balanced',
              'Balance performance and battery',
              Icons.balance,
              Colors.blue,
            ),
            SizedBox(height: 8),
            _buildOptimizationLevelButton(
              OptimizationLevel.performance,
              'Performance',
              'Maximize performance',
              Icons.speed,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizationLevelButton(
    OptimizationLevel level,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _setOptimizationLevel(level),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          padding: EdgeInsets.all(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: color.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSettingsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('Low Memory Mode'),
              subtitle: Text('Reduce memory usage for slower devices'),
              value: _performanceOptimizer.lowMemoryMode,
              onChanged: (value) async {
                await _performanceOptimizer.setLowMemoryMode(value);
                setState(() {});
              },
            ),
            SwitchListTile(
              title: Text('Battery Optimization'),
              subtitle: Text('Optimize for battery life'),
              value: _performanceOptimizer.batteryOptimizationEnabled,
              onChanged: (value) async {
                await _performanceOptimizer.setBatteryOptimization(value);
                setState(() {});
              },
            ),
            SwitchListTile(
              title: Text('Background Processing'),
              subtitle: Text('Allow background tasks'),
              value: _performanceOptimizer.backgroundProcessingEnabled,
              onChanged: (value) async {
                await _performanceOptimizer.setBackgroundProcessing(value);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkSettingsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Network Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('Data Compression'),
              subtitle: Text('Compress data to save bandwidth'),
              value: _networkOptimizer.compressionEnabled,
              onChanged: (value) async {
                await _networkOptimizer.setCompressionEnabled(value);
                setState(() {});
              },
            ),
            SwitchListTile(
              title: Text('Content Caching'),
              subtitle: Text('Cache content locally'),
              value: _networkOptimizer.cachingEnabled,
              onChanged: (value) async {
                await _networkOptimizer.setCachingEnabled(value);
                setState(() {});
              },
            ),
            SwitchListTile(
              title: Text('Content Prefetching'),
              subtitle: Text('Preload content for faster access'),
              value: _networkOptimizer.prefetchingEnabled,
              onChanged: (value) async {
                await _networkOptimizer.setPrefetchingEnabled(value);
                setState(() {});
              },
            ),
            SwitchListTile(
              title: Text('Battery-Aware Networking'),
              subtitle: Text('Reduce network usage on low battery'),
              value: _networkOptimizer.batteryAwareNetworking,
              onChanged: (value) async {
                await _networkOptimizer.setBatteryAwareNetworking(value);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettingsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.network_check),
              title: Text('Network Diagnostics'),
              subtitle: Text('Run network speed test'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: _runNetworkDiagnostics,
            ),
            ListTile(
              leading: Icon(Icons.cleaning_services),
              title: Text('Clear Cache'),
              subtitle: Text('Free up storage space'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: _clearCache,
            ),
            ListTile(
              leading: Icon(Icons.memory),
              title: Text('Memory Cleanup'),
              subtitle: Text('Force garbage collection'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: _cleanupMemory,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setOptimizationLevel(OptimizationLevel level) async {
    try {
      await _platformManager.setOptimizationLevel(level);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Optimization level updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update optimization level: $e')),
      );
    }
  }

  Future<void> _runNetworkDiagnostics() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Running network diagnostics...'),
          ],
        ),
      ),
    );

    try {
      final diagnostics = await _networkOptimizer.runNetworkDiagnostics();
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Network Diagnostics'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Latency: ${diagnostics.latency.toInt()}ms'),
              Text('Bandwidth: ${diagnostics.bandwidth.toStringAsFixed(2)} Mbps'),
              Text('Connection Quality: ${diagnostics.connectionQuality}'),
              Text('Packet Loss: ${(diagnostics.packetLoss * 100).toStringAsFixed(1)}%'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Diagnostics failed: $e')),
      );
    }
  }

  Future<void> _clearCache() async {
    try {
      await _performanceOptimizer.onMemoryPressure();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cache cleared successfully')),
      );
      _loadDiagnostics();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear cache: $e')),
      );
    }
  }

  Future<void> _cleanupMemory() async {
    try {
      await _performanceOptimizer.onMemoryPressure();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Memory cleanup completed')),
      );
      _loadDiagnostics();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Memory cleanup failed: $e')),
      );
    }
  }

  Color _getBatteryColor(double level) {
    if (level > 0.5) return Colors.green;
    if (level > 0.2) return Colors.orange;
    return Colors.red;
  }

  Color _getMemoryColor(Map<String, dynamic> memoryUsage) {
    final used = memoryUsage['usedMemory'] ?? 0;
    final total = memoryUsage['totalMemory'] ?? 1;
    final percentage = used / total;

    if (percentage < 0.7) return Colors.green;
    if (percentage < 0.9) return Colors.orange;
    return Colors.red;
  }

  String _formatMemoryUsage(Map<String, dynamic> memoryUsage) {
    final used = memoryUsage['usedMemory'] ?? 0;
    final total = memoryUsage['totalMemory'] ?? 1;
    final percentage = (used / total * 100).toInt();

    return '$percentage% (${_formatBytes(used)} / ${_formatBytes(total)})';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}