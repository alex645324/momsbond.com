#!/bin/bash

echo ""
echo "================================================================================"
echo "                    ACTIVE USER MATCHING TEST RUNNER"
echo "================================================================================"
echo ""

echo "🔧 Checking Flutter environment..."
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found! Please install Flutter and add it to PATH"
    exit 1
fi

flutter --version

echo ""
echo "🧪 Running Active User Matching Tests..."
echo ""

dart run test_active_matching.dart

echo ""
echo "📊 Test execution completed."
echo "" 