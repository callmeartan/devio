# Offline Functionality Testing Plan

This document outlines the testing plan for ensuring that Local Mode works properly in offline scenarios.

## Test Scenarios

### 1. Initial App Launch in Offline Mode

**Setup:**
- Put device in Airplane Mode
- Clear app data or reinstall app
- Launch app

**Expected Behavior:**
- App should launch successfully
- User should be able to select Local Mode
- No error messages related to connectivity should appear

### 2. Switching to Local Mode While Offline

**Setup:**
- Launch app with internet connection
- Put device in Airplane Mode
- Switch to Local Mode

**Expected Behavior:**
- App should switch to Local Mode successfully
- No error messages related to connectivity should appear
- User should be able to use all Local Mode features

### 3. Creating and Managing Chats Offline

**Setup:**
- Launch app in Local Mode
- Put device in Airplane Mode

**Test Actions:**
- Create a new chat
- Send messages in the chat
- Switch between chats
- Delete a chat
- Pin/unpin chats

**Expected Behavior:**
- All chat operations should work normally
- No error messages related to connectivity should appear
- Changes should persist after app restart

### 4. Data Export While Offline

**Setup:**
- Launch app in Local Mode
- Create some chats and messages
- Put device in Airplane Mode

**Test Actions:**
- Navigate to Settings
- Export a chat
- Export all chats

**Expected Behavior:**
- Export functionality should work normally
- Exported files should contain all chat data
- Share functionality should work (though actual sharing may require connectivity depending on the sharing method)

### 5. Transition from Offline to Online

**Setup:**
- Launch app in Local Mode while offline
- Use the app (create chats, send messages)
- Turn on internet connection

**Expected Behavior:**
- App should continue to function normally
- No unexpected sync or connectivity errors should appear
- Local Mode data should remain isolated from cloud data

### 6. Transition from Online to Offline

**Setup:**
- Launch app in Cloud Mode
- Use the app (create chats, send messages)
- Turn off internet connection
- Switch to Local Mode

**Expected Behavior:**
- App should detect connectivity loss
- App should allow switching to Local Mode
- Local Mode should function normally without errors

## Test Matrix

| Test Case | iOS | Android |
|-----------|-----|---------|
| Initial App Launch in Offline Mode | ⬜ | ⬜ |
| Switching to Local Mode While Offline | ⬜ | ⬜ |
| Creating and Managing Chats Offline | ⬜ | ⬜ |
| Data Export While Offline | ⬜ | ⬜ |
| Transition from Offline to Online | ⬜ | ⬜ |
| Transition from Online to Offline | ⬜ | ⬜ |

## Edge Cases to Test

1. **Low Storage Space:**
   - Test Local Mode behavior when device storage is nearly full

2. **Intermittent Connectivity:**
   - Test with poor/intermittent network conditions
   - Rapidly toggle airplane mode on/off during operations

3. **Background/Foreground Transitions:**
   - Test putting app in background while operations are in progress
   - Test system interruptions (calls, notifications) during operations

4. **Device Restart:**
   - Test app behavior after device restart while in Local Mode

## Reporting Issues

When reporting issues with offline functionality, please include:

1. Device model and OS version
2. Steps to reproduce
3. Network state when issue occurred
4. Screenshots or screen recordings if possible
5. Any error messages displayed 