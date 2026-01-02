# Data Protection

Ukkin employs multiple layers of protection to keep your data secure on your device.

## Encryption

### At Rest

All stored data is encrypted using:

- **Algorithm:** AES-256-GCM
- **Key Storage:** Android Keystore / iOS Keychain
- **Key Generation:** Device-specific, never leaves device

### Encrypted Data Types

| Data Type | Encryption | Notes |
|-----------|------------|-------|
| Agent configurations | Always | Includes all settings |
| Extracted data | Always | Prices, text, etc. |
| Screenshots | Configurable | Optional encryption |
| Chat history | Standard+ levels | Based on privacy level |
| Execution logs | Standard+ levels | Based on privacy level |

### Encryption Process

```
Data → Encrypt with AES-256 → Store in SQLite
                ↑
    Key from Android Keystore
    (never exported)
```

## Data Storage

### Local Database

All data stored in encrypted SQLite database:

- Located in app's private directory
- Not accessible to other apps
- Automatically encrypted

### File Storage

Screenshots and exports:

- Stored in app's private storage
- Optionally encrypted
- Cleared on uninstall

### No External Storage

Ukkin never stores data:

- On SD cards
- In shared directories
- In cloud services

## Data Isolation

### App Sandboxing

Android/iOS sandboxing ensures:

- Other apps can't access Ukkin data
- Ukkin can't access other apps' data (except through UI)
- System-level isolation

### Agent Isolation

Each agent's data is isolated:

- Separate encryption keys
- Independent storage
- Can be deleted individually

## Secure Key Management

### Key Generation

Encryption keys are:

- Generated on first launch
- Stored in hardware-backed keystore
- Unique to your device
- Never transmitted

### Key Protection

Keys are protected by:

- Hardware security module (when available)
- Device PIN/password
- Biometric authentication (optional)

### Key Recovery

Keys cannot be recovered if:

- Device is wiped
- App is uninstalled
- Keystore is cleared

!!! warning "No Recovery"
    If you lose access to your device, encrypted data cannot be recovered. Export important data regularly.

## Sensitive Data Handling

### Detection

Ukkin can detect sensitive patterns:

- Credit card numbers
- Social security numbers
- Password fields
- Personal identifiers

### Protection Options

| Option | Behavior |
|--------|----------|
| **Redact** | Replace with *** in logs |
| **Skip** | Don't extract this data |
| **Alert** | Warn before accessing |
| **Block** | Never access |

### Configuration

1. **Settings** > **Privacy** > **Sensitive Data**
2. Enable pattern detection
3. Choose handling for each type

## Data Minimization

### Collection Limits

Ukkin only collects what's needed:

- Agents only extract specified data
- Temporary data deleted after use
- No excessive logging

### Retention Limits

Configure how long data is kept:

| Data Type | Default Retention |
|-----------|-------------------|
| Execution logs | 30 days |
| Screenshots | 7 days |
| Extracted data | Until deleted |
| Chat history | Unlimited |

### Auto-Cleanup

Enable automatic cleanup:

1. **Settings** > **Privacy** > **Auto Cleanup**
2. Set retention periods
3. Choose what to clean

## Secure Deletion

### Standard Delete

Normal deletion:

- Removes database records
- Deletes files
- May leave traces in storage

### Secure Wipe

For maximum security:

- Overwrites data before deletion
- Clears file system traces
- Verifies deletion

Enable: **Settings** > **Privacy** > **Secure Delete**

## Memory Protection

### Runtime Security

During execution:

- Sensitive data not logged
- Memory cleared after use
- No debugging in release builds

### Screenshot Protection

Prevent system screenshots:

- Enable **Secure Screen** mode
- Prevents screenshot capture of Ukkin
- Blocks screen recording

## Network Security

### No Network by Default

Ukkin doesn't require internet:

- AI runs locally
- Data stays on device
- Works fully offline

### Optional Network Use

If you choose to use network features:

- All connections use TLS 1.3
- Certificate pinning enabled
- No data transmitted without consent

## Backup Protection

### System Backups

By default, Ukkin data is excluded from:

- Google/iCloud backups
- ADB backups
- Device migration

### Manual Backups

If you export data manually:

- Export is encrypted
- Password protected
- You control the file

## Compliance

### Privacy Standards

Ukkin follows:

- GDPR principles (data minimization, user control)
- CCPA requirements (transparency, deletion rights)
- Privacy by design methodology

### Your Rights

You always have the right to:

- View all your data
- Export all your data
- Delete all your data
- Understand what's collected

## Verification

### Audit Your Security

Check your security status:

1. **Settings** > **Privacy** > **Security Status**
2. View:
   - Encryption status
   - Permission audit
   - Data inventory
   - Security recommendations

### Security Recommendations

Ukkin will suggest:

- Enabling biometric protection
- Reducing data retention
- Blocking sensitive apps
- Enabling audit logging

## Next Steps

- [Privacy Overview](overview.md) - General privacy information
- [Permissions Guide](permissions.md) - Control what Ukkin accesses
- [Settings](../configuration/settings.md) - Configure protection options
