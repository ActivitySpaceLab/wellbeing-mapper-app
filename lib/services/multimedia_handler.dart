/// Service for handling multimedia data (photos and audio) in the survey system
/// 
/// MULTIMEDIA DATA STRATEGY:
/// 
/// Option 1: Store URLs in Qualtrics (RECOMMENDED)
/// - Upload files to cloud storage (Firebase Storage, AWS S3, etc.)
/// - Store URLs in Qualtrics text fields
/// - Benefits: Cost-effective, efficient, familiar infrastructure
/// 
/// Option 2: Qualtrics File Upload (ALTERNATIVE)
/// - Use Qualtrics' native file upload questions
/// - Limitations: File size limits, storage costs, mobile complexity
/// 
/// Option 3: Disable Multimedia (SIMPLEST)
/// - Remove photo/audio buttons for this version
/// - Focus on core survey functionality
/// 
/// This implementation provides Option 1 (URL-based) as the recommended approach.

import 'dart:io';
import 'dart:convert';
// TODO: MULTIMEDIA DISABLED - Uncomment imports when re-enabling multimedia
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:path/path.dart' as path;

class MultimediaHandler {
  // Firebase Storage configuration
  // static const String _storageBucket = 'wellbeing-mapper-multimedia'; // TODO: Implement when Firebase is configured
  
  /// Upload an image file and return the download URL
  static Future<String> uploadImage(File imageFile, String participantUuid) async {
    // TODO: MULTIMEDIA DISABLED - Return error or implement upload when re-enabled
    throw UnsupportedError('Multimedia functionality is currently disabled');
    
    /* COMMENTED OUT FOR MULTIMEDIA DISABLE - Uncomment to re-enable Firebase Storage uploads
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final ref = FirebaseStorage.instance
          .ref()
          .child('participant_images')
          .child(participantUuid)
          .child(fileName);
      
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
    */
  }
  
  /// Upload an audio file and return the download URL
  static Future<String> uploadAudio(File audioFile, String participantUuid) async {
    // TODO: MULTIMEDIA DISABLED - Return error or implement upload when re-enabled
    throw UnsupportedError('Multimedia functionality is currently disabled');
    
    /* COMMENTED OUT FOR MULTIMEDIA DISABLE - Uncomment to re-enable Firebase Storage uploads
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(audioFile.path)}';
      final ref = FirebaseStorage.instance
          .ref()
          .child('participant_audio')
          .child(participantUuid)
          .child(fileName);
      
      final uploadTask = await ref.putFile(audioFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload audio: $e');
    }
    */
  }
  
  /// Upload multiple files and return list of URLs
  static Future<List<String>> uploadMultipleImages(
    List<File> imageFiles, 
    String participantUuid
  ) async {
    final urls = <String>[];
    
    for (final file in imageFiles) {
      final url = await uploadImage(file, participantUuid);
      urls.add(url);
    }
    
    return urls;
  }
  
  /// Upload multiple audio files and return list of URLs
  static Future<List<String>> uploadMultipleAudio(
    List<File> audioFiles, 
    String participantUuid
  ) async {
    final urls = <String>[];
    
    for (final file in audioFiles) {
      final url = await uploadAudio(file, participantUuid);
      urls.add(url);
    }
    
    return urls;
  }
  
  /// Delete a file from storage (for data cleanup)
  static Future<void> deleteFile(String downloadUrl) async {
    // TODO: MULTIMEDIA DISABLED - Return or implement delete when re-enabled
    throw UnsupportedError('Multimedia functionality is currently disabled');
    
    /* COMMENTED OUT FOR MULTIMEDIA DISABLE - Uncomment to re-enable Firebase Storage deletes
    try {
      final ref = FirebaseStorage.instance.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      // File might already be deleted or URL invalid
      print('Warning: Could not delete file: $e');
    }
    */
  }
  
  /// Get file size constraints for the app
  static const int maxImageSizeMB = 10;
  static const int maxAudioSizeMB = 25;
  static const int maxImageSizeBytes = maxImageSizeMB * 1024 * 1024;
  static const int maxAudioSizeBytes = maxAudioSizeMB * 1024 * 1024;
  
  /// Validate file size before upload
  static bool isValidImageSize(File imageFile) {
    return imageFile.lengthSync() <= maxImageSizeBytes;
  }
  
  /// Validate audio file size before upload
  static bool isValidAudioSize(File audioFile) {
    return audioFile.lengthSync() <= maxAudioSizeBytes;
  }
}

/// Alternative implementation for Qualtrics native file upload
/// (Use this if you prefer Qualtrics' built-in file handling)
class QualtricsFileUploadHandler {
  
  /// Convert file to base64 for Qualtrics file upload questions
  static Future<String> fileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }
  
  /// Create Qualtrics file upload question definition
  static Map<String, dynamic> createFileUploadQuestion(
    String questionId, 
    String questionText, 
    {bool allowMultiple = false}
  ) {
    return {
      'QuestionID': questionId,
      'QuestionText': questionText,
      'QuestionType': 'FileUpload',
      'Validation': {
        'Settings': {
          'FileSize': '10', // MB
          'AllowedFileTypes': allowMultiple ? 
            ['jpg', 'jpeg', 'png', 'mp3', 'wav', 'm4a'] : 
            ['jpg', 'jpeg', 'png'],
        },
      },
    };
  }
}

/// Instructions for implementing multimedia in your survey screens
class MultimediaImplementationGuide {
  static void printInstructions() {
    print('''
=== MULTIMEDIA IMPLEMENTATION GUIDE ===

RECOMMENDED APPROACH (URL-based):

1. In your survey screens, when user selects photo/audio:
   ```dart
   // After user selects file
   final imageUrl = await MultimediaHandler.uploadImage(imageFile, participantUuid);
   
   // Add to survey response
   survey.imageUrls = [...survey.imageUrls ?? [], imageUrl];
   ```

2. In Qualtrics surveys, URLs are stored as text:
   - QID_IMAGE_URLS: "https://storage.../image1.jpg,https://storage.../image2.jpg"
   - QID_VOICE_NOTE_URLS: "https://storage.../audio1.mp3"

3. For data analysis, URLs can be processed to download files or generate previews.

ALTERNATIVE APPROACH (Qualtrics native):

1. Replace URL questions with file upload questions:
   ```dart
   QualtricsFileUploadHandler.createFileUploadQuestion(
     'QID_IMAGES', 
     'Upload photos related to your environmental challenges',
     allowMultiple: true
   )
   ```

2. Files are stored directly in Qualtrics with size/type restrictions.

SIMPLE APPROACH (Disable multimedia):

1. Remove photo/audio buttons from survey screens
2. Remove multimedia questions from Qualtrics surveys
3. Focus on text-based responses for environmental challenges

RECOMMENDATION:
Use URL-based approach with Firebase Storage for:
- Better mobile performance
- Lower costs
- More control over file management
- Easier integration with existing infrastructure
''');
  }
}
