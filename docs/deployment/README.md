# Deployment Guide

This guide covers the complete deployment process for Ukkin, including build configuration, distribution, and maintenance procedures for both Android and iOS platforms.

## Build Configuration

### Production Build Setup

**Environment Configuration**:

Create production environment files:

```bash
# .env.production
ENVIRONMENT=production
LOG_LEVEL=error
ENABLE_ANALYTICS=true
API_BASE_URL=https://api.ukkin.com
API_TIMEOUT=30000
ENABLE_CRASH_REPORTING=true
```

**Build Constants**:

```dart
// lib/config/build_config.dart
class BuildConfig {
  static const String environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.ukkin.dev');
  static const bool enableAnalytics = bool.fromEnvironment('ENABLE_ANALYTICS', defaultValue: false);
  static const bool enableCrashReporting = bool.fromEnvironment('ENABLE_CRASH_REPORTING', defaultValue: false);

  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
}
```

### Version Management

**Semantic Versioning**:
- **MAJOR**: Breaking changes or major feature releases
- **MINOR**: New features with backward compatibility
- **PATCH**: Bug fixes and minor improvements

**Version Update Process**:

1. **Update pubspec.yaml**:
   ```yaml
   name: ukkin
   description: AI-Powered Mobile Assistant Platform
   version: 1.2.3+45  # version+build_number
   ```

2. **Update Platform-Specific Versions**:

   **Android** (`android/app/build.gradle`):
   ```gradle
   android {
       defaultConfig {
           versionCode 45
           versionName "1.2.3"
       }
   }
   ```

   **iOS** (`ios/Runner/Info.plist`):
   ```xml
   <key>CFBundleShortVersionString</key>
   <string>1.2.3</string>
   <key>CFBundleVersion</key>
   <string>45</string>
   ```

## Android Deployment

### Keystore Configuration

**Generate Release Keystore**:
```bash
keytool -genkey -v -keystore ~/ukkin-release-key.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias ukkin
```

**Configure Signing** (`android/key.properties`):
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=ukkin
storeFile=../ukkin-release-key.keystore
```

**Update build.gradle** (`android/app/build.gradle`):
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            useProguard true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

### Build Commands

**Development Build**:
```bash
flutter build apk --debug
```

**Release Build**:
```bash
# Single APK
flutter build apk --release

# Split APKs by ABI (recommended for Play Store)
flutter build apk --split-per-abi --release

# Android App Bundle (AAB) - preferred for Play Store
flutter build appbundle --release

# Obfuscated build
flutter build apk --obfuscate --split-debug-info=build/debug-info --release
```

### ProGuard Configuration

**ProGuard Rules** (`android/app/proguard-rules.pro`):
```proguard
# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Ukkin specific classes
-keep class com.example.ukkin.** { *; }

# SQLite
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# HTTP
-keepattributes Signature
-keepattributes *Annotation*
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
```

### Google Play Store Deployment

**Store Listing Requirements**:
- App title: "Ukkin: AI Assistant"
- Short description: "Private AI assistant with voice, vision, and app automation"
- Full description: Comprehensive feature overview
- Screenshots: High-quality screenshots showcasing key features
- Privacy policy: Required for apps with sensitive permissions

**App Bundle Upload**:
1. Generate signed AAB file
2. Upload to Google Play Console
3. Configure release tracks (internal, alpha, beta, production)
4. Review and publish

**Release Tracks**:
- **Internal Testing**: For development team
- **Closed Testing (Alpha)**: For selected testers
- **Open Testing (Beta)**: For public beta testing
- **Production**: For all users

### Firebase Distribution (Optional)

**Setup Firebase App Distribution**:
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize project
firebase init
```

**Distribute Build**:
```bash
# Upload to Firebase Distribution
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
    --app YOUR_FIREBASE_APP_ID \
    --groups testers \
    --release-notes "Version 1.2.3 - Bug fixes and performance improvements"
```

## iOS Deployment

### Code Signing Configuration

**Apple Developer Account Setup**:
1. Enroll in Apple Developer Program
2. Create App ID in Apple Developer Portal
3. Generate provisioning profiles
4. Configure signing certificates

**Xcode Configuration**:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target
3. Configure Signing & Capabilities
4. Set Team and Bundle Identifier
5. Enable required capabilities

**Required Capabilities**:
- Microphone (for voice input)
- Camera (for image analysis)
- Location Services (for location-based features)
- Background App Refresh (for background processing)

### Build Commands

**Development Build**:
```bash
flutter build ios --debug
```

**Release Build**:
```bash
# Build for device
flutter build ios --release

# Build with specific configuration
flutter build ios --release --flavor production

# Archive for App Store
flutter build ipa --release
```

### TestFlight Distribution

**Upload to App Store Connect**:
1. Archive build in Xcode
2. Use Xcode Organizer to upload
3. Configure build in App Store Connect
4. Submit for TestFlight review
5. Distribute to internal and external testers

**Command Line Upload**:
```bash
# Using xcrun altool
xcrun altool --upload-app --type ios --file build/ios/ipa/ukkin.ipa \
    --username your_apple_id@example.com \
    --password your_app_specific_password

# Using Transporter app
# Open Transporter and drag the IPA file
```

### App Store Deployment

**App Store Connect Configuration**:
- App Information: Name, category, description
- Pricing and Availability: Territory and pricing
- App Privacy: Data collection practices
- App Review Information: Contact details and notes

**Metadata Requirements**:
- App name and description
- Keywords for search optimization
- Screenshots for all supported device types
- App preview videos (optional but recommended)
- App icon in required sizes

**Submission Process**:
1. Complete all metadata
2. Upload app binary
3. Submit for review
4. Respond to any review feedback
5. Release manually or automatically upon approval

## Continuous Integration/Continuous Deployment

### GitHub Actions Workflow

**Build Workflow** (`.github/workflows/build.yml`):
```yaml
name: Build and Test

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.1.5'
    - run: flutter pub get
    - run: flutter analyze
    - run: flutter test

  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
    - run: flutter pub get
    - run: flutter build apk --release
    - uses: actions/upload-artifact@v3
      with:
        name: android-apk
        path: build/app/outputs/flutter-apk/app-release.apk

  build-ios:
    needs: test
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
    - run: flutter pub get
    - run: flutter build ios --release --no-codesign
    - uses: actions/upload-artifact@v3
      with:
        name: ios-build
        path: build/ios/iphoneos/Runner.app
```

**Release Workflow** (`.github/workflows/release.yml`):
```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
    - run: flutter pub get
    - run: flutter test
    - run: flutter build apk --release --split-per-abi
    - run: flutter build appbundle --release

    - name: Create Release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: ${{ github.ref }}
        release_name: Release ${{ github.ref }}
        body: |
          Changes in this Release
          - Feature improvements
          - Bug fixes
          - Performance optimizations
        draft: false
        prerelease: false
```

### Fastlane Configuration (Advanced)

**Setup Fastlane**:
```bash
# Install Fastlane
sudo gem install fastlane

# Initialize for Android
cd android && fastlane init

# Initialize for iOS
cd ios && fastlane init
```

**Android Fastfile** (`android/fastlane/Fastfile`):
```ruby
default_platform(:android)

platform :android do
  desc "Deploy to Google Play internal track"
  lane :internal do
    gradle(
      task: "bundle",
      build_type: "Release",
      project_dir: "android/"
    )
    upload_to_play_store(
      track: "internal",
      aab: "build/app/outputs/bundle/release/app-release.aab"
    )
  end

  desc "Deploy to Google Play production"
  lane :production do
    gradle(
      task: "bundle",
      build_type: "Release",
      project_dir: "android/"
    )
    upload_to_play_store(
      track: "production",
      aab: "build/app/outputs/bundle/release/app-release.aab"
    )
  end
end
```

**iOS Fastfile** (`ios/fastlane/Fastfile`):
```ruby
default_platform(:ios)

platform :ios do
  desc "Push to TestFlight"
  lane :beta do
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store"
    )
    upload_to_testflight
  end

  desc "Deploy to App Store"
  lane :release do
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store"
    )
    upload_to_app_store(
      submit_for_review: true,
      automatic_release: true
    )
  end
end
```

## Production Monitoring

### Crash Reporting

**Firebase Crashlytics Integration**:
```dart
// lib/services/crash_reporting_service.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashReportingService {
  static Future<void> initialize() async {
    if (BuildConfig.enableCrashReporting) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  }

  static void recordError(dynamic exception, StackTrace? stack, {String? reason}) {
    if (BuildConfig.enableCrashReporting) {
      FirebaseCrashlytics.instance.recordError(exception, stack, reason: reason);
    }
  }

  static void log(String message) {
    if (BuildConfig.enableCrashReporting) {
      FirebaseCrashlytics.instance.log(message);
    }
  }
}
```

### Analytics and Performance

**Firebase Analytics Integration**:
```dart
// lib/services/analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> logEvent(String name, Map<String, dynamic> parameters) async {
    if (BuildConfig.enableAnalytics) {
      await _analytics.logEvent(name: name, parameters: parameters);
    }
  }

  static Future<void> setUserId(String userId) async {
    if (BuildConfig.enableAnalytics) {
      await _analytics.setUserId(id: userId);
    }
  }

  static Future<void> setUserProperty(String name, String value) async {
    if (BuildConfig.enableAnalytics) {
      await _analytics.setUserProperty(name: name, value: value);
    }
  }
}
```

### Performance Monitoring

**Performance Tracking**:
```dart
// lib/services/performance_service.dart
import 'package:firebase_performance/firebase_performance.dart';

class PerformanceService {
  static Future<void> trackScreenView(String screenName) async {
    final trace = FirebasePerformance.instance.newTrace('screen_view_$screenName');
    await trace.start();
    await trace.stop();
  }

  static Future<T> trackOperation<T>(String operationName, Future<T> Function() operation) async {
    final trace = FirebasePerformance.instance.newTrace(operationName);
    await trace.start();
    try {
      final result = await operation();
      trace.setMetric('success', 1);
      return result;
    } catch (e) {
      trace.setMetric('error', 1);
      rethrow;
    } finally {
      await trace.stop();
    }
  }
}
```

## Security Considerations

### Code Obfuscation

**Flutter Obfuscation**:
```bash
# Build with obfuscation
flutter build apk --obfuscate --split-debug-info=build/debug-info --release

# Store debug symbols for crash reporting
# Upload debug-info directory to crash reporting service
```

**Native Code Protection**:
- Enable R8 obfuscation for Android
- Use Xcode's built-in optimizations for iOS
- Remove debug symbols from production builds

### API Security

**Network Security**:
- Use HTTPS for all network communications
- Implement certificate pinning
- Validate all server responses
- Use secure authentication mechanisms

**Data Protection**:
- Encrypt sensitive data at rest
- Use secure storage for credentials
- Implement proper session management
- Follow platform security guidelines

## Maintenance and Updates

### Update Strategy

**Patch Updates** (1.0.x):
- Critical bug fixes
- Security patches
- Minor performance improvements
- Deploy immediately to production

**Minor Updates** (1.x.0):
- New features
- Non-breaking API changes
- UI improvements
- Deploy through staged rollout

**Major Updates** (x.0.0):
- Breaking changes
- Major feature additions
- Architecture changes
- Extensive testing and gradual rollout

### Rollback Procedures

**App Store Rollback**:
- Prepare previous version for quick release
- Monitor crash reports and user feedback
- Coordinate rollback across all platforms

**Phased Rollout**:
- Start with 5% of users
- Monitor metrics and feedback
- Gradually increase to 100%
- Pause rollout if issues detected

This deployment guide ensures reliable, secure, and scalable distribution of Ukkin across mobile platforms while maintaining high standards for user experience and platform compliance.