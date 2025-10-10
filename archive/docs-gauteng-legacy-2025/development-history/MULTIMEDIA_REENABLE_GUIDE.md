# 📸 **Multimedia Re-enablement Guide**

## 🎯 **Overview**
Multimedia support (photos and audio) has been temporarily disabled to simplify the initial deployment. This guide shows how to re-enable it when needed.

## 🔄 **Quick Re-enablement Steps**

### **Step 1: Re-enable in Data Models**
**File:** `lib/models/survey_models.dart`

1. **InitialSurveyResponse class:**
   - Uncomment `voiceNoteUrls` and `imageUrls` field declarations
   - Uncomment constructor parameters
   - Uncomment toJson/fromJson entries

2. **RecurringSurveyResponse class:**
   - Uncomment `voiceNoteUrls` and `imageUrls` field declarations
   - Uncomment constructor parameters  
   - Uncomment toJson/fromJson entries

**Search for:** `TODO: MULTIMEDIA DISABLED` and uncomment the relevant lines.

### **Step 2: Re-enable in Database**
**File:** `lib/db/survey_database.dart`

1. **insertInitialSurvey method:**
   - Uncomment multimedia database insert lines
   
2. **insertRecurringSurvey method:**
   - Uncomment multimedia database insert lines
   
3. **getInitialSurveys/getRecurringSurveys methods:**
   - Uncomment multimedia database read lines

**Search for:** `TODO: MULTIMEDIA DISABLED` and uncomment the relevant lines.

### **Step 3: Re-enable in Qualtrics Surveys**
**File:** `lib/services/qualtrics_survey_creator.dart`

1. **_getInitialSurveyQuestions method:**
   - Uncomment `QID_VOICE_NOTE_URLS_BASELINE` and `QID_IMAGE_URLS_BASELINE`
   
2. **_getBiweeklySurveyQuestions method:**
   - Uncomment `QID_VOICE_NOTE_URLS` and `QID_IMAGE_URLS`

**Search for:** `TODO: MULTIMEDIA DISABLED` and uncomment the relevant lines.

### **Step 4: Add Multimedia Handler Service**
**File:** `lib/services/multimedia_handler.dart` (already created)

1. Configure Firebase Storage or your preferred cloud storage
2. Update storage bucket name and credentials
3. Add file upload/download logic to your survey screens

### **Step 5: Update Survey Screens**
Add file picker and upload functionality to your survey forms:

```dart
// Example for photo upload
File? selectedImage;

Future<void> _selectImage() async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  
  if (image != null) {
    selectedImage = File(image.path);
    
    // Upload to cloud storage
    final imageUrl = await MultimediaHandler.uploadImage(
      selectedImage!, 
      participantUuid
    );
    
    // Add to survey response
    setState(() {
      survey.imageUrls = [...survey.imageUrls ?? [], imageUrl];
    });
  }
}
```

### **Step 6: Re-create Qualtrics Surveys**
After uncommenting the multimedia questions:

1. Run `QualtricsSurveyCreator.createAllSurveys()` again
2. Update `QualtricsApiService` with new survey IDs
3. The surveys will now include multimedia URL fields

## 🎨 **Multimedia Implementation Strategies**

### **Strategy 1: URL-based (RECOMMENDED)**
- Upload files to Firebase Storage/AWS S3
- Store URLs in Qualtrics text fields
- Best performance and cost-effectiveness

### **Strategy 2: Qualtrics Native**
- Replace URL questions with FileUpload question types
- Files stored directly in Qualtrics
- Simpler but with limitations

### **Strategy 3: Hybrid Approach**
- Small files (voice notes) → Qualtrics native
- Large files (photos) → URL-based storage

## ⚡ **Dependencies to Add**
If re-enabling multimedia, add these to `pubspec.yaml`:

```yaml
dependencies:
  image_picker: ^1.0.4
  file_picker: ^6.1.1
  firebase_storage: ^11.5.6  # For URL-based approach
  path: ^1.8.3
```

## 🔍 **Testing Multimedia Re-enablement**

1. **Compile check:** Ensure all TODO comments are properly uncommented
2. **Database test:** Verify multimedia fields save/load correctly
3. **Qualtrics test:** Confirm surveys include multimedia questions
4. **Upload test:** Test file upload and URL storage
5. **Sync test:** Verify multimedia URLs sync to Qualtrics properly

## 💡 **Notes**
- All multimedia fields are nullable, so existing data remains compatible
- Database columns for multimedia already exist (they just store NULL values)
- Qualtrics survey structure is designed to accommodate multimedia easily
- The multimedia handler service provides ready-to-use upload functionality

This approach ensures multimedia can be enabled quickly without breaking existing functionality.
