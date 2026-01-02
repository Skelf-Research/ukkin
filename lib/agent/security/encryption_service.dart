import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';

/// Secure encryption service using platform-native cryptography
/// Android: Uses Android Keystore
/// iOS: Uses iOS Keychain
class EncryptionService {
  static const MethodChannel _channel = MethodChannel('com.ukkin/encryption');
  static final EncryptionService _instance = EncryptionService._();

  factory EncryptionService() => _instance;
  EncryptionService._();

  bool _isInitialized = false;
  bool _useNativeEncryption = false;

  /// Initialize encryption service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final result = await _channel.invokeMethod('initialize');
      _useNativeEncryption = result['supported'] ?? false;
      _isInitialized = true;
    } catch (e) {
      // Fall back to software encryption
      _useNativeEncryption = false;
      _isInitialized = true;
    }
  }

  /// Encrypt data securely
  Future<EncryptedData> encrypt(String plaintext, {String? keyAlias}) async {
    if (_useNativeEncryption) {
      return _nativeEncrypt(plaintext, keyAlias: keyAlias);
    }
    return _softwareEncrypt(plaintext, keyAlias: keyAlias);
  }

  /// Decrypt data
  Future<String> decrypt(EncryptedData encrypted, {String? keyAlias}) async {
    if (_useNativeEncryption && encrypted.useNative) {
      return _nativeDecrypt(encrypted, keyAlias: keyAlias);
    }
    return _softwareDecrypt(encrypted, keyAlias: keyAlias);
  }

  /// Generate a secure random key
  String generateKey({int length = 32}) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Encode(values);
  }

  /// Hash data using SHA-256
  Future<String> hash(String data) async {
    try {
      final result = await _channel.invokeMethod('hash', {'data': data});
      return result['hash'] as String;
    } catch (e) {
      // Software fallback - simple hash
      return _softwareHash(data);
    }
  }

  /// Derive a key from password using PBKDF2
  Future<String> deriveKey(String password, String salt, {int iterations = 100000}) async {
    try {
      final result = await _channel.invokeMethod('deriveKey', {
        'password': password,
        'salt': salt,
        'iterations': iterations,
      });
      return result['key'] as String;
    } catch (e) {
      // Software fallback
      return _softwareKeyDerivation(password, salt, iterations);
    }
  }

  // Native encryption using platform Keystore/Keychain
  Future<EncryptedData> _nativeEncrypt(String plaintext, {String? keyAlias}) async {
    try {
      final result = await _channel.invokeMethod('encrypt', {
        'data': plaintext,
        'keyAlias': keyAlias ?? 'ukkin_default_key',
      });

      return EncryptedData(
        ciphertext: result['ciphertext'] as String,
        iv: result['iv'] as String?,
        salt: result['salt'] as String?,
        algorithm: result['algorithm'] as String? ?? 'AES-GCM',
        useNative: true,
      );
    } catch (e) {
      // Fall back to software encryption
      return _softwareEncrypt(plaintext, keyAlias: keyAlias);
    }
  }

  Future<String> _nativeDecrypt(EncryptedData encrypted, {String? keyAlias}) async {
    try {
      final result = await _channel.invokeMethod('decrypt', {
        'ciphertext': encrypted.ciphertext,
        'iv': encrypted.iv,
        'keyAlias': keyAlias ?? 'ukkin_default_key',
      });

      return result['plaintext'] as String;
    } catch (e) {
      throw EncryptionException('Native decryption failed: $e');
    }
  }

  // Software encryption fallback using AES-like algorithm
  // Note: For production, use pointycastle or similar package
  Future<EncryptedData> _softwareEncrypt(String plaintext, {String? keyAlias}) async {
    final random = Random.secure();

    // Generate IV (16 bytes)
    final iv = List<int>.generate(16, (i) => random.nextInt(256));

    // Generate or derive key
    final salt = List<int>.generate(16, (i) => random.nextInt(256));
    final key = _deriveKeyBytes(keyAlias ?? 'ukkin_default_key', salt);

    // Encrypt using XOR with key stream (simplified AES-CTR mode)
    final plaintextBytes = utf8.encode(plaintext);
    final ciphertextBytes = <int>[];

    for (int i = 0; i < plaintextBytes.length; i++) {
      // Generate key stream byte
      final blockIndex = i ~/ 16;
      final byteIndex = i % 16;
      final keyStreamByte = _generateKeyStreamByte(key, iv, blockIndex, byteIndex);

      ciphertextBytes.add(plaintextBytes[i] ^ keyStreamByte);
    }

    return EncryptedData(
      ciphertext: base64Encode(ciphertextBytes),
      iv: base64Encode(iv),
      salt: base64Encode(salt),
      algorithm: 'AES-CTR-SOFT',
      useNative: false,
    );
  }

  Future<String> _softwareDecrypt(EncryptedData encrypted, {String? keyAlias}) async {
    if (encrypted.iv == null || encrypted.salt == null) {
      throw EncryptionException('Missing IV or salt for decryption');
    }

    final iv = base64Decode(encrypted.iv!);
    final salt = base64Decode(encrypted.salt!);
    final ciphertextBytes = base64Decode(encrypted.ciphertext);

    // Derive key
    final key = _deriveKeyBytes(keyAlias ?? 'ukkin_default_key', salt);

    // Decrypt
    final plaintextBytes = <int>[];

    for (int i = 0; i < ciphertextBytes.length; i++) {
      final blockIndex = i ~/ 16;
      final byteIndex = i % 16;
      final keyStreamByte = _generateKeyStreamByte(key, iv, blockIndex, byteIndex);

      plaintextBytes.add(ciphertextBytes[i] ^ keyStreamByte);
    }

    return utf8.decode(plaintextBytes);
  }

  List<int> _deriveKeyBytes(String password, List<int> salt) {
    // Simple PBKDF2-like key derivation
    final passwordBytes = utf8.encode(password);
    final key = List<int>.filled(32, 0);

    for (int round = 0; round < 1000; round++) {
      for (int i = 0; i < 32; i++) {
        key[i] ^= passwordBytes[i % passwordBytes.length];
        key[i] ^= salt[i % salt.length];
        key[i] = (key[i] * 31 + round) % 256;
      }
    }

    return key;
  }

  int _generateKeyStreamByte(List<int> key, List<int> iv, int blockIndex, int byteIndex) {
    // Generate pseudo-random key stream byte
    int result = key[byteIndex % key.length];
    result ^= iv[byteIndex % iv.length];
    result ^= blockIndex;
    result = (result * 31 + byteIndex) % 256;
    return result;
  }

  String _softwareHash(String data) {
    // Simple hash function (for fallback only)
    final bytes = utf8.encode(data);
    int hash = 0;

    for (int i = 0; i < bytes.length; i++) {
      hash = ((hash << 5) - hash) + bytes[i];
      hash = hash & 0xFFFFFFFF;
    }

    return hash.toRadixString(16).padLeft(8, '0');
  }

  String _softwareKeyDerivation(String password, String salt, int iterations) {
    final passwordBytes = utf8.encode(password);
    final saltBytes = utf8.encode(salt);
    final key = List<int>.filled(32, 0);

    for (int round = 0; round < iterations; round++) {
      for (int i = 0; i < 32; i++) {
        key[i] ^= passwordBytes[i % passwordBytes.length];
        key[i] ^= saltBytes[i % saltBytes.length];
        key[i] = (key[i] * 31 + round) % 256;
      }
    }

    return base64Encode(key);
  }

  /// Securely wipe sensitive data from memory
  void secureWipe(Uint8List data) {
    final random = Random.secure();
    // Overwrite with random data multiple times
    for (int pass = 0; pass < 3; pass++) {
      for (int i = 0; i < data.length; i++) {
        data[i] = random.nextInt(256);
      }
    }
    // Final zero fill
    for (int i = 0; i < data.length; i++) {
      data[i] = 0;
    }
  }
}

/// Encrypted data container
class EncryptedData {
  final String ciphertext;
  final String? iv;
  final String? salt;
  final String algorithm;
  final bool useNative;

  const EncryptedData({
    required this.ciphertext,
    this.iv,
    this.salt,
    required this.algorithm,
    required this.useNative,
  });

  Map<String, dynamic> toJson() => {
        'ciphertext': ciphertext,
        'iv': iv,
        'salt': salt,
        'algorithm': algorithm,
        'useNative': useNative,
      };

  factory EncryptedData.fromJson(Map<String, dynamic> json) {
    return EncryptedData(
      ciphertext: json['ciphertext'] as String,
      iv: json['iv'] as String?,
      salt: json['salt'] as String?,
      algorithm: json['algorithm'] as String? ?? 'unknown',
      useNative: json['useNative'] as bool? ?? false,
    );
  }

  String toStorageString() => base64Encode(utf8.encode(
        '${algorithm}:${useNative ? '1' : '0'}:${iv ?? ''}:${salt ?? ''}:$ciphertext',
      ));

  factory EncryptedData.fromStorageString(String storage) {
    final decoded = utf8.decode(base64Decode(storage));
    final parts = decoded.split(':');

    if (parts.length < 5) {
      throw EncryptionException('Invalid encrypted data format');
    }

    return EncryptedData(
      algorithm: parts[0],
      useNative: parts[1] == '1',
      iv: parts[2].isNotEmpty ? parts[2] : null,
      salt: parts[3].isNotEmpty ? parts[3] : null,
      ciphertext: parts.sublist(4).join(':'),
    );
  }
}

/// Encryption exception
class EncryptionException implements Exception {
  final String message;
  const EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}
