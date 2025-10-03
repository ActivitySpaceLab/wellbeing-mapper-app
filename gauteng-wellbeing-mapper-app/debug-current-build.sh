#!/bin/bash

# Quick debug script to test the current build
# Usage: ./debug-current-build.sh

echo "🔍 DEBUGGING CURRENT BUILD"
echo "=========================="

# Connect to device and start logging
echo "📱 Starting ADB logcat for app debugging..."
echo ""
echo "🔎 Looking for these key patterns:"
echo "   - [EncryptedSurveyService] (upload attempts)"
echo "   - [AppModeService] (mode operations)"  
echo "   - [ParticipationSelection] (mode switching)"
echo "   - ✅ or ❌ (success/failure indicators)"
echo ""
echo "Press Ctrl+C to stop logging"
echo ""

adb logcat | grep -E "(EncryptedSurveyService|AppModeService|ParticipationSelection|✅|❌|ERROR|WARN)"