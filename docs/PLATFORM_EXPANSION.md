# Platform Expansion Guide

This document outlines the strategy for expanding Ukkin to additional platforms beyond mobile.

## Current Platform Support

| Platform | Status | Automation Level |
|----------|--------|------------------|
| Android | Full Support | Full (Accessibility Service) |
| iOS | Graceful Degradation | Limited (URL Schemes, Shortcuts) |

## Planned Platforms

### 1. Desktop Companion App

**Target Platforms**: macOS, Windows, Linux

**Architecture**:
```
┌─────────────────────────────────────────────┐
│           Desktop Companion App              │
├─────────────────────────────────────────────┤
│  ┌─────────────┐  ┌──────────────────────┐  │
│  │   Tray App  │  │   Main Window        │  │
│  │   - Status  │  │   - Agent Dashboard  │  │
│  │   - Quick   │  │   - Chat Interface   │  │
│  │     Actions │  │   - Settings         │  │
│  └─────────────┘  └──────────────────────┘  │
├─────────────────────────────────────────────┤
│             AgentLib Core (FFI)             │
├─────────────────────────────────────────────┤
│           Local LLM (llamafu)               │
└─────────────────────────────────────────────┘
```

**Implementation Steps**:

1. **Flutter Desktop Setup**
   ```bash
   flutter config --enable-macos-desktop
   flutter config --enable-windows-desktop
   flutter config --enable-linux-desktop
   ```

2. **Platform-Specific Features**
   - System tray integration
   - Global hotkeys
   - Clipboard monitoring (opt-in)
   - File system access
   - Browser extension communication

3. **Desktop Automation Options**
   - macOS: AppleScript, Accessibility API
   - Windows: UI Automation, PowerShell
   - Linux: D-Bus, xdotool

4. **Sync Protocol**
   - Local network discovery (mDNS)
   - End-to-end encrypted sync
   - Conflict resolution for agent states

**Files to Create**:
```
lib/desktop/
├── tray_service.dart
├── hotkey_manager.dart
├── desktop_automation.dart
├── sync_client.dart
└── platform/
    ├── macos_automation.dart
    ├── windows_automation.dart
    └── linux_automation.dart
```

### 2. Web Interface (PWA)

**Purpose**: Browser-based access for configuration and monitoring

**Architecture**:
```
┌─────────────────────────────────────────────┐
│              Web PWA                         │
├─────────────────────────────────────────────┤
│  ┌─────────────────────────────────────┐    │
│  │         Flutter Web App             │    │
│  │  - Agent Dashboard (view only)      │    │
│  │  - Configuration Editor             │    │
│  │  - Activity Logs                    │    │
│  └─────────────────────────────────────┘    │
├─────────────────────────────────────────────┤
│              WebSocket Bridge               │
├─────────────────────────────────────────────┤
│     Mobile App (local server mode)          │
└─────────────────────────────────────────────┘
```

**Implementation Steps**:

1. **Enable Flutter Web**
   ```bash
   flutter config --enable-web
   ```

2. **Web-Specific Considerations**
   - No local LLM (use mobile device as backend)
   - WebSocket connection to mobile app
   - Service Worker for offline mode
   - Push notifications via browser API

3. **Security**
   - Local network only by default
   - Optional secure tunnel for remote access
   - Authentication required

**Files to Create**:
```
lib/web/
├── web_app.dart
├── websocket_client.dart
├── web_notifications.dart
└── pwa_manifest.json
```

### 3. Wearable Integration

**Target Devices**: Wear OS, Apple Watch

**Features**:
- Quick status check
- Voice commands
- Notification mirroring
- Simple quick actions

**Architecture**:
```
┌───────────────┐     ┌─────────────────┐
│  Wearable     │◄────│  Mobile App     │
│  Companion    │     │  (Main Host)    │
├───────────────┤     └─────────────────┘
│ - Status View │           ▲
│ - Voice Input │           │
│ - Quick Acts  │     Bluetooth/WiFi
│ - Alerts      │           │
└───────────────┘           │
                            ▼
                   ┌─────────────────┐
                   │   AgentLib      │
                   │   (Core Logic)  │
                   └─────────────────┘
```

**Implementation Steps**:

1. **Wear OS App**
   ```yaml
   # pubspec.yaml additions
   dependencies:
     wear: ^1.1.0
     flutter_wear_os_connectivity: ^1.0.0
   ```

2. **Apple Watch App**
   - Create watchOS target in Xcode
   - Use WatchConnectivity framework
   - SwiftUI for watch UI

3. **Communication Protocol**
   - Lightweight message format
   - Battery-efficient sync
   - Priority-based updates

**Files to Create**:
```
lib/wearable/
├── wearable_bridge.dart
├── wearable_messages.dart
└── wearable_actions.dart

wear_os/
├── lib/main.dart
└── lib/wear_home.dart
```

## Implementation Priority

| Phase | Platform | Effort | Value |
|-------|----------|--------|-------|
| 1 | Desktop (macOS) | Medium | High |
| 2 | Desktop (Windows) | Medium | High |
| 3 | Web PWA | Low | Medium |
| 4 | Desktop (Linux) | Low | Medium |
| 5 | Wear OS | High | Low |
| 6 | Apple Watch | High | Low |

## Sync Architecture

All platforms communicate through a shared sync protocol:

```dart
/// Sync message format
class SyncMessage {
  final String id;
  final SyncMessageType type;
  final String sourceDevice;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
  final String signature; // E2E encryption signature
}

enum SyncMessageType {
  agentState,
  configuration,
  taskResult,
  notification,
  command,
}
```

## Security Considerations

1. **Device Pairing**
   - QR code based pairing
   - Device-specific encryption keys
   - Revocable device access

2. **Data Sync**
   - End-to-end encryption
   - No cloud storage (local network only by default)
   - Optional self-hosted relay server

3. **Authentication**
   - Biometric on each device
   - Cross-device authentication chain
   - Session timeout policies

## Getting Started

To begin platform expansion:

1. Choose target platform from priority list
2. Create platform directory under `lib/`
3. Implement platform-specific automation service
4. Add sync client for multi-device support
5. Test thoroughly on target platform
6. Update this documentation

## Resources

- [Flutter Desktop Documentation](https://docs.flutter.dev/desktop)
- [Flutter Web Documentation](https://docs.flutter.dev/web)
- [Wear OS Development](https://developer.android.com/wear)
- [watchOS Development](https://developer.apple.com/watchos/)
