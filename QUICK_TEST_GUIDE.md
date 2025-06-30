# Quick Test Guide

## 🚀 Fastest Way to Run Tests

```bash
# Navigate to project
cd v1_mother_edition

# Run tests directly
dart run test_active_matching.dart
```

## 📋 Alternative Methods

### Windows (Batch)
```cmd
run_tests.bat
```

### Windows (PowerShell)
```powershell
# If you get execution policy error, run:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Then run:
.\run_tests.ps1
```

### Mac/Linux (Shell)
```bash
chmod +x run_tests.sh
./run_tests.sh
```

## ⏱️ Expected Output Timeline

1. **0-5 seconds**: Firebase initialization
2. **5-10 seconds**: Database cleanup
3. **10-40 seconds**: 5 test scenarios
4. **40-50 seconds**: Final cleanup
5. **50+ seconds**: Results summary

## 🎯 Success Indicators

✅ All 5 tests show "PASSED"  
✅ Final message: "ALL TESTS COMPLETED SUCCESSFULLY!"  
✅ Clean exit with test data cleanup

## 🚨 Common Issues

**"Flutter not found"**
- Install Flutter: https://flutter.dev/docs/get-started/install
- Add Flutter to PATH

**"Firebase connection failed"**
- Check internet connection
- Verify firebase_options.dart exists

**"Permission denied"**
- Check Firebase Security Rules
- Ensure test script has write permissions

## 📞 Need Help?

If tests fail, copy the error output and check:
1. Firebase console for security rules
2. Internet connectivity
3. Flutter/Dart installation 