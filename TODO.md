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

## Remaining Tasks
- [ ] Generate freezed files for the StorageModeCubit
- [ ] Implement local database schema for storing chat data
- [ ] Create local repositories for data persistence
- [ ] Add data export functionality
- [ ] Implement encryption for local data
- [ ] Add visual indicator in the app header when in Local Mode
- [ ] Create onboarding tooltips for first-time Local Mode users
- [ ] Test offline functionality
- [ ] Verify data isolation between modes
- [ ] Conduct security testing
- [ ] Perform usability testing

## Implementation Notes
1. **Local Storage**:
   - Using `SharedPreferences` for simple key-value storage
   - Using `flutter_secure_storage` for sensitive information
   - Need to implement SQLite for structured data

2. **Authentication Flow**:
   - Local Mode skips Firebase authentication
   - Creates a local user profile with a unique ID
   - Maintains session state locally

3. **Data Isolation**:
   - Local Mode data is completely isolated from cloud data
   - No data is transmitted to or synced with cloud services
   - Users start with a fresh profile when switching modes

4. **Security**:
   - Need to implement encryption for locally stored data
   - Need to communicate data recovery limitations to users

5. **User Experience**:
   - Added clear visual distinction for Local Mode
   - Need to add more onboarding for first-time users
   - Need to provide feedback when attempting to access cloud-only features

## Next Steps
1. Fix the linter errors by generating the freezed files
2. Implement the local database schema
3. Create local repositories for data persistence
4. Add visual indicators when in Local Mode
5. Test the implementation thoroughly 