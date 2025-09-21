# Final Production Release Checklist - September 21, 2025

**Version:** 1.1.0  
**Release Date:** September 21, 2025  
**Critical Features:** Location data preservation during upgrades, encrypted data submission

## Overview

This document serves as the final validation checklist before releasing Wellbeing Mapper v1.1.0 to real research participants. All items must be verified and checked off before the production deployment.

---

## Core Migration & Upgrade Testing

### ✅ 1. Pilot-to-Production Migration Testing
**Critical:** Test upgrading from current production version to v1.1.0

- [ ] Install current production version on test device
- [ ] Complete initial consent and survey setup
- [ ] Add some location data (let app track for a few hours/days)
- [ ] Add some survey responses (both initial and biweekly)
- [ ] Upgrade to v1.1.0 via USB installation
- [ ] **Verify:** Location data is preserved and visible on map
- [ ] **Verify:** Content and surveys are reset (user sees consent screen again)
- [ ] **Verify:** User must retake initial survey
- [ ] **Verify:** Previous survey responses are cleared (research participants start fresh)
- [ ] **Verify:** App version shows 1.1.0 in side drawer

### ✅ 2. Production-to-Production Upgrade Testing  
**Critical:** Test standard version upgrade (e.g., 1.1.0 → 1.1.1)

- [ ] Install v1.1.0 on test device
- [ ] Complete full setup (consent, initial survey, some tracking)
- [ ] Create a test v1.1.1 build (minor version bump)
- [ ] Upgrade to v1.1.1 via USB installation
- [ ] **Verify:** ALL data is preserved (location, surveys, consent)
- [ ] **Verify:** No re-consent required
- [ ] **Verify:** No survey reset
- [ ] **Verify:** Seamless upgrade experience
- [ ] **Verify:** App version updates correctly in side drawer

---

## Data Transmission & Encryption Testing

### ✅ 3. End-to-End Qualtrics Integration
**Critical:** Verify all survey data reaches Qualtrics and can be decrypted

- [ ] Complete initial survey with test data
- [ ] Complete at least 2 biweekly surveys with test data
- [ ] Wait for data transmission (check app logs for successful uploads)
- [ ] Download data from Qualtrics dashboard
- [ ] Run decryption process using data analysis toolkit
- [ ] **Verify:** All survey responses are present and correctly decrypted
- [ ] **Verify:** Location data is properly encrypted and decryptable
- [ ] **Verify:** Participant codes are properly hashed
- [ ] **Verify:** Timestamps are accurate
- [ ] **Verify:** No data corruption or missing fields

---

## User Experience & Core Functionality

### ✅ 4. Complete UX Testing
**Critical:** Ensure participants can track themselves effectively over time

- [ ] **App Installation & Onboarding**
  - [ ] First-time installation flow works smoothly
  - [ ] Participant code validation works
  - [ ] Permission requests are clear and functional
  - [ ] Initial survey is intuitive and submits successfully

- [ ] **Location Tracking**
  - [ ] Background location tracking works consistently
  - [ ] Location points appear on map over time
  - [ ] Map navigation is smooth and responsive
  - [ ] Location data persists across app restarts

- [ ] **Survey Experience**
  - [ ] Biweekly survey notifications trigger correctly
  - [ ] Survey questions display properly
  - [ ] All input types work (sliders, dropdowns, text)
  - [ ] Survey submission works reliably

- [ ] **Data Visualization**
  - [ ] Users can view their location history on map
  - [ ] Users can see their survey response history
  - [ ] Data visualizations are meaningful and helpful
  - [ ] No data loss under normal usage patterns

- [ ] **Settings & Data Management**
  - [ ] Data retention settings work as expected
  - [ ] Users can clear data if desired
  - [ ] Privacy settings function correctly
  - [ ] App respects user data choices

### ✅ 5. Notification System Testing
**Critical:** Survey notifications must work reliably

- [ ] **Biweekly Survey Notifications**
  - [ ] Notifications trigger at correct intervals
  - [ ] Notification content is appropriate and clear
  - [ ] Tapping notification opens survey correctly
  - [ ] Notifications respect user's device settings

- [ ] **Notification Permissions**
  - [ ] App requests notification permissions appropriately
  - [ ] Handles permission denial gracefully
  - [ ] Users can enable notifications later if initially denied

- [ ] **Cross-Platform Testing**
  - [ ] Test notifications on multiple Android versions
  - [ ] Test with different device power management settings
  - [ ] Verify notifications work with app in background

### ✅ 6. Location Data Editing System
**Critical:** Users must be able to review/edit location data before survey submission

- [ ] **Location Review Interface**
  - [ ] Users can view recent location data before survey submission
  - [ ] Interface clearly shows which locations will be included
  - [ ] Users can select/deselect specific location points

- [ ] **Location Editing Functionality**
  - [ ] Users can remove sensitive location points
  - [ ] Users can adjust location accuracy if needed
  - [ ] Changes are reflected in final survey submission

- [ ] **Privacy Controls**
  - [ ] Users understand what location data is being shared
  - [ ] Editing interface is intuitive and non-technical
  - [ ] Users can submit surveys even if they remove all location data

---

## Technical Validation

### ✅ 7. Device Compatibility Testing

- [ ] **Android Testing**
  - [ ] Test on Android 8.0+ (minimum supported version)
  - [ ] Test on different screen sizes (phone/tablet)
  - [ ] Test with different hardware configurations
  - [ ] Verify app bundle installation from Play Store

- [ ] **Performance Testing**
  - [ ] App startup time is reasonable
  - [ ] Background location tracking doesn't drain battery excessively
  - [ ] No memory leaks during extended usage
  - [ ] Smooth performance with large datasets

### ✅ 8. Security & Privacy Validation

- [ ] **Encryption Verification**
  - [ ] All sensitive data is encrypted before transmission
  - [ ] Local data storage uses appropriate security measures
  - [ ] Participant codes are properly hashed, never stored in plain text

- [ ] **Network Security**
  - [ ] All API communications use HTTPS
  - [ ] Certificate pinning works correctly
  - [ ] No sensitive data in network logs

### ✅ 9. Error Handling & Edge Cases

- [ ] **Network Conditions**
  - [ ] App handles offline scenarios gracefully
  - [ ] Data queues properly when network is unavailable
  - [ ] Automatic retry mechanisms work
  - [ ] No data loss during network interruptions

- [ ] **Permission Edge Cases**
  - [ ] App handles location permission revocation
  - [ ] App handles notification permission changes
  - [ ] Graceful degradation when permissions are denied

- [ ] **Data Edge Cases**
  - [ ] Large datasets don't cause performance issues
  - [ ] App handles corrupted local data gracefully
  - [ ] Survey submissions work with unusual but valid input

---

## Pre-Release Documentation & Communication

### ✅ 10. Documentation Updates

- [ ] Update user guide with v1.1.0 features
- [ ] Verify installation instructions are current
- [ ] Update troubleshooting documentation
- [ ] Ensure research team has current participant onboarding materials

### ✅ 11. Research Team Preparation

- [ ] Provide updated APK to research team for final testing
- [ ] Brief research team on new features and any changes
- [ ] Ensure data analysis toolkit works with v1.1.0 data format
- [ ] Verify research team can decrypt and analyze test data

### ✅ 12. Deployment Preparation

- [ ] GitHub release is successfully created with all artifacts
- [ ] Play Store listing is ready (if using Play Store distribution)
- [ ] Beta testing group has validated the release
- [ ] Rollback plan is documented in case of critical issues

---

## Final Sign-Off

### ✅ Pre-Deployment Checklist Complete
- [ ] All above items tested and verified
- [ ] No critical bugs identified
- [ ] Performance meets requirements
- [ ] Research team approval obtained
- [ ] Documentation is current and complete

### ✅ Go/No-Go Decision
- [ ] **GO**: All critical functionality verified, ready for research participants
- [ ] **NO-GO**: Critical issues identified, requires additional fixes

---

## Notes & Issues Found

**Date:** _______________  
**Tester:** _______________

### Critical Issues (Must Fix Before Release)
_List any critical issues that must be resolved_

### Non-Critical Issues (Can Address in Future Updates)
_List any minor issues that can be addressed in subsequent releases_

### Additional Observations
_Any other notes about the release candidate_

---

**Final Approval:** _______________  
**Date:** _______________  
**Approved by:** _______________

---

*This checklist ensures that Wellbeing Mapper v1.1.0 is fully validated and ready for deployment to research participants. All items must be completed and verified before the production release.*