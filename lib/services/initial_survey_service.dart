import 'package:shared_preferences/shared_preferences.dart';
import '../db/survey_database.dart';
import 'dart:convert';

/// Service for managing initial survey completion status and reminders
class InitialSurveyService {
  static const String _INITIAL_SURVEY_COMPLETED_KEY = 'initial_survey_completed';
  static const String _INITIAL_SURVEY_REMINDER_COUNT_KEY = 'initial_survey_reminder_count';
  static const String _LAST_REMINDER_DATE_KEY = 'last_initial_survey_reminder_date';
  
  // Reminder intervals (in days)
  static const int INITIAL_REMINDER_DELAY = 1; // First reminder after 1 day
  static const int SUBSEQUENT_REMINDER_INTERVAL = 3; // Then every 3 days
  static const int MAX_REMINDERS = 5; // Maximum number of reminders

  /// Check if the user has completed the initial survey
  static Future<bool> hasCompletedInitialSurvey() async {
    try {
      // First check SharedPreferences for quick access
      final prefs = await SharedPreferences.getInstance();
      final completedFromPrefs = prefs.getBool(_INITIAL_SURVEY_COMPLETED_KEY);
      
      print('[InitialSurveyService] completedFromPrefs: $completedFromPrefs');
      
      if (completedFromPrefs == true) {
        print('[InitialSurveyService] Survey marked as completed in SharedPreferences');
        return true;
      }
      
      // If not marked as completed in prefs, check the database
      final db = SurveyDatabase();
      final surveys = await db.getInitialSurveys();
      final hasCompleted = surveys.isNotEmpty;
      
      print('[InitialSurveyService] surveys from database: ${surveys.length}');
      print('[InitialSurveyService] hasCompleted from database: $hasCompleted');
      
      // Update SharedPreferences if we found a completed survey
      if (hasCompleted) {
        await prefs.setBool(_INITIAL_SURVEY_COMPLETED_KEY, true);
        print('[InitialSurveyService] Updated SharedPreferences with completion status');
      }
      
      return hasCompleted;
    } catch (e) {
      print('[InitialSurveyService] Error checking initial survey completion: $e');
      return false;
    }
  }

  /// Mark the initial survey as completed
  static Future<void> markInitialSurveyCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_INITIAL_SURVEY_COMPLETED_KEY, true);
      
      // Clear reminder count since survey is completed
      await prefs.remove(_INITIAL_SURVEY_REMINDER_COUNT_KEY);
      await prefs.remove(_LAST_REMINDER_DATE_KEY);
      
      print('[InitialSurveyService] Initial survey marked as completed');
    } catch (e) {
      print('[InitialSurveyService] Error marking initial survey as completed: $e');
    }
  }

  /// Reset the initial survey completion status (for testing purposes)
  static Future<void> resetInitialSurveyStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_INITIAL_SURVEY_COMPLETED_KEY);
      await prefs.remove(_INITIAL_SURVEY_REMINDER_COUNT_KEY);
      await prefs.remove(_LAST_REMINDER_DATE_KEY);
      
      print('[InitialSurveyService] Initial survey status reset');
    } catch (e) {
      print('[InitialSurveyService] Error resetting initial survey status: $e');
    }
  }

  /// Check if a reminder should be shown and return the reminder message
  static Future<String?> shouldShowReminder() async {
    try {
      // Don't show reminders if survey is already completed
      if (await hasCompletedInitialSurvey()) {
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      final reminderCount = prefs.getInt(_INITIAL_SURVEY_REMINDER_COUNT_KEY) ?? 0;
      
      // Don't show more reminders if we've reached the maximum
      if (reminderCount >= MAX_REMINDERS) {
        return null;
      }

      final lastReminderDateStr = prefs.getString(_LAST_REMINDER_DATE_KEY);
      final now = DateTime.now();
      
      // Determine if enough time has passed for the next reminder
      bool shouldShow = false;
      int daysSinceLastReminder = 0;
      
      if (lastReminderDateStr == null) {
        // No previous reminder, check if initial delay has passed
        // For this, we'll use the participation settings date as a reference
        final participationJson = prefs.getString('participation_settings');
        if (participationJson != null) {
          // We can't directly get the date from participation settings,
          // so we'll show the first reminder after the delay
          shouldShow = true;
        }
      } else {
        final lastReminderDate = DateTime.parse(lastReminderDateStr);
        daysSinceLastReminder = now.difference(lastReminderDate).inDays;
        shouldShow = daysSinceLastReminder >= SUBSEQUENT_REMINDER_INTERVAL;
      }

      if (shouldShow) {
        // Update reminder count and date
        await prefs.setInt(_INITIAL_SURVEY_REMINDER_COUNT_KEY, reminderCount + 1);
        await prefs.setString(_LAST_REMINDER_DATE_KEY, now.toIso8601String());
        
        // Return appropriate reminder message
        if (reminderCount == 0) {
          return 'Complete your initial survey to help us understand your background and provide personalized wellbeing insights!';
        } else if (reminderCount < 3) {
          return 'Your initial survey is still pending. It takes just 5-10 minutes and helps improve your wellbeing tracking experience.';
        } else {
          return 'Final reminder: Please complete your initial survey to unlock all app features and contribute to important wellbeing research.';
        }
      }
      
      return null;
    } catch (e) {
      print('[InitialSurveyService] Error checking reminder status: $e');
      return null;
    }
  }

  /// Force show a reminder dialog (for immediate use)
  static String getImmediateReminderMessage() {
    return 'Please complete your initial survey to get started with the full research experience. This helps us understand your background and provide better wellbeing insights.';
  }

  /// Check if user needs to complete the initial survey (for research/testing participants)
  static Future<bool> needsInitialSurvey() async {
    try {
      // Check if user is research participant or in testing mode
      final prefs = await SharedPreferences.getInstance();
      final participationJson = prefs.getString('participation_settings');
      
      print('[InitialSurveyService] participationJson: $participationJson');
      
      if (participationJson == null) {
        print('[InitialSurveyService] No participation settings - private user, no survey needed');
        return false; // Private users don't need initial survey
      }

      final participationData = jsonDecode(participationJson);
      final isResearchParticipant = participationData['isResearchParticipant'] ?? false;
      
      print('[InitialSurveyService] isResearchParticipant: $isResearchParticipant');
      
      if (!isResearchParticipant) {
        print('[InitialSurveyService] Not a research participant - no survey needed');
        return false; // Private users don't need initial survey
      }

      // Research participants need initial survey if not completed
      final hasCompleted = await hasCompletedInitialSurvey();
      print('[InitialSurveyService] hasCompletedInitialSurvey: $hasCompleted');
      
      final needsSurvey = !hasCompleted;
      print('[InitialSurveyService] needsInitialSurvey result: $needsSurvey');
      return needsSurvey;
    } catch (e) {
      print('[InitialSurveyService] Error checking if initial survey is needed: $e');
      return false;
    }
  }
}
