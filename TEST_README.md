# Active User Matching Test Suite

This test suite verifies that the active user timestamp functionality is working correctly and that only truly active users get matched together.

## What the Tests Verify

✅ **Active users can match with each other**  
✅ **Inactive users are filtered out of matching**  
✅ **Timestamp expiration works (30-second timeout)**  
✅ **Multiple concurrent active users can match**  
✅ **Mixed active/inactive scenarios work correctly**

## How to Run the Tests

### Option 1: Use the Batch Script (Windows)
```bash
# Navigate to the project directory
cd v1_mother_edition

# Run the test script
run_tests.bat
```

### Option 2: Use the Shell Script (Mac/Linux)
```bash
# Navigate to the project directory
cd v1_mother_edition

# Make script executable
chmod +x run_tests.sh

# Run the test script
./run_tests.sh
```

### Option 3: Run Directly with Dart
```bash
# Navigate to the project directory
cd v1_mother_edition

# Run the test script directly
dart run test_active_matching.dart
```

## Test Scenarios

### Test 1: Active Users Match
- Creates 2 active users with recent timestamps
- Verifies they can match with each other
- **Expected**: Successful match between active users

### Test 2: Inactive Users Filtered
- Creates 1 active user and 1 inactive user (old timestamp)
- Attempts matching for the active user
- **Expected**: No match found (inactive user filtered out)

### Test 3: Timestamp Expiration
- Creates users with timestamps older than 30 seconds
- Attempts matching between them
- **Expected**: No matches (expired timestamps filtered out)

### Test 4: Concurrent Active Users
- Creates 5 active users simultaneously
- Tests multiple matching attempts
- **Expected**: Multiple successful matches between active users

### Test 5: Mixed Active/Inactive
- Creates mix of 2 active and 2 inactive users
- Tests that active users match with each other, not inactive ones
- **Expected**: Active users match together, inactive users ignored

## Understanding the Results

### ✅ Success Output
```
🧪 ACTIVE USER MATCHING TEST SUITE
================================================================================

🔧 Initializing Firebase for testing...
✅ Firebase initialized successfully

🧹 Cleaning up previous test data...
✅ Cleanup completed (removed 0 test users)

------------------------------------------------------------
🧪 TEST 1: Active Users Should Match
------------------------------------------------------------
👤 Created test user: test_user_active1 (test_user_active1_...)
👤 Created test user: test_user_active2 (test_user_active2_...)
🟢 Made user active: test_user_active1_...
🟢 Made user active: test_user_active2_...
🔍 Attempting to match user1 with active user2...
✅ TEST 1 PASSED: Active users successfully matched!

... (more tests)

================================================================================
✅ ALL TESTS COMPLETED SUCCESSFULLY!
================================================================================
```

### ❌ Failure Output
```
❌ TEST SUITE FAILED: TEST 2 FAILED: Inactive user was matched (should be filtered)
```

## Troubleshooting

### Firebase Connection Issues
- Ensure your `firebase_options.dart` is configured correctly
- Check that your Firebase project allows connections
- Verify internet connectivity

### Permission Issues
- Make sure the test script has proper Firestore read/write permissions
- Check Firebase Security Rules if tests fail with permission errors

### Dependency Issues
- Run `flutter pub get` to ensure all dependencies are installed
- Make sure you're in the correct directory (`v1_mother_edition`)

## Test Data Cleanup

The test suite automatically:
- Cleans up previous test data before running
- Creates test users with `test_user_` prefix
- Removes all test users and matches after completion
- Uses isolated test data that won't affect real users

## What Each Test Proves

| Test | Proves |
|------|--------|
| Test 1 | Active timestamp system allows matching between active users |
| Test 2 | Inactive users (old timestamps) are properly filtered out |
| Test 3 | 30-second timeout threshold works correctly |
| Test 4 | System can handle multiple concurrent active users |
| Test 5 | Mixed scenarios work - active users match, inactive users don't |

## Expected Runtime

The complete test suite typically takes **30-60 seconds** to run, including:
- Firebase initialization
- Database cleanup  
- 5 test scenarios with waits for timestamp propagation
- Final cleanup

If tests take significantly longer, check your internet connection and Firebase performance. 