import 'package:flutter/services.dart';
import '../tools/tool.dart';
import '../models/task.dart';

class PhoneIntegrations extends Tool with ToolValidation {
  static const MethodChannel _platform = MethodChannel('ukkin.phone/integrations');

  @override
  String get name => 'phone_integrations';

  @override
  String get description => 'Integrate with phone features: contacts, SMS, calls, notifications, calendar, etc.';

  @override
  Map<String, String> get parameters => {
        'action': 'Action: send_sms, make_call, add_contact, get_contacts, schedule_reminder, get_notifications, etc.',
        'phone_number': 'Phone number for calls/SMS',
        'message': 'SMS message content',
        'contact_name': 'Contact name',
        'contact_info': 'Contact information (JSON)',
        'reminder_title': 'Reminder title',
        'reminder_time': 'Reminder time (ISO format)',
        'app_name': 'App name for notifications',
      };

  @override
  bool canHandle(Task task) {
    return task.type == 'phone_integration' || task.type.startsWith('phone_');
  }

  @override
  Future<bool> validate(Map<String, dynamic> parameters) async {
    return validateRequired(parameters, ['action']);
  }

  @override
  Future<dynamic> execute(Map<String, dynamic> parameters) async {
    if (!await validate(parameters)) {
      throw Exception('Invalid parameters for phone integrations');
    }

    final action = parameters['action'] as String;

    try {
      switch (action) {
        case 'send_sms':
          return await _sendSMS(parameters['phone_number'], parameters['message']);
        case 'make_call':
          return await _makeCall(parameters['phone_number']);
        case 'add_contact':
          return await _addContact(parameters['contact_name'], parameters['contact_info']);
        case 'get_contacts':
          return await _getContacts(parameters['search_query']);
        case 'schedule_reminder':
          return await _scheduleReminder(
            parameters['reminder_title'],
            parameters['reminder_time'],
            parameters['description'],
          );
        case 'get_notifications':
          return await _getNotifications(parameters['app_name']);
        case 'dismiss_notification':
          return await _dismissNotification(parameters['notification_id']);
        case 'get_device_info':
          return await _getDeviceInfo();
        case 'get_battery_status':
          return await _getBatteryStatus();
        case 'get_network_status':
          return await _getNetworkStatus();
        case 'toggle_wifi':
          return await _toggleWifi(parameters['enabled']);
        case 'toggle_bluetooth':
          return await _toggleBluetooth(parameters['enabled']);
        case 'set_volume':
          return await _setVolume(parameters['volume_type'], parameters['level']);
        case 'get_location':
          return await _getLocation();
        case 'take_photo':
          return await _takePhoto(parameters['save_path']);
        case 'record_audio':
          return await _recordAudio(parameters['duration'], parameters['save_path']);
        default:
          throw Exception('Unknown phone integration action: $action');
      }
    } catch (e) {
      return ToolExecutionResult.failure('Phone integration action failed: $e');
    }
  }

  Future<ToolExecutionResult> _sendSMS(String? phoneNumber, String? message) async {
    if (phoneNumber == null || message == null) {
      return ToolExecutionResult.failure('Phone number and message are required');
    }

    try {
      final result = await _platform.invokeMethod('sendSMS', {
        'phoneNumber': phoneNumber,
        'message': message,
      });

      return ToolExecutionResult.success({
        'action': 'send_sms',
        'phone_number': phoneNumber,
        'message': message,
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Send SMS failed: $e');
    }
  }

  Future<ToolExecutionResult> _makeCall(String? phoneNumber) async {
    if (phoneNumber == null) {
      return ToolExecutionResult.failure('Phone number is required');
    }

    try {
      final result = await _platform.invokeMethod('makeCall', {
        'phoneNumber': phoneNumber,
      });

      return ToolExecutionResult.success({
        'action': 'make_call',
        'phone_number': phoneNumber,
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Make call failed: $e');
    }
  }

  Future<ToolExecutionResult> _addContact(String? name, Map<String, dynamic>? contactInfo) async {
    if (name == null) {
      return ToolExecutionResult.failure('Contact name is required');
    }

    try {
      final result = await _platform.invokeMethod('addContact', {
        'name': name,
        'contactInfo': contactInfo ?? {},
      });

      return ToolExecutionResult.success({
        'action': 'add_contact',
        'name': name,
        'contact_info': contactInfo,
        'contact_id': result['contactId'],
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Add contact failed: $e');
    }
  }

  Future<ToolExecutionResult> _getContacts(String? searchQuery) async {
    try {
      final result = await _platform.invokeMethod('getContacts', {
        'searchQuery': searchQuery,
      });

      final contacts = result['contacts'] as List?;

      return ToolExecutionResult.success({
        'action': 'get_contacts',
        'search_query': searchQuery,
        'contacts': contacts ?? [],
        'count': contacts?.length ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Get contacts failed: $e');
    }
  }

  Future<ToolExecutionResult> _scheduleReminder(
    String? title,
    String? reminderTime,
    String? description,
  ) async {
    if (title == null || reminderTime == null) {
      return ToolExecutionResult.failure('Title and reminder time are required');
    }

    try {
      final result = await _platform.invokeMethod('scheduleReminder', {
        'title': title,
        'reminderTime': reminderTime,
        'description': description,
      });

      return ToolExecutionResult.success({
        'action': 'schedule_reminder',
        'title': title,
        'reminder_time': reminderTime,
        'description': description,
        'reminder_id': result['reminderId'],
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Schedule reminder failed: $e');
    }
  }

  Future<ToolExecutionResult> _getNotifications(String? appName) async {
    try {
      final result = await _platform.invokeMethod('getNotifications', {
        'appName': appName,
      });

      final notifications = result['notifications'] as List?;

      return ToolExecutionResult.success({
        'action': 'get_notifications',
        'app_name': appName,
        'notifications': notifications ?? [],
        'count': notifications?.length ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Get notifications failed: $e');
    }
  }

  Future<ToolExecutionResult> _dismissNotification(String? notificationId) async {
    if (notificationId == null) {
      return ToolExecutionResult.failure('Notification ID is required');
    }

    try {
      final result = await _platform.invokeMethod('dismissNotification', {
        'notificationId': notificationId,
      });

      return ToolExecutionResult.success({
        'action': 'dismiss_notification',
        'notification_id': notificationId,
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Dismiss notification failed: $e');
    }
  }

  Future<ToolExecutionResult> _getDeviceInfo() async {
    try {
      final result = await _platform.invokeMethod('getDeviceInfo');

      return ToolExecutionResult.success({
        'action': 'get_device_info',
        'device_info': result,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Get device info failed: $e');
    }
  }

  Future<ToolExecutionResult> _getBatteryStatus() async {
    try {
      final result = await _platform.invokeMethod('getBatteryStatus');

      return ToolExecutionResult.success({
        'action': 'get_battery_status',
        'battery_level': result['batteryLevel'],
        'is_charging': result['isCharging'],
        'charge_time_remaining': result['chargeTimeRemaining'],
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Get battery status failed: $e');
    }
  }

  Future<ToolExecutionResult> _getNetworkStatus() async {
    try {
      final result = await _platform.invokeMethod('getNetworkStatus');

      return ToolExecutionResult.success({
        'action': 'get_network_status',
        'wifi_connected': result['wifiConnected'],
        'wifi_name': result['wifiName'],
        'mobile_connected': result['mobileConnected'],
        'network_type': result['networkType'],
        'signal_strength': result['signalStrength'],
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Get network status failed: $e');
    }
  }

  Future<ToolExecutionResult> _toggleWifi(bool? enabled) async {
    try {
      final result = await _platform.invokeMethod('toggleWifi', {
        'enabled': enabled ?? true,
      });

      return ToolExecutionResult.success({
        'action': 'toggle_wifi',
        'enabled': enabled,
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Toggle WiFi failed: $e');
    }
  }

  Future<ToolExecutionResult> _toggleBluetooth(bool? enabled) async {
    try {
      final result = await _platform.invokeMethod('toggleBluetooth', {
        'enabled': enabled ?? true,
      });

      return ToolExecutionResult.success({
        'action': 'toggle_bluetooth',
        'enabled': enabled,
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Toggle Bluetooth failed: $e');
    }
  }

  Future<ToolExecutionResult> _setVolume(String? volumeType, int? level) async {
    if (volumeType == null || level == null) {
      return ToolExecutionResult.failure('Volume type and level are required');
    }

    try {
      final result = await _platform.invokeMethod('setVolume', {
        'volumeType': volumeType, // 'media', 'ring', 'alarm', 'notification'
        'level': level,
      });

      return ToolExecutionResult.success({
        'action': 'set_volume',
        'volume_type': volumeType,
        'level': level,
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Set volume failed: $e');
    }
  }

  Future<ToolExecutionResult> _getLocation() async {
    try {
      final result = await _platform.invokeMethod('getLocation');

      return ToolExecutionResult.success({
        'action': 'get_location',
        'latitude': result['latitude'],
        'longitude': result['longitude'],
        'accuracy': result['accuracy'],
        'altitude': result['altitude'],
        'speed': result['speed'],
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Get location failed: $e');
    }
  }

  Future<ToolExecutionResult> _takePhoto(String? savePath) async {
    try {
      final result = await _platform.invokeMethod('takePhoto', {
        'savePath': savePath,
      });

      return ToolExecutionResult.success({
        'action': 'take_photo',
        'photo_path': result['photoPath'],
        'save_path': savePath,
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Take photo failed: $e');
    }
  }

  Future<ToolExecutionResult> _recordAudio(int? duration, String? savePath) async {
    try {
      final result = await _platform.invokeMethod('recordAudio', {
        'duration': duration ?? 10, // seconds
        'savePath': savePath,
      });

      return ToolExecutionResult.success({
        'action': 'record_audio',
        'audio_path': result['audioPath'],
        'duration': duration,
        'save_path': savePath,
        'success': result['success'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Record audio failed: $e');
    }
  }

  // Helper methods for common phone operations
  Future<ToolExecutionResult> sendQuickMessage(String contactName, String message) async {
    try {
      // First, find the contact
      final contactsResult = await _getContacts(contactName);
      if (!contactsResult.success) {
        return contactsResult;
      }

      final contacts = contactsResult.data['contacts'] as List;
      if (contacts.isEmpty) {
        return ToolExecutionResult.failure('Contact "$contactName" not found');
      }

      final contact = contacts.first;
      final phoneNumber = contact['phoneNumber'] as String?;

      if (phoneNumber == null) {
        return ToolExecutionResult.failure('No phone number found for contact "$contactName"');
      }

      // Send SMS
      return await _sendSMS(phoneNumber, message);
    } catch (e) {
      return ToolExecutionResult.failure('Send quick message failed: $e');
    }
  }

  Future<ToolExecutionResult> callContact(String contactName) async {
    try {
      // First, find the contact
      final contactsResult = await _getContacts(contactName);
      if (!contactsResult.success) {
        return contactsResult;
      }

      final contacts = contactsResult.data['contacts'] as List;
      if (contacts.isEmpty) {
        return ToolExecutionResult.failure('Contact "$contactName" not found');
      }

      final contact = contacts.first;
      final phoneNumber = contact['phoneNumber'] as String?;

      if (phoneNumber == null) {
        return ToolExecutionResult.failure('No phone number found for contact "$contactName"');
      }

      // Make call
      return await _makeCall(phoneNumber);
    } catch (e) {
      return ToolExecutionResult.failure('Call contact failed: $e');
    }
  }

  Future<ToolExecutionResult> scheduleQuickReminder(String title, int minutesFromNow) async {
    try {
      final reminderTime = DateTime.now().add(Duration(minutes: minutesFromNow));
      return await _scheduleReminder(title, reminderTime.toIso8601String(), null);
    } catch (e) {
      return ToolExecutionResult.failure('Schedule quick reminder failed: $e');
    }
  }

  Future<ToolExecutionResult> getRecentNotifications({int limit = 10}) async {
    try {
      final result = await _getNotifications(null);
      if (!result.success) {
        return result;
      }

      final notifications = result.data['notifications'] as List;
      final recentNotifications = notifications.take(limit).toList();

      return ToolExecutionResult.success({
        'action': 'get_recent_notifications',
        'notifications': recentNotifications,
        'count': recentNotifications.length,
        'total_count': notifications.length,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Get recent notifications failed: $e');
    }
  }

  Future<ToolExecutionResult> checkPhoneStatus() async {
    try {
      final batteryResult = await _getBatteryStatus();
      final networkResult = await _getNetworkStatus();

      return ToolExecutionResult.success({
        'action': 'check_phone_status',
        'battery': batteryResult.data,
        'network': networkResult.data,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return ToolExecutionResult.failure('Check phone status failed: $e');
    }
  }

  Future<bool> hasPermission(String permission) async {
    try {
      final result = await _platform.invokeMethod('hasPermission', {
        'permission': permission,
      });
      return result['hasPermission'] ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> requestPermission(String permission) async {
    try {
      await _platform.invokeMethod('requestPermission', {
        'permission': permission,
      });
    } catch (e) {
      throw Exception('Failed to request permission $permission: $e');
    }
  }

  Future<List<String>> getRequiredPermissions() async {
    return [
      'android.permission.SEND_SMS',
      'android.permission.CALL_PHONE',
      'android.permission.READ_CONTACTS',
      'android.permission.WRITE_CONTACTS',
      'android.permission.ACCESS_NOTIFICATION_POLICY',
      'android.permission.ACCESS_FINE_LOCATION',
      'android.permission.CAMERA',
      'android.permission.RECORD_AUDIO',
      'android.permission.WRITE_EXTERNAL_STORAGE',
      'android.permission.CHANGE_WIFI_STATE',
      'android.permission.BLUETOOTH_ADMIN',
    ];
  }

  Future<Map<String, bool>> checkAllPermissions() async {
    final permissions = await getRequiredPermissions();
    final permissionStatus = <String, bool>{};

    for (final permission in permissions) {
      permissionStatus[permission] = await hasPermission(permission);
    }

    return permissionStatus;
  }
}