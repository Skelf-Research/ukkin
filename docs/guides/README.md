# Development Guide

This guide provides comprehensive instructions for setting up, developing, and contributing to the Ukkin mobile AI assistant platform.

## Development Environment Setup

### Prerequisites

**Required Software**:
- Flutter SDK 3.1.5 or higher
- Dart SDK (included with Flutter)
- Android Studio 2022.3.1 or higher
- Xcode 14.0 or higher (macOS only)
- Git for version control

**System Requirements**:
- **Windows**: Windows 10 64-bit or higher
- **macOS**: macOS 10.14 or higher
- **Linux**: Ubuntu 18.04 LTS or higher
- **RAM**: Minimum 8GB, recommended 16GB
- **Storage**: 10GB free space for development tools

### Flutter Installation

1. **Download Flutter SDK**:
   ```bash
   git clone https://github.com/flutter/flutter.git -b stable
   export PATH="$PATH:`pwd`/flutter/bin"
   ```

2. **Verify Installation**:
   ```bash
   flutter doctor -v
   ```

3. **Install Dependencies**:
   ```bash
   flutter doctor --android-licenses
   ```

### Android Development Setup

1. **Install Android Studio**:
   - Download from https://developer.android.com/studio
   - Install with default settings including Android SDK

2. **Configure Environment Variables**:
   ```bash
   export ANDROID_HOME=$HOME/Android/Sdk
   export PATH=$PATH:$ANDROID_HOME/emulator
   export PATH=$PATH:$ANDROID_HOME/tools
   export PATH=$PATH:$ANDROID_HOME/tools/bin
   export PATH=$PATH:$ANDROID_HOME/platform-tools
   ```

3. **Accept Android Licenses**:
   ```bash
   flutter doctor --android-licenses
   ```

### iOS Development Setup (macOS only)

1. **Install Xcode**:
   - Download from Mac App Store
   - Install Xcode command line tools

2. **Configure iOS Simulator**:
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```

3. **Install CocoaPods**:
   ```bash
   sudo gem install cocoapods
   ```

## Project Setup

### Repository Clone and Setup

1. **Clone Repository**:
   ```bash
   git clone https://github.com/yourusername/ukkin.git
   cd ukkin
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate Native Code** (if needed):
   ```bash
   flutter packages pub run build_runner build
   ```

### Configuration Files

**Android Configuration**:
- `android/app/src/main/AndroidManifest.xml`: App permissions and configuration
- `android/app/build.gradle`: Build configuration and dependencies
- `android/gradle.properties`: Project-wide Android properties

**iOS Configuration**:
- `ios/Runner/Info.plist`: App permissions and configuration
- `ios/Runner.xcodeproj/`: Xcode project configuration
- `ios/Podfile`: iOS dependency management

### Environment Configuration

Create a `.env` file in the project root for environment-specific configurations:

```bash
# Development environment
ENVIRONMENT=development
LOG_LEVEL=debug
ENABLE_ANALYTICS=false

# API configurations
API_BASE_URL=https://api.ukkin.dev
API_TIMEOUT=30000

# Feature flags
ENABLE_VOICE_FEATURES=true
ENABLE_VLM_FEATURES=true
ENABLE_EXPERIMENTAL_FEATURES=false
```

## Development Workflow

### Code Organization

The project follows a modular architecture with clear separation of concerns:

```
lib/
├── agent/              # AI agent system
│   ├── core/          # Core agent interfaces and base classes
│   ├── mobile/        # Mobile-specific agent implementations
│   ├── coordination/  # Agent coordination and orchestration
│   ├── memory/        # Memory management and persistence
│   ├── planning/      # Task planning and execution
│   └── models/        # Data models and message types
├── voice/             # Voice processing and interaction
│   ├── services/      # Voice recognition and synthesis
│   ├── widgets/       # Voice UI components
│   └── models/        # Voice-related data models
├── vlm/               # Computer vision and VLM
│   ├── services/      # VLM processing and analysis
│   ├── widgets/       # Visual analysis UI components
│   └── models/        # VLM data models and results
├── integrations/      # App integrations and workflows
│   ├── services/      # Integration management
│   ├── workflows/     # Workflow builder and execution
│   ├── ui/           # Integration UI components
│   └── models/        # Integration data models
├── platform/          # Platform-specific optimizations
│   ├── performance/   # Performance optimization
│   ├── network/       # Network optimization
│   └── managers/      # Platform management
└── ui/                # Shared UI components and themes
```

### Coding Standards

**Dart Code Style**:
- Follow official Dart style guide
- Use meaningful variable and function names
- Include comprehensive documentation
- Implement proper error handling

**File Naming Conventions**:
- Use snake_case for file names
- Use descriptive names indicating file purpose
- Group related files in appropriate directories

**Code Documentation**:
```dart
/// Service for managing app integrations and cross-app automation.
///
/// This service provides a unified interface for connecting with various
/// mobile applications and executing automated workflows across multiple apps.
///
/// Example usage:
/// ```dart
/// final service = AppIntegrationService.instance;
/// await service.initialize();
///
/// final result = await service.sendMessage(
///   'com.whatsapp',
///   'John Doe',
///   'Hello from Ukkin!',
/// );
/// ```
class AppIntegrationService {
  /// Initializes the integration service and discovers available apps.
  Future<void> initialize() async {
    // Implementation
  }
}
```

### Testing Guidelines

**Unit Tests**:
```dart
// test/services/app_integration_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ukkin/integrations/app_integration_service.dart';

void main() {
  group('AppIntegrationService', () {
    late AppIntegrationService service;

    setUp(() {
      service = AppIntegrationService.instance;
    });

    test('should initialize successfully', () async {
      await service.initialize();
      expect(service.isInitialized, isTrue);
    });

    test('should discover available integrations', () async {
      await service.initialize();
      final integrations = service.availableIntegrations;
      expect(integrations, isNotEmpty);
    });
  });
}
```

**Integration Tests**:
```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ukkin/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Ukkin App Integration Tests', () {
    testWidgets('should launch app successfully', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should navigate to AI assistant', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('AI Assistant'));
      await tester.pumpAndSettle();

      expect(find.text('Hi! I\'m your AI assistant.'), findsOneWidget);
    });
  });
}
```

**Running Tests**:
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Development Commands

**Development Server**:
```bash
# Run in debug mode
flutter run

# Run with hot reload
flutter run --hot

# Run on specific device
flutter run -d <device_id>

# Run with performance overlay
flutter run --profile
```

**Code Analysis**:
```bash
# Static analysis
flutter analyze

# Format code
flutter format .

# Fix common issues
dart fix --apply
```

**Build Commands**:
```bash
# Build APK (Android)
flutter build apk

# Build AAB (Android)
flutter build appbundle

# Build iOS
flutter build ios

# Build for release
flutter build apk --release
flutter build ios --release
```

## Platform-Specific Development

### Android Native Development

**Adding Native Android Code**:

1. **Create Plugin File**:
   ```kotlin
   // android/app/src/main/kotlin/com/example/ukkin/CustomPlugin.kt
   package com.example.ukkin

   import io.flutter.embedding.engine.plugins.FlutterPlugin
   import io.flutter.plugin.common.MethodChannel

   class CustomPlugin : FlutterPlugin {
       override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
           val channel = MethodChannel(binding.binaryMessenger, "custom_plugin")
           channel.setMethodCallHandler { call, result ->
               when (call.method) {
                   "customMethod" -> {
                       result.success("Custom result")
                   }
                   else -> result.notImplemented()
               }
           }
       }

       override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}
   }
   ```

2. **Register Plugin**:
   ```kotlin
   // android/app/src/main/kotlin/com/example/ukkin/MainActivity.kt
   override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
       super.configureFlutterEngine(flutterEngine)
       flutterEngine.plugins.add(CustomPlugin())
   }
   ```

3. **Flutter Integration**:
   ```dart
   // lib/services/custom_service.dart
   class CustomService {
       static const MethodChannel _channel = MethodChannel('custom_plugin');

       static Future<String> customMethod() async {
           final result = await _channel.invokeMethod('customMethod');
           return result as String;
       }
   }
   ```

### iOS Native Development

**Adding Native iOS Code**:

1. **Create Plugin File**:
   ```swift
   // ios/Runner/CustomPlugin.swift
   import Flutter

   class CustomPlugin: NSObject, FlutterPlugin {
       static func register(with registrar: FlutterPluginRegistrar) {
           let channel = FlutterMethodChannel(name: "custom_plugin", binaryMessenger: registrar.messenger())
           let instance = CustomPlugin()
           registrar.addMethodCallDelegate(instance, channel: channel)
       }

       func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
           switch call.method {
           case "customMethod":
               result("Custom result")
           default:
               result(FlutterMethodNotImplemented)
           }
       }
   }
   ```

2. **Register Plugin**:
   ```swift
   // ios/Runner/AppDelegate.swift
   override func application(
       _ application: UIApplication,
       didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
   ) -> Bool {
       GeneratedPluginRegistrant.register(with: self)
       CustomPlugin.register(with: self.registrar(forPlugin: "CustomPlugin")!)
       return super.application(application, didFinishLaunchingWithOptions: launchOptions)
   }
   ```

## Performance Optimization

### Memory Management

**Best Practices**:
- Dispose of controllers and streams in widget dispose methods
- Use const constructors for immutable widgets
- Implement proper widget lifecycle management
- Monitor memory usage during development

```dart
class MyWidget extends StatefulWidget {
    @override
    _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
    late StreamSubscription _subscription;
    late AnimationController _controller;

    @override
    void initState() {
        super.initState();
        _controller = AnimationController(vsync: this);
        _subscription = stream.listen(_handleData);
    }

    @override
    void dispose() {
        _controller.dispose();
        _subscription.cancel();
        super.dispose();
    }
}
```

### Build Optimization

**Release Build Configuration**:
```bash
# Optimize for size
flutter build apk --split-per-abi --target-platform android-arm64

# Enable R8 obfuscation
flutter build apk --obfuscate --split-debug-info=<debug-info-dir>

# Tree shaking for web
flutter build web --tree-shake-icons
```

## Debugging and Troubleshooting

### Common Issues and Solutions

**Build Issues**:
```bash
# Clean build cache
flutter clean
flutter pub get

# Reset Flutter
flutter doctor
flutter upgrade

# Clear Gradle cache (Android)
cd android && ./gradlew clean
```

**Performance Issues**:
```bash
# Profile app performance
flutter run --profile
flutter run --release

# Memory profiling
flutter run --profile --enable-vm-service
```

**Platform-Specific Issues**:

**Android**:
- Ensure ANDROID_HOME is set correctly
- Check Android SDK and build tools versions
- Verify AndroidManifest.xml permissions

**iOS**:
- Ensure valid provisioning profiles
- Check Info.plist configurations
- Verify CocoaPods installation

### Debugging Tools

**Flutter Inspector**:
- Widget tree inspection
- Performance profiling
- Memory analysis
- Network monitoring

**Platform Tools**:
- Android: Android Studio profiler, adb logcat
- iOS: Xcode Instruments, iOS Simulator

## Contribution Guidelines

### Git Workflow

**Branch Naming**:
- Feature: `feature/description`
- Bug fix: `bugfix/description`
- Hotfix: `hotfix/description`

**Commit Messages**:
```
type(scope): description

feat(voice): add voice command recognition
fix(vlm): resolve image analysis crash
docs(api): update integration service documentation
```

**Pull Request Process**:
1. Create feature branch from main
2. Implement changes with tests
3. Update documentation if needed
4. Submit pull request with detailed description
5. Address code review feedback
6. Merge after approval

### Code Review Checklist

**Functionality**:
- Code works as intended
- Edge cases are handled
- Error handling is implemented
- Performance is acceptable

**Code Quality**:
- Follows project coding standards
- Includes appropriate documentation
- Has adequate test coverage
- No code duplication or complexity

**Security**:
- No sensitive data exposure
- Proper input validation
- Secure communication protocols
- Permission management

### Release Process

**Version Management**:
- Follow semantic versioning (MAJOR.MINOR.PATCH)
- Update version in pubspec.yaml
- Create release notes
- Tag release in Git

**Build and Deploy**:
```bash
# Prepare release build
flutter clean
flutter pub get
flutter test
flutter analyze

# Build release artifacts
flutter build apk --release
flutter build ios --release

# Generate release notes
git log --oneline v1.0.0..HEAD
```

This development guide provides the foundation for contributing to Ukkin's mobile AI assistant platform while maintaining code quality, performance, and security standards.