import 'dart:async';
import 'package:flutter/services.dart';

/// Biometric authentication service
/// Supports fingerprint, face recognition, and device credentials
class BiometricAuth {
  static const MethodChannel _channel = MethodChannel('com.ukkin/biometric');
  static final BiometricAuth _instance = BiometricAuth._();

  factory BiometricAuth() => _instance;
  BiometricAuth._();

  BiometricCapabilities? _capabilities;

  /// Check available biometric capabilities
  Future<BiometricCapabilities> getCapabilities() async {
    if (_capabilities != null) return _capabilities!;

    try {
      final result = await _channel.invokeMethod('getCapabilities');

      _capabilities = BiometricCapabilities(
        isAvailable: result['isAvailable'] ?? false,
        hasFaceRecognition: result['hasFaceRecognition'] ?? false,
        hasFingerprint: result['hasFingerprint'] ?? false,
        hasIris: result['hasIris'] ?? false,
        hasDeviceCredential: result['hasDeviceCredential'] ?? false,
        strongBiometricAvailable: result['strongBiometricAvailable'] ?? false,
      );
    } catch (e) {
      _capabilities = const BiometricCapabilities(
        isAvailable: false,
        hasFaceRecognition: false,
        hasFingerprint: false,
        hasIris: false,
        hasDeviceCredential: false,
        strongBiometricAvailable: false,
      );
    }

    return _capabilities!;
  }

  /// Authenticate user with biometrics
  Future<AuthResult> authenticate({
    required String reason,
    bool allowDeviceCredential = true,
    bool requireStrongBiometric = false,
  }) async {
    try {
      final caps = await getCapabilities();

      if (!caps.isAvailable) {
        return const AuthResult(
          success: false,
          error: AuthError.notAvailable,
          message: 'Biometric authentication not available',
        );
      }

      if (requireStrongBiometric && !caps.strongBiometricAvailable) {
        return const AuthResult(
          success: false,
          error: AuthError.notEnrolled,
          message: 'Strong biometric not available',
        );
      }

      final result = await _channel.invokeMethod('authenticate', {
        'reason': reason,
        'allowDeviceCredential': allowDeviceCredential,
        'requireStrongBiometric': requireStrongBiometric,
      });

      if (result['success'] == true) {
        return AuthResult(
          success: true,
          method: _parseAuthMethod(result['method']),
          message: 'Authentication successful',
        );
      } else {
        return AuthResult(
          success: false,
          error: _parseAuthError(result['error']),
          message: result['message'] ?? 'Authentication failed',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        error: AuthError.unknown,
        message: 'Authentication error: $e',
      );
    }
  }

  /// Cancel ongoing authentication
  Future<void> cancelAuthentication() async {
    try {
      await _channel.invokeMethod('cancelAuthentication');
    } catch (e) {
      // Ignore cancellation errors
    }
  }

  /// Check if user can authenticate (has enrolled biometrics)
  Future<bool> canAuthenticate() async {
    final caps = await getCapabilities();
    return caps.isAvailable && (caps.hasFingerprint || caps.hasFaceRecognition || caps.hasDeviceCredential);
  }

  /// Check if device is secured (has screen lock)
  Future<bool> isDeviceSecure() async {
    try {
      final result = await _channel.invokeMethod('isDeviceSecure');
      return result['secure'] ?? false;
    } catch (e) {
      return false;
    }
  }

  AuthMethod _parseAuthMethod(String? method) {
    switch (method) {
      case 'fingerprint':
        return AuthMethod.fingerprint;
      case 'face':
        return AuthMethod.faceRecognition;
      case 'iris':
        return AuthMethod.iris;
      case 'deviceCredential':
        return AuthMethod.deviceCredential;
      default:
        return AuthMethod.unknown;
    }
  }

  AuthError _parseAuthError(String? error) {
    switch (error) {
      case 'cancelled':
        return AuthError.cancelled;
      case 'timeout':
        return AuthError.timeout;
      case 'lockout':
        return AuthError.lockout;
      case 'lockoutPermanent':
        return AuthError.lockoutPermanent;
      case 'notEnrolled':
        return AuthError.notEnrolled;
      case 'notAvailable':
        return AuthError.notAvailable;
      case 'failed':
        return AuthError.failed;
      default:
        return AuthError.unknown;
    }
  }
}

/// Biometric capabilities of the device
class BiometricCapabilities {
  final bool isAvailable;
  final bool hasFaceRecognition;
  final bool hasFingerprint;
  final bool hasIris;
  final bool hasDeviceCredential;
  final bool strongBiometricAvailable;

  const BiometricCapabilities({
    required this.isAvailable,
    required this.hasFaceRecognition,
    required this.hasFingerprint,
    required this.hasIris,
    required this.hasDeviceCredential,
    required this.strongBiometricAvailable,
  });

  List<String> get availableMethods {
    final methods = <String>[];
    if (hasFingerprint) methods.add('Fingerprint');
    if (hasFaceRecognition) methods.add('Face Recognition');
    if (hasIris) methods.add('Iris');
    if (hasDeviceCredential) methods.add('Device PIN/Password');
    return methods;
  }
}

/// Authentication result
class AuthResult {
  final bool success;
  final AuthMethod? method;
  final AuthError? error;
  final String message;

  const AuthResult({
    required this.success,
    this.method,
    this.error,
    required this.message,
  });
}

/// Authentication methods
enum AuthMethod {
  fingerprint,
  faceRecognition,
  iris,
  deviceCredential,
  unknown,
}

/// Authentication errors
enum AuthError {
  cancelled,
  timeout,
  lockout,
  lockoutPermanent,
  notEnrolled,
  notAvailable,
  failed,
  unknown,
}
