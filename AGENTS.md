# AGENTS.md

## Project Overview

**ClaudeMeter** is a macOS 14+ menu bar application that monitors Claude.ai usage limits in real-time. It tracks 5-hour session usage, 7-day weekly usage, and Sonnet-specific usage limits.

- **Language**: Swift 6
- **UI Framework**: SwiftUI with AppKit integration (NSStatusItem/NSPopover)
- **Architecture**: SwiftUI-first with @MainActor @Observable state management and actor-isolated services
- **Platform**: macOS 14.0 (Sonoma) or later
- **IDE**: Xcode 16.0+

## Project Structure

```
ClaudeMeter/
├── App/                      # Application entry point and main model
│   ├── AppDelegate.swift     # NSApplicationDelegate for menu bar management
│   ├── AppModel.swift        # @MainActor @Observable central state
│   └── ClaudeMeterApp.swift  # @main app struct, Scene configuration
├── Models/                   # Data types and domain models
│   ├── API/                  # API response models (UsageAPIResponse, OrganizationListResponse)
│   ├── Errors/               # Error types (AppError, NetworkError, KeychainError)
│   ├── AppSettings.swift     # User preferences (Codable, persisted to UserDefaults)
│   ├── Constants.swift       # Application-wide constants (TTL, thresholds, intervals)
│   ├── IconStyle.swift       # Enum for menu bar icon styles (battery, circular, etc.)
│   ├── NotificationState.swift      # Notification tracking state
│   ├── NotificationThresholds.swift # Configurable alert thresholds
│   ├── Organization.swift    # Organization data from API
│   ├── SessionKey.swift      # Validated session key (sk-ant-* format)
│   ├── UsageData.swift       # Complete usage data across all limit types
│   ├── UsageLimit.swift      # Single usage limit with risk calculation
│   └── UsageStatus.swift     # Status enum (safe, warning, critical)
├── Services/                 # Actor-isolated business logic
│   ├── Protocols/            # Service protocols for dependency injection
│   ├── NetworkService.swift  # URLSession-based HTTP client
│   ├── NotificationService.swift    # UserNotifications framework integration
│   └── UsageService.swift    # Usage fetching with retry logic
├── Repositories/             # Data persistence layer
│   ├── Protocols/            # Repository protocols
│   ├── CacheRepository.swift        # In-memory usage data cache
│   ├── KeychainRepository.swift     # Secure session key storage
│   └── SettingsRepository.swift     # UserDefaults persistence
├── Views/                    # SwiftUI components
│   ├── MenuBar/              # Menu bar icon, popover, status item management
│   │   ├── IconStyles/       # 6 icon style implementations
│   │   ├── MenuBarIconView.swift    # Icon style dispatcher
│   │   ├── MenuBarManager.swift     # NSStatusItem/NSPopover management
│   │   └── UsagePopoverView.swift   # Main popover content
│   ├── Settings/             # Settings window views
│   │   ├── IconStylePicker.swift
│   │   └── SettingsView.swift       # Tabbed settings interface
│   └── Setup/                # First-time setup
│       └── SetupWizardView.swift
├── Utilities/                # Helper utilities
│   ├── DemoDataFactory.swift # Screenshot/demo data generation
│   └── DemoMode.swift        # Demo mode launcher (DEBUG only)
└── Resources/                # Assets and plist files

ClaudeMeterTests/             # XCTest suite
├── TestDoubles/              # Stubs, fakes, spies for protocol-based testing
│   ├── CacheRepositoryFake.swift
│   ├── KeychainRepositoryFake.swift
│   ├── NetworkServiceStub.swift
│   ├── NotificationCenterSpy.swift
│   ├── NotificationServiceSpy.swift
│   ├── SettingsRepositoryFake.swift
│   └── UsageServiceStub.swift
├── TestSupport/              # Test helpers and constants
│   └── TestConstants.swift
├── __Snapshots__/            # Snapshot test reference images
├── AppModelTests.swift
├── MenuBarIconRendererTests.swift
├── MenuBarIconSnapshotTests.swift
├── NotificationServiceTests.swift
├── SettingsRepositoryTests.swift
└── UsageLimitRiskTests.swift
```

## Build Commands

```bash
# Open in Xcode
open ClaudeMeter.xcodeproj

# Build (Debug)
xcodebuild clean build \
  -project ClaudeMeter.xcodeproj \
  -scheme ClaudeMeter \
  -configuration Debug

# Build (Release - Universal Binary)
xcodebuild clean build \
  -project ClaudeMeter.xcodeproj \
  -scheme ClaudeMeter \
  -configuration Release \
  -derivedDataPath ./build \
  -arch x86_64 -arch arm64

# Run Tests
xcodebuild test \
  -project ClaudeMeter.xcodeproj \
  -scheme ClaudeMeter \
  -configuration Debug \
  -skip-testing:ClaudeMeterTests/MenuBarIconSnapshotTests \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

# Run specific test class
xcodebuild test \
  -project ClaudeMeter.xcodeproj \
  -scheme ClaudeMeter \
  -only-testing ClaudeMeterTests/AppModelTests
```

## Architecture Patterns

### State Management
- **AppModel**: Single @MainActor @Observable class owns all UI state
- **@ObservationIgnored**: Mark non-UI dependencies to prevent unnecessary updates
- **Settings persistence**: Automatic save on change via didSet observer

### Concurrency Model
```swift
// Observable state owner (UI thread)
@MainActor @Observable final class AppModel {
    var settings: AppSettings = .default
    @ObservationIgnored private let service: ServiceProtocol
}

// Actor-isolated service (thread-safe background)
actor UsageService: UsageServiceProtocol {
    private static let logger = Logger(...)
    func fetchUsage() async throws -> UsageData { }
}

// @MainActor class for notification delegate callbacks
@MainActor final class NotificationService: NSObject, UNUserNotificationCenterDelegate
```

### Dependency Injection
Constructor injection with default implementations:
```swift
init(
    settingsRepository: SettingsRepositoryProtocol = SettingsRepository(),
    keychainRepository: KeychainRepositoryProtocol = KeychainRepository()
) { }
```

### Repository Pattern
- **KeychainRepository**: Secure session key storage (service: `com.claudemeter.sessionkey`)
- **SettingsRepository**: UserDefaults with JSON encoding
- **CacheRepository**: Actor-isolated in-memory cache with TTL

### Service Layer
- **NetworkService**: URLSession wrapper with Cloudflare bot detection headers
- **UsageService**: Retry logic with exponential backoff (2^n for network, 3^n for rate limits)
- **NotificationService**: UNUserNotificationCenter integration with threshold tracking

## Code Conventions

### File Organization
- One type per file, filename matches type exactly
- Protocols in `Protocols/` subdirectory
- Error types suffixed (AppError.swift, NetworkError.swift)

### Naming
- Types: PascalCase (`UsageService`, `AppModel`)
- Functions/variables: camelCase (`fetchUsage`, `isLoading`)
- Constants: static let within enum namespaces (`Constants.Cache.ttl`)

### Imports
System frameworks only, no third-party dependencies in main target:
```swift
import SwiftUI
import Observation
import UserNotifications
import AppKit
import Security  // For Keychain
import os        // For Logger
```

### Test-Only Dependency
Tests use [pointfreeco/swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) for image comparison (MenuBarIconSnapshotTests).

## Testing Strategy

### Test Structure
- **Unit tests**: Protocol-based with test doubles (stubs, fakes, spies)
- **@MainActor**: All test classes marked for UI thread isolation
- **Async tests**: Use `async`/`await` throughout

### Test Doubles Pattern
```swift
// Stub: Returns predefined responses
final class UsageServiceStub: UsageServiceProtocol {
    var fetchUsageResult: Result<UsageData, Error>
    func fetchUsage(forceRefresh: Bool) async throws -> UsageData {
        try fetchUsageResult.get()
    }
}

// Spy: Records call history
final class NotificationServiceSpy: NotificationServiceProtocol {
    var lastEvaluatedUsageData: UsageData?
    func evaluateThresholds(usageData: UsageData, settings: AppSettings) async {
        lastEvaluatedUsageData = usageData
    }
}

// Fake: In-memory implementation
final class KeychainRepositoryFake: KeychainRepositoryProtocol {
    private var storage: [String: String] = [:]
    func save(sessionKey: String, account: String) async throws {
        storage[account] = sessionKey
    }
}
```

### Running Tests
- Snapshot tests are skipped in CI due to rendering differences
- Tests run on `macos-latest` GitHub Actions runner
- Code signing disabled for test workflow

## Key Constants

Defined in `ClaudeMeter/Models/Constants.swift`:

| Constant | Value | Description |
|----------|-------|-------------|
| `Cache.ttl` | 55 seconds | Memory cache time-to-live (< min refresh interval) |
| `Cache.maxIconCacheSize` | 100 | Maximum cached icons |
| `Network.maxRetries` | 3 | Maximum retry attempts |
| `Network.backoffBase` | 2.0 | Exponential backoff multiplier (network errors) |
| `Network.rateLimitBackoffBase` | 3.0 | Exponential backoff multiplier (rate limits) |
| `Refresh.minimum` | 60 seconds | Minimum refresh interval |
| `Refresh.maximum` | 600 seconds | Maximum refresh interval |
| `Refresh.stalenessThreshold` | 1200 seconds | Shows "stale" indicator |
| `Pacing.riskThreshold` | 1.2 | Ratio for "at risk" status |
| `Thresholds.Status.warningStart` | 50% | Warning status begins |
| `Thresholds.Status.criticalStart` | 80% | Critical status begins |
| `Thresholds.Notification.warningDefault` | 75% | Default warning threshold |
| `Thresholds.Notification.criticalDefault` | 90% | Default critical threshold |

## Security Considerations

### Session Keys
- **Format**: `sk-ant-*` (validated by `SessionKey` initializer)
- **Storage**: macOS Keychain only (never UserDefaults, never logs)
- **Keychain service**: `com.claudemeter.sessionkey`
- **Access group**: `$(AppIdentifierPrefix)com.claudemeter`
- **Accessibility**: `kSecAttrAccessibleAfterFirstUnlock`
- **Not Codable**: `SessionKey` intentionally not serializable to prevent accidental persistence

### Data Export
Usage data exported to `~/.claudemeter/usage.json` for external tools integration (contains only percentages, no sensitive data).

### Network Security
- HTTPS-only validation (rejects HTTP endpoints)
- Session key sent as cookie header
- Cloudflare-compatible request headers

## CI/CD

### GitHub Actions Workflows

**`.github/workflows/test.yml`**
- Triggers: Push/PR to `main`
- Runs unit tests (skips snapshot tests)
- Uses `CODE_SIGNING_ALLOWED=NO` for CI compatibility

**`.github/workflows/release.yml`** (manual trigger)
- Extracts version from CHANGELOG.md
- Builds universal binary (x86_64 + arm64)
- Code signs with Developer ID
- Notarizes with Apple
- Creates GitHub release with signed ZIP
- Updates Homebrew tap (eddmann/homebrew-tap)

**`.github/workflows/deploy-pages.yml`**
- Deploys GitHub Pages landing page from `site/` directory

### Release Process
1. Update CHANGELOG.md with new version
2. Trigger release workflow manually
3. Workflow extracts version and release notes automatically
4. No local builds required

## Files to Never Commit

```
*.p12                    # Apple certificates
*.mobileprovision        # Provisioning profiles
xcuserdata/              # Xcode user data
DerivedData/             # Build output
build/                   # Local build directory
*.env                    # Environment files
.claudemeter/            # Local usage export (runtime)
```

## Adding New Features

### Adding a New Setting
1. Add property to `AppSettings` struct (make it Codable, Equatable, Sendable)
2. Settings auto-persist via `SettingsRepository` on change
3. Add UI control in `SettingsView` bound to `appModel.settings`
4. React to changes in `AppModel.scheduleSettingsSave()` if needed

### Adding a New API Endpoint
1. Define response model in `Models/API/`
2. Add method to protocol in `Services/Protocols/`
3. Implement in `NetworkService` or `UsageService` with retry logic
4. Add error handling in `NetworkError` or `AppError` if needed

### Adding a New Icon Style
1. Add case to `IconStyle` enum
2. Implement view in `Views/MenuBar/IconStyles/`
3. Add case to `MenuBarIconView` switch statement
4. Add preview to `MenuBarIconView` previews

## Development Tips

- **Demo Mode**: Pass `-demo-mode <mode>` launch argument in Xcode scheme for screenshot generation (DEBUG builds only)
- **Menu Bar**: App uses `NSStatusItem` with `NSPopover` (not MenuBarExtra) for better control
- **Refresh Loop**: Cancel existing `Task` before creating new ones to prevent duplicates
- **Wake Observer**: App refreshes usage when Mac wakes from sleep
- **Notifications**: Tapping notification opens usage popover via `NotificationCenter`

## External Integration

Usage data exported to `~/.claudemeter/usage.json`:
```json
{
  "last_updated": "2025-12-24T07:30:00Z",
  "session_usage": { "reset_at": "2025-12-24T12:00:00Z", "utilization": 29 },
  "sonnet_usage": { "reset_at": "2025-12-30T00:00:00Z", "utilization": 15 },
  "weekly_usage": { "reset_at": "2025-12-30T00:00:00Z", "utilization": 45 }
}
```

## License

MIT License - See LICENSE file for details.

**Disclaimer**: This is an unofficial tool not affiliated with Anthropic PBC. Using browser session keys may violate Claude.ai Terms of Service. Use at your own risk.
