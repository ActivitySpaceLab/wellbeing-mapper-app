# 🧪 **IMMEDIATE TESTING GUIDE**
**Gauteng Wellbeing Mapper Production Testing**  
*Start testing now while iOS device is being prepared*

---

## 📱 **PHASE 1: Android Testing (START NOW)**

### **Your Device**: SM A536B ✅ **APP INSTALLED**

**The production app (v1.0.7+132) is now installed on your Android device.**

### **🎯 Priority Test Sequence (15-20 minutes)**

#### **Test 1: Fresh Install Experience** (5 min)
1. **Open the app** on your Android device
2. **Check startup**: Does it launch without crashes?
3. **Permissions**: Grant location and any other requested permissions
4. **Participation Screen**: Should show "Welcome to Gauteng Wellbeing Mapper"
5. **Choose Mode**: Select "Private Mode" for initial testing
6. **Result**: ✅/❌ Note any issues

#### **Test 2: Consent & Initial Survey** (8 min)
1. **Consent Flow**: Read through and accept consent
2. **Initial Survey**: Complete the survey using new slider controls
3. **Slider Test**: Verify new UX - sliders should start "not selected" and require interaction
4. **Submit**: Ensure survey submits successfully
5. **Success Message**: Should see appropriate success dialog
6. **Result**: ✅/❌ Note any issues

#### **Test 3: Happiness Survey** (3 min)
1. **Access Survey**: Tap happiness survey from main screen
2. **Location**: Allow location access if prompted
3. **Slider**: Test the improved happiness slider
4. **Submit**: Complete and submit survey
5. **Success**: Verify success message appears
6. **Result**: ✅/❌ Note any issues

#### **Test 4: App Persistence** (2 min)
1. **Close App**: Force-close the app (recent apps → swipe away)
2. **Reopen**: Launch app again
3. **Check State**: Should remember you're in private mode
4. **Data**: Previous surveys should be remembered
5. **Result**: ✅/❌ Note any issues

#### **Test 5: Migration System** (2 min)
*Note: This will only trigger if you had a pilot version previously*
1. **Check Startup**: Look for pilot user migration messages in console
2. **UI Elements**: Any special pilot user info displayed?
3. **Data**: App should function normally for fresh installs
4. **Result**: ✅/❌ Note any migration-related messages

---

## 📱 **PHASE 2: iOS Testing (When Connected)**

### **To Connect iPhone SE**:
1. **USB Cable**: Connect iPhone SE via Lightning cable
2. **Unlock Device**: Make sure iPhone is unlocked
3. **Trust Computer**: If prompted, tap "Trust This Computer"
4. **Developer Mode**: May need to enable in Settings → Privacy & Security → Developer Mode

### **Installation Command** (when ready):
```bash
cd /Users/palmer/projects/space_mapper_app/current/gauteng-wellbeing-mapper-app/gauteng-wellbeing-mapper-app 
flutter install -d "iPhone"
```

### **iOS Testing Focus**:
- Same 5 tests as Android above
- **Plus**: iOS-specific gesture handling
- **Plus**: Background app refresh behavior
- **Plus**: iOS permission dialogs

---

## 🐛 **Issue Logging Template**

**Copy this for each issue:**

```
**ISSUE #[X]**
Platform: Android/iOS
Test: [Test name]
Severity: Critical/High/Medium/Low

**Problem**: [Brief description]

**Steps**:
1. [Step 1]
2. [Step 2]  
3. [Step 3]

**Expected**: [What should happen]
**Actual**: [What happened]
**Screenshot**: [If helpful]
**Notes**: [Additional context]
```

---

## ⚡️ **CRITICAL SUCCESS CRITERIA**

### **❌ STOP & FIX if you see**:
- App crashes on startup
- Cannot complete consent flow
- Surveys don't save/submit
- Location permission completely broken
- Data doesn't persist between sessions

### **⚠️ NOTE & CONTINUE if you see**:
- Minor UI glitches
- Slightly slow performance
- Non-critical permission issues
- Cosmetic problems

### **✅ GOOD TO GO if**:
- App starts reliably
- Core survey flows work
- Data persists properly
- Location services function
- No crashes during normal use

---

## 📊 **Quick Results Summary**

**Android (SM A536B) Results:**
- Test 1 (Startup): ✅/❌
- Test 2 (Surveys): ✅/❌  
- Test 3 (Happiness): ✅/❌
- Test 4 (Persistence): ✅/❌
- Test 5 (Migration): ✅/❌
- **Overall**: ✅ Pass / ⚠️ Pass with issues / ❌ Fail

**iOS (iPhone SE) Results:**
- Test 1 (Startup): ✅/❌
- Test 2 (Surveys): ✅/❌
- Test 3 (Happiness): ✅/❌
- Test 4 (Persistence): ✅/❌
- Test 5 (Migration): ✅/❌
- **Overall**: ✅ Pass / ⚠️ Pass with issues / ❌ Fail

---

## 🚀 **Next Steps Based on Results**

### **If tests PASS**:
1. Create GitHub pre-release
2. Share with team for broader testing
3. Prepare store submissions

### **If CRITICAL issues found**:
1. Fix blocking issues immediately
2. Rebuild and retest
3. Document fixes made

### **If MINOR issues found**:
1. Log issues for post-release
2. Proceed with release if not blocking
3. Plan patch release if needed

---

**🎯 START WITH ANDROID TESTING NOW**  
*The app is already installed and ready to test!*