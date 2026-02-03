---
title: Overlay Black Screen and Apps Page Issues
status: draft
created: 2026-02-02
---

# Overlay Black Screen and Apps Page Issues - Requirements

## Overview
This spec addresses three critical issues in the PushLock app:
1. **Overlay Black Screen**: When opening locked apps, the overlay shows a completely black screen
2. **Apps Page Usage Time**: Usage time is stale and requires manual refresh
3. **Apps Page Lock Status**: Lock icon doesn't update immediately when locking/unlocking apps

## Problem Analysis

### Issue 1: Overlay Black Screen
**Current Flow:**
1. `AppLockService.kt` → `OverlayUi.kt` → launches MainActivity with intent
2. `MainActivity.kt` receives intent and calls method channel `showOverlay`
3. `main.dart` listens and navigates to `OverlayLockPage`
4. Result: Black screen (no UI elements visible)

**Root Causes:**
- Timing issue: Method channel called before Flutter engine is fully initialized
- MainActivity might not be in foreground when navigation is attempted
- The `overlayMain()` entry point exists but is unused, creating confusion
- Navigation happens via `pushAndRemoveUntil` which might be too aggressive

**Evidence from logs:**
```
I/SurfaceView@b32a442( 3153): surfaceCreated
E/gralloc4( 3153): ERROR: Format allocation info not found
```
Graphics buffer allocation errors indicate Flutter surface initialization failure.

### Issue 2: Apps Page Usage Time Not Updating
**Current Behavior:**
- Apps page shows stale usage time
- User must manually pull-to-refresh to see updated usage
- Home page has similar issue (previously worked)

**Root Cause:**
- `AppsBloc` loads data once on `LoadApps` event
- No automatic refresh when app comes to foreground
- `WidgetsBindingObserver` is implemented but only triggers on `didChangeAppLifecycleState`
- Room database stats are fetched but not continuously updated

### Issue 3: Lock Status UI Not Updating
**Current Behavior:**
- When locking/unlocking apps on apps page, lock icon doesn't update immediately
- UI requires manual refresh to show correct lock status

**Root Cause:**
- `AppsBloc` doesn't have events for lock/unlock operations
- Apps page doesn't listen to lock status changes
- No state update mechanism after lock/unlock operations

## User Stories

### US-1: Overlay Display
**As a** user  
**I want** the overlay to display correctly when I open a locked app  
**So that** I can see the push-up challenge screen and proceed to unlock the app

**Acceptance Criteria:**
- [ ] When opening a locked app, overlay shows white text on black87 background
- [ ] Lock icon, "PushLock" title, and push-up man SVG are visible
- [ ] "Start Push-ups" button is visible and functional
- [ ] No black screen or graphics errors occur
- [ ] Navigation to camera page works from overlay

### US-2: Real-time Usage Updates
**As a** user  
**I want** app usage times to update automatically  
**So that** I can see current usage without manually refreshing

**Acceptance Criteria:**
- [ ] Usage times update when app comes to foreground
- [ ] Usage times update periodically while app is in foreground (every 30 seconds)
- [ ] Both home page and apps page show current usage
- [ ] No manual refresh required to see updated usage
- [ ] Tab switching on apps page shows current usage for each category

### US-3: Immediate Lock Status Updates
**As a** user  
**I want** lock status to update immediately when I lock/unlock an app  
**So that** I can see the current state without refreshing

**Acceptance Criteria:**
- [ ] Lock icon updates immediately after locking an app
- [ ] Lock icon updates immediately after unlocking an app
- [ ] Works on both home page and apps page
- [ ] No manual refresh required
- [ ] State persists across tab switches

## Technical Requirements

### TR-1: Overlay Navigation Fix
**Objective:** Ensure Flutter engine is ready before navigation

**Implementation:**
1. Remove unused `overlayMain()` entry point from `main.dart`
2. Add Flutter engine ready check in MainActivity before invoking method channel
3. Use `pushReplacement` instead of `pushAndRemoveUntil` for overlay navigation
4. Add delay or callback to ensure MainActivity is in foreground
5. Add error handling and logging for navigation failures

**Files to Modify:**
- `lib/main.dart` - Remove `overlayMain()` and `OverlayApp` class
- `android/app/src/main/kotlin/com/example/pushlock/MainActivity.kt` - Add engine ready check
- `android/app/src/main/kotlin/com/example/pushlock/OverlayUi.kt` - Ensure proper intent flags

### TR-2: Apps Page Bloc Enhancement
**Objective:** Add lock/unlock events and automatic refresh

**Implementation:**
1. Add `LockAppRequested` and `UnlockAppRequested` events to `AppsBloc`
2. Add periodic timer for usage stats refresh (every 30 seconds)
3. Implement proper state updates after lock/unlock operations
4. Ensure category filter persists during refresh
5. Add lifecycle-aware refresh on app resume

**Files to Modify:**
- `lib/appsPage/bloc/apps_bloc.dart` - Add lock/unlock handlers and timer
- `lib/appsPage/bloc/apps_event.dart` - Add lock/unlock events
- `lib/appsPage/appsPage.dart` - Trigger bloc events on lock/unlock

### TR-3: Home Page Bloc Enhancement
**Objective:** Add periodic refresh for usage stats

**Implementation:**
1. Add periodic timer for usage stats refresh (every 30 seconds)
2. Ensure refresh doesn't interfere with user interactions
3. Maintain current state during background refresh

**Files to Modify:**
- `lib/homePage/bloc/homePage_bloc.dart` - Add timer for periodic refresh

### TR-4: Shared State Management
**Objective:** Ensure both pages reflect same data

**Implementation:**
1. Consider using a shared stream or event bus for lock status changes
2. Ensure cache updates propagate to both blocs
3. Add proper error handling for concurrent updates

**Files to Consider:**
- `lib/repositories/installed_apps_repository.dart` - Add change notification
- `lib/data/installed_apps_cache.dart` - Add listeners

## Implementation Plan

### Phase 1: Overlay Fix (High Priority)
1. Remove unused overlay entry point
2. Add MainActivity engine ready check
3. Fix navigation method
4. Test overlay display on locked app open

### Phase 2: Apps Page Lock Status (High Priority)
1. Add lock/unlock events to AppsBloc
2. Update apps page to trigger events
3. Implement state updates
4. Test immediate UI updates

### Phase 3: Usage Time Updates (Medium Priority)
1. Add periodic refresh timer to both blocs
2. Implement lifecycle-aware refresh
3. Test automatic updates
4. Optimize refresh frequency

### Phase 4: Testing & Polish (Low Priority)
1. Test all scenarios end-to-end
2. Add error handling
3. Optimize performance
4. Add logging for debugging

## Success Metrics
- [ ] Overlay displays correctly 100% of the time
- [ ] Usage times update within 30 seconds without manual refresh
- [ ] Lock status updates immediately (< 1 second)
- [ ] No black screen errors in logs
- [ ] No user complaints about stale data

## Technical Debt
- Remove unused `overlayMain()` code
- Clean up print statements (use proper logging)
- Fix file naming conventions (appsPage.dart → apps_page.dart)
- Remove unused imports
- Add proper error handling throughout

## Notes
- The overlay black screen is the most critical issue affecting core functionality
- Usage time updates are important for user experience
- Lock status updates are important for user confidence
- All three issues are interconnected through state management
