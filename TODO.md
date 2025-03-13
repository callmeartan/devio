# Local Mode Implementation TODO

## Completed Tasks
- [x] Created `StorageMode` enum with `local` and `cloud` values
- [x] Implemented `StorageModeCubit` to manage the current storage mode
- [x] Created `LocalAuthService` for handling local authentication
- [x] Added "Local Mode" button to the landing screen
- [x] Updated the router to handle Local Mode navigation
- [x] Added `StorageModeSelector` to the settings screen
- [x] Updated the `AuthCubit` to handle Local Mode authentication
- [x] Added visual feedback when Local Mode is active
- [x] Implemented local database schema for storing chat data
- [x] Created local repositories for data persistence
- [x] Updated ChatCubit to work with both local and cloud repositories
- [x] Fixed ChatCubit to handle different repository implementations (local vs cloud)
- [x] Added data export functionality
- [x] Implemented missing repository methods in LocalChatRepository

## Remaining Tasks
- [ ] Generate freezed files for the StorageModeCubit
- [ ] Test offline functionality
- [ ] Verify data isolation between modes
- [ ] Create onboarding tooltips for first-time Local Mode users
- [ ] Conduct security testing
- [ ] Perform usability testing

## Implementation Notes
1. **Local Storage**:
   - Using `SharedPreferences` for simple key-value storage
   - Using `flutter_secure_storage` for sensitive information
   - Implemented SQLite for structured data with `LocalDatabaseService`
   - Relying on iOS built-in encryption for app data security

2. **Authentication Flow**:
   - Local Mode skips Firebase authentication
   - Creates a local user profile with a unique ID
   - Maintains session state locally

3. **Data Isolation**:
   - Local Mode data is completely isolated from cloud data
   - No data is transmitted to or synced with cloud services
   - Users start with a fresh profile when switching modes
   - Created `RepositoryFactory` to provide appropriate repositories based on storage mode

4. **Security**:
   - iOS provides built-in encryption for app data when device is locked
   - Need to communicate data recovery limitations to users

5. **User Experience**:
   - Added clear visual distinction for Local Mode
   - Need to add more onboarding for first-time users
   - Need to provide feedback when attempting to access cloud-only features
   - Added data export functionality for local chats

## Next Steps
1. Test the implementation thoroughly, especially offline functionality
2. Create onboarding tooltips for first-time Local Mode users
3. Verify data isolation between modes
4. Conduct security and usability testing 