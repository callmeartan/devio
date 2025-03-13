# Data Isolation Verification Plan

This document outlines the testing plan for ensuring proper data isolation between Local Mode and Cloud Mode.

## Importance of Data Isolation

Data isolation is critical for the Local Mode feature because:

1. **Privacy:** Users choosing Local Mode expect their data to remain on their device only
2. **Security:** Preventing unintended data leakage to cloud services
3. **User Trust:** Maintaining the promise that Local Mode is truly local

## Test Scenarios

### 1. Mode Switching Data Isolation

**Setup:**
- Start in Cloud Mode
- Create chats and messages
- Switch to Local Mode

**Test Actions:**
- Verify no Cloud Mode chats appear in Local Mode
- Create new chats in Local Mode
- Switch back to Cloud Mode

**Expected Behavior:**
- Cloud Mode should only show cloud chats
- Local Mode should only show local chats
- No data should leak between modes

### 2. User Authentication Isolation

**Setup:**
- Log in with a user account in Cloud Mode
- Switch to Local Mode
- Switch back to Cloud Mode

**Expected Behavior:**
- User should remain logged in when returning to Cloud Mode
- Local Mode should use a separate local user identity
- Authentication tokens should not be used in Local Mode

### 3. Database Isolation

**Setup:**
- Create content in both modes
- Examine database files

**Test Actions:**
- Use database inspection tools to verify separate storage
- Check for any shared database connections

**Expected Behavior:**
- Local Mode should use separate database files/tables
- No cross-contamination of data between modes

### 4. Network Request Isolation

**Setup:**
- Enable network monitoring
- Use the app in Local Mode

**Test Actions:**
- Monitor all network traffic
- Perform various actions in Local Mode

**Expected Behavior:**
- No user data should be sent to cloud services
- No authentication or sync requests should occur
- Only essential non-user-data requests (e.g., app analytics if enabled) should be allowed

### 5. File Storage Isolation

**Setup:**
- Create and export content in both modes

**Test Actions:**
- Examine file storage locations
- Check for any shared file access

**Expected Behavior:**
- Local Mode should use separate file storage paths
- No access to cloud storage credentials in Local Mode

### 6. Preference Isolation

**Setup:**
- Set different preferences in each mode

**Test Actions:**
- Change settings in one mode
- Check if they affect the other mode

**Expected Behavior:**
- Mode-specific preferences should remain isolated
- Only app-wide preferences should be shared

## Verification Methods

1. **Code Review:**
   - Review repository factory implementation
   - Verify proper mode checking before data access
   - Check for any shared state between modes

2. **Database Inspection:**
   - Use database browser tools to inspect SQLite files
   - Verify separate tables or databases for each mode

3. **Network Monitoring:**
   - Use Charles Proxy or similar tools to monitor all network requests
   - Verify no user data is transmitted in Local Mode

4. **File System Inspection:**
   - Examine app sandbox to verify file separation
   - Check for proper path usage in file operations

## Reporting Issues

When reporting data isolation issues, please include:

1. Detailed steps to reproduce
2. Which data was found to leak between modes
3. Direction of leakage (Local → Cloud or Cloud → Local)
4. Any relevant logs or screenshots
5. Device and OS information 