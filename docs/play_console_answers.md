# Play Console Answers

## Location Permissions

**App purpose**

The main purpose of the app is to let users map their mental wellbeing over time and as they move around their activity spaces.

**Location access**

The app needs to access background location so that it can map users' activity spaces and link their mental wellbeing to geographic locations where they spend time.

## Android Declarations

**Foreground service**

The app uses foreground service permissions for background location tracking. The relevant type is location, and the feature supports continuous location collection while the app is not in the foreground.

**Sensitive permissions**

The app uses background location so it can map activity spaces and connect wellbeing data to places where users spend time.

The app also requests notifications for reminders and boot completed so scheduled reminders can be restored after device restart.

**Notes**

If Play Console asks for video evidence, the most useful demo is the app starting tracking, moving to the background, and showing that location tracking continues.