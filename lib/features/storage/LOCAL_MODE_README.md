# Local Mode Feature

## Overview

Local Mode is a privacy-focused feature that allows users to use the app without syncing data to the cloud. All data is stored locally on the device, providing enhanced privacy and the ability to use the app offline.

## Key Features

- **Complete Privacy**: No data is sent to cloud services
- **Offline Usage**: Use the app without an internet connection
- **Data Export**: Export your chats as JSON files
- **Simple Switching**: Easily switch between Local and Cloud modes

## Implementation Details

### Storage Mode Management

The app uses a `StorageModeCubit` to manage the current storage mode (local or cloud). This cubit:

- Persists the selected mode using `SharedPreferences`
- Provides methods to switch between modes
- Notifies the app when the mode changes

### Authentication

In Local Mode:
- No Firebase authentication is required
- A local user profile is created with a unique ID
- Session state is maintained locally

### Data Storage

Local Mode uses:
- SQLite database for structured data (chats, messages)
- `SharedPreferences` for simple key-value storage
- `flutter_secure_storage` for sensitive information

### Repository Pattern

The app uses a repository pattern with:
- `RepositoryFactory` to provide the appropriate repository based on the storage mode
- `LocalChatRepository` for Local Mode
- `ChatRepository` for Cloud Mode

### Data Isolation

Local Mode ensures:
- Complete isolation of local and cloud data
- No data leakage between modes
- Separate storage paths for each mode

## Usage

### Switching to Local Mode

1. From the landing screen, tap the "Local Mode" button
2. OR from Settings, use the Storage Mode selector

### Exporting Data

1. Go to Settings
2. In the "Data Management" section (visible only in Local Mode):
   - Tap "Export All Chats" to export all chats
   - Tap "Export Current Chat" to export only the current chat

### Security Considerations

- Local data is protected by iOS built-in encryption when the device is locked
- Exported data is not encrypted, so handle exported files with care
- If the app is deleted, all local data will be lost permanently

## Testing

Comprehensive testing plans have been created for:
- Offline functionality
- Data isolation verification
- Security testing

See the `docs` folder for detailed testing plans.

## Limitations

- No automatic sync between Local and Cloud modes
- Data cannot be transferred between modes
- Limited recovery options if the app is deleted

## Future Enhancements

Potential future enhancements could include:
- Data migration between modes
- Enhanced export options (encrypted exports)
- Backup and restore functionality 