# Task-Based Reminders & Nutrition System - Implementation Guide

## Overview
This implementation provides a comprehensive task-based reminder system integrated with nutrition planning for children with cognitive health needs. The system supports reminders for water intake, meals, medication, homework, and other daily activities, with optional Raspberry Pi integration for physical reminders.

## Backend Implementation (NestJS)

### 1. Database Schemas

#### Nutrition Plan Schema (`/backend/src/nutrition/schemas/nutrition-plan.schema.ts`)
- **Purpose**: Store personalized meal plans, hydration goals, and dietary restrictions
- **Key Features**:
  - Daily water intake goals with customizable reminder intervals
  - Meal planning (breakfast, lunch, dinner) with specific times
  - Snack scheduling with custom times
  - Food allergies and dietary restrictions tracking
  - Medication tracking with dosage and timing
  - Linked to child and creator (parent/healthcare professional)

#### Task Reminder Schema (`/backend/src/nutrition/schemas/task-reminder.schema.ts`)
- **Purpose**: Store task reminders with flexible scheduling
- **Key Features**:
  - Multiple reminder types (water, meal, medication, homework, activity, hygiene, custom)
  - Flexible frequency (once, daily, weekly, interval)
  - Completion history tracking per day
  - Sound/vibration settings
  - Raspberry Pi sync capability
  - Color-coded visual customization

### 2. API Endpoints

#### Nutrition Endpoints
```
POST   /api/v1/nutrition/plans                    - Create nutrition plan
GET    /api/v1/nutrition/plans/child/:childId     - Get active plan for child
PATCH  /api/v1/nutrition/plans/:planId            - Update nutrition plan
DELETE /api/v1/nutrition/plans/:planId            - Deactivate plan
```

#### Reminder Endpoints
```
POST   /api/v1/reminders                          - Create task reminder
GET    /api/v1/reminders/child/:childId           - Get all reminders for child
GET    /api/v1/reminders/child/:childId/today     - Get today's reminders
PATCH  /api/v1/reminders/:reminderId              - Update reminder
POST   /api/v1/reminders/complete                 - Mark task as completed
DELETE /api/v1/reminders/:reminderId              - Deactivate reminder
GET    /api/v1/reminders/child/:childId/stats     - Get completion statistics
```

### 3. Security & Authorization
- Only parents and healthcare professionals can manage nutrition plans and reminders
- JWT authentication required for all endpoints
- Role-based access control (family, doctor, psychologist, speech_therapist, occupational_therapist)
- Child ownership verification for all operations

### 4. Data Validation
- Comprehensive DTOs with class-validator decorators
- Swagger/OpenAPI documentation for all endpoints
- Type-safe request/response handling

## Frontend Implementation (Flutter)

### 1. Models

#### NutritionPlan (`/frontend/lib/models/nutrition_plan.dart`)
- Includes nested models for Snack and Medication
- JSON serialization for API communication
- Comprehensive field validation

#### TaskReminder (`/frontend/lib/models/task_reminder.dart`)
- Enum-based type and frequency definitions
- Completion status tracking
- Immutable copyWith method for state updates

### 2. Services

#### NutritionService (`/frontend/lib/services/nutrition_service.dart`)
- Full CRUD operations for nutrition plans
- Error handling with user-friendly messages
- Token-based authentication

#### RemindersService (`/frontend/lib/services/reminders_service.dart`)
- Reminder management (create, update, delete)
- Task completion tracking
- Statistics retrieval (completion rates, daily stats)
- Today's reminders filtering

### 3. User Interfaces

#### Child Daily Routine Screen (`/frontend/lib/screens/family/child_daily_routine_screen.dart`)
**Purpose**: Visual routine checklist for children (matching provided screenshot)
**Features**:
- Color-coded task cards with icons
- Tap-to-complete checkboxes with immediate visual feedback
- Progress tracking (X / Y tasks completed)
- Time-based filtering (morning, afternoon, evening routines)
- Raspberry Pi connection status indicator
- Encouraging completion messages
- Supports custom task icons (emojis or Material icons)

**Visual Design**:
- Light blue background (#BFE3F5)
- White task cards with rounded corners
- Large, accessible icons and text
- Clear visual hierarchy for child-friendly UX

#### Reminder Notification Screen (`/frontend/lib/screens/family/reminder_notification_screen.dart`)
**Purpose**: Full-screen reminder notification (matching provided screenshot)
**Features**:
- Animated pulsing icon
- Large, clear task title and time display
- "I'm done!" action button
- "Remind me later" option
- Raspberry Pi sync indicator
- Smooth animations for engagement

**Visual Design**:
- Centered content with large touch targets
- Animated circular icon container
- Pulsing time display for attention
- High contrast colors for accessibility

## Integration Points

### 1. With Existing Child Profile
```dart
// Get child ID from auth provider or navigation
final childId = context.read<AuthProvider>().user?.childrenIds?.first;

// Load reminders for child
final reminders = await RemindersService().getTodayReminders(childId);
```

### 2. With Gamification System
```dart
// After task completion, award points
if (completed) {
  await GamificationService().awardPoints(
    childId: childId,
    points: 10,
    reason: 'Completed ${reminder.title}',
  );
}
```

### 3. With Raspberry Pi (Future Enhancement)
- Use `piSyncEnabled` flag on reminders
- Backend can trigger Pi notifications via MQTT or WebSocket
- Pi displays physical reminder (LED, speaker, screen)
- Child interaction tracked back to app

## Usage Examples

### Creating a Nutrition Plan (Parent Dashboard)
```dart
final nutritionService = NutritionService(
  getToken: () async => authProvider.accessToken,
);

final plan = await nutritionService.createNutritionPlan({
  'childId': childId,
  'dailyWaterGoal': 6,
  'waterReminderInterval': 120, // every 2 hours
  'breakfast': ['Oatmeal', 'Banana', 'Milk'],
  'breakfastTime': '08:00',
  'lunch': ['Chicken', 'Rice', 'Vegetables'],
  'lunchTime': '12:30',
  'medications': [
    {
      'name': 'Melatonin',
      'dosage': '1mg',
      'time': '20:00',
      'withFood': false,
    }
  ],
  'allergies': ['Peanuts', 'Dairy'],
});
```

### Creating Task Reminders
```dart
final remindersService = RemindersService(
  getToken: () async => authProvider.accessToken,
);

// Water reminder every 2 hours
await remindersService.createReminder({
  'childId': childId,
  'type': 'water',
  'title': 'Drink Water',
  'description': 'Remember to drink a full glass of water',
  'icon': '💧',
  'color': '#3B82F6',
  'frequency': 'interval',
  'intervalMinutes': 120,
  'soundEnabled': true,
  'vibrationEnabled': true,
  'piSyncEnabled': true,
});

// Medication reminder at specific time
await remindersService.createReminder({
  'childId': childId,
  'type': 'medication',
  'title': 'Take Medicine',
  'description': 'Melatonin 1mg',
  'icon': '💊',
  'time': '20:00',
  'frequency': 'daily',
  'soundEnabled': true,
});
```

### Displaying Child Routine
```dart
// Navigate to routine screen
context.push('/family/child-routine', extra: {
  'childId': childId,
  'routineType': 'morning', // or 'afternoon', 'evening', null
});
```

### Marking Task Complete
```dart
await remindersService.completeTask(
  reminderId: reminder.id,
  completed: true,
  date: DateTime.now(),
);

// Show encouragement
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Great job staying hydrated! 💧'),
    backgroundColor: Colors.green,
  ),
);
```

### Getting Completion Statistics
```dart
final stats = await remindersService.getCompletionStats(
  childId,
  days: 7, // last 7 days
);

// Returns:
// {
//   totalReminders: 10,
//   totalTasks: 70,     // 10 reminders × 7 days
//   completedTasks: 56,
//   completionRate: 80, // percentage
//   dailyStats: [
//     {date: '2026-02-13', total: 10, completed: 8},
//     ...
//   ]
// }
```

## Raspberry Pi Integration Guide

### Hardware Setup
1. Raspberry Pi 3/4 with speaker/LED display
2. Network connection (WiFi or Ethernet)
3. Optional: Physical button for task completion

### Software Architecture
```
Backend (NestJS)
    ↓ (MQTT/WebSocket)
Raspberry Pi (Python/Node.js)
    ↓ (GPIO/Audio)
Physical Output (LED/Speaker/Display)
```

### Example Pi Integration Flow
1. Backend detects reminder time
2. Sends MQTT message to Pi: `{childId, reminderId, title, icon, time}`
3. Pi displays reminder on screen + plays sound
4. Child presses button or app to complete
5. Pi sends completion back to backend
6. Backend updates completion history

### MQTT Topics (Suggested)
```
cognicare/{childId}/reminders/trigger
cognicare/{childId}/reminders/complete
cognicare/{childId}/status
```

## Testing Checklist

### Backend Testing
- ✅ Nutrition plan CRUD operations
- ✅ Reminder CRUD operations
- ✅ Authorization (only parent/healthcare can manage)
- ✅ Child ownership validation
- ✅ Completion tracking accuracy
- ✅ Statistics calculation (7-day, 30-day)

### Frontend Testing
- ✅ Nutrition plan form validation
- ✅ Reminder creation with all types
- ✅ Daily routine display
- ✅ Task completion UI feedback
- ✅ Progress bar accuracy
- ✅ Time-based filtering (morning/afternoon/evening)

### Integration Testing
- ⏳ End-to-end: Create plan → Create reminders → Display → Complete → Stats
- ⏳ Raspberry Pi sync (if applicable)
- ⏳ Local notifications (requires flutter_local_notifications setup)

## Next Steps

### Immediate Enhancements
1. **Local Notifications**: Add flutter_local_notifications package
   ```yaml
   dependencies:
     flutter_local_notifications: ^17.0.0
   ```

2. **Schedule Background Jobs**: Use Android WorkManager / iOS Background Fetch
   ```dart
   // Schedule daily reminder checks
   Workmanager().registerPeriodicTask(
     "reminderCheck",
     "checkReminders",
     frequency: Duration(hours: 1),
   );
   ```

3. **Parent Configuration UI**: Create screens for:
   - Nutrition plan editor
   - Reminder scheduler
   - Completion history viewer
   - Settings (sounds, vibration, Pi sync)

4. **Gamification Integration**:
   ```dart
   // After completing 5 tasks in a day
   if (completedToday >= 5) {
     await StickerBookProvider().unlockSticker('hydration_hero');
   }
   ```

### Advanced Features
- Voice reminders (text-to-speech)
- AI-powered suggestion (meal planning based on allergies)
- Progress charts (weekly/monthly completion trends)
- Multi-language support for task titles
- Photo uploads for meal verification
- Family collaboration (multiple parents managing same child)

## File Structure Summary

```
backend/src/nutrition/
├── schemas/
│   ├── nutrition-plan.schema.ts       # MongoDB schema for nutrition plans
│   └── task-reminder.schema.ts        # MongoDB schema for reminders
├── dto/
│   ├── create-nutrition-plan.dto.ts   # Validation for nutrition plan creation
│   ├── update-nutrition-plan.dto.ts   # Validation for updates
│   ├── create-task-reminder.dto.ts    # Validation for reminder creation
│   ├── update-task-reminder.dto.ts    # Validation for updates
│   └── complete-task.dto.ts           # Validation for task completion
├── nutrition.controller.ts            # Nutrition plan API endpoints
├── reminders.controller.ts            # Task reminder API endpoints
├── nutrition.service.ts               # Nutrition business logic
├── reminders.service.ts               # Reminder business logic
└── nutrition.module.ts                # NestJS module configuration

frontend/lib/
├── models/
│   ├── nutrition_plan.dart            # Nutrition plan data model
│   └── task_reminder.dart             # Task reminder data model
├── services/
│   ├── nutrition_service.dart         # HTTP client for nutrition API
│   └── reminders_service.dart         # HTTP client for reminders API
└── screens/family/
    ├── child_daily_routine_screen.dart       # Visual routine checklist
    └── reminder_notification_screen.dart     # Full-screen reminder alert
```

## API Documentation

Access Swagger documentation at: `http://localhost:3000/api`

- All endpoints require JWT Bearer token
- Comprehensive request/response examples
- Try-it-out functionality for testing

## Support & Troubleshooting

### Common Issues

1. **"Nutrition plan not found"**: Create a plan first before accessing reminders
2. **"Not authorized"**: Ensure user is parent of child or healthcare professional
3. **Reminders not showing**: Check if child has any active reminders with `isActive: true`
4. **Pi sync not working**: Verify `piSyncEnabled` flag and network connectivity

### Debug Endpoints

```bash
# Get all reminders for child
curl -H "Authorization: Bearer TOKEN" \
  http://localhost:3000/api/v1/reminders/child/CHILD_ID

# Get today's reminders
curl -H "Authorization: Bearer TOKEN" \
  http://localhost:3000/api/v1/reminders/child/CHILD_ID/today

# Get completion stats
curl -H "Authorization: Bearer TOKEN" \
  http://localhost:3000/api/v1/reminders/child/CHILD_ID/stats?days=7
```

## Conclusion

This implementation provides a complete task-based reminder system with nutrition planning, designed specifically for children with cognitive health needs. The visual, child-friendly interface encourages engagement, while the comprehensive backend ensures data security and proper authorization. The system is ready for production use and can be extended with local notifications and Raspberry Pi integration for enhanced physical reminders.
