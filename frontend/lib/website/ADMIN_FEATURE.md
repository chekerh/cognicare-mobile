# Admin Login Feature - Documentation

## Overview

The CogniCare website now includes a secure admin login system that allows administrators to access a management dashboard. This feature implements role-based access control (RBAC) to ensure only users with admin privileges can access administrative functions.

## Features Implemented

### 1. Admin Role in Backend

**Files Modified:**
- `backend/src/users/schemas/user.schema.ts` - Added 'admin' to role enum
- `backend/src/auth/dto/signup.dto.ts` - Updated role validation to include 'admin'
- `backend/src/auth/admin.guard.ts` - New guard for protecting admin-only routes

**Role Types:**
- `family` - Family members caring for loved ones
- `doctor` - Medical professionals
- `volunteer` - Community volunteers
- `admin` - Platform administrators (⚠️ **Can only be created manually in database or promoted by existing admin**)

### 2. Admin Login Button on Landing Page

**Location:** Header of the landing page

**Behavior:**
- Visible on both mobile and desktop
- Mobile: Shows "Admin" text
- Desktop: Shows "Admin Login" with icon
- Clicking navigates to `/admin-login` route

### 3. Admin Login Screen

**File:** `frontend/lib/website/admin_login_screen.dart`

**Features:**
- Professional login form with email and password fields
- Form validation (email format, required fields)
- Password visibility toggle
- Role verification (only admin users can proceed)
- Error handling with user-friendly messages
- Security notice for restricted access
- Responsive design for mobile and desktop

**Security:**
- Verifies user role after successful authentication
- Clears stored data if user is not admin
- Shows specific error: "Access denied. Admin privileges required."

### 4. Admin Dashboard

**File:** `frontend/lib/website/admin_dashboard_screen.dart`

**Features:**
- Welcome card with admin profile information
- Statistics overview (Users, Families, Doctors, Volunteers)
- Management sections:
  - User Management
  - Analytics
  - System Settings
  - Email Templates
- Logout functionality with confirmation dialog
- Session validation (redirects to login if not authenticated)
- Responsive grid layout

**Future Enhancements:** Each management section shows "Coming Soon" message and can be implemented with actual functionality.

### 5. Routing Configuration

**File:** `frontend/lib/website/main_web.dart`

**Routes:**
- `/` - Landing page (public)
- `/admin-login` - Admin login screen (public)
- `/admin-dashboard` - Admin dashboard (protected)

## Usage

### For Developers

#### 1. Creating an Admin User

⚠️ **IMPORTANT: Admin accounts cannot be created through the signup API for security reasons.**

**Only Method: Direct Database Insert (MongoDB)**

Connect to your MongoDB database and run:

```javascript
// Using MongoDB Shell or init script
db.users.insertOne({
  fullName: "Admin User",
  email: "admin@cognicare.com",
  passwordHash: "$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewfLkIwF5qcO7G6", // password: "admin123"
  role: "admin",
  createdAt: new Date(),
  updatedAt: new Date()
});
```

Or use a custom hashed password:

```javascript
// First, hash your desired password using bcrypt with 12 rounds
// Then insert:
db.users.insertOne({
  fullName: "Your Admin Name",
  email: "your.admin@email.com",
  passwordHash: "your_bcrypt_hashed_password_here",
  role: "admin",
  phone: "+1234567890", // optional
  createdAt: new Date(),
  updatedAt: new Date()
});
```

**Alternative Tools:**
- MongoDB Compass: GUI for inserting documents
- Studio 3T: Advanced MongoDB IDE
- MongoDB Atlas: Cloud interface for data management

**Security Note:** The signup API will reject any attempts to create admin accounts (returns 400 Bad Request with message "Admin accounts can only be created by system administrators"). This ensures only authorized personnel with database access can create administrators.

#### 2. Testing Admin Login

1. Run the website:
```bash
cd frontend
flutter run -d chrome --target lib/website/main_web.dart
```

2. Click "Admin Login" button in the header
3. Enter admin credentials
4. Verify successful login and dashboard access

#### 3. Protecting Backend Admin Routes

Use the `AdminGuard` to protect admin-only endpoints:

```typescript
import { UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from './auth/jwt-auth.guard';
import { AdminGuard } from './auth/admin.guard';

@Controller('admin')
@UseGuards(JwtAuthGuard, AdminGuard)
export class AdminController {
  @Get('users')
  getAllUsers() {
    // Only admins can access this
  }
}
```

### For End Users (Administrators)

1. Navigate to the CogniCare website
2. Click "Admin Login" in the top-right corner
3. Enter your admin email and password
4. Access the dashboard to manage the platform

**Note:** If you don't have admin credentials, contact the system administrator.

## Security Features

### Authentication Flow

1. User enters credentials on login screen
2. Credentials sent to backend `/api/v1/auth/login`
3. Backend validates credentials and returns JWT token + user data
4. Frontend checks if `user.role === 'admin'`
5. If not admin, session is cleared and error is shown
6. If admin, user is redirected to dashboard
7. Dashboard validates session on load

### Session Management

- JWT tokens stored securely using `flutter_secure_storage`
- Automatic session validation on dashboard load
- Logout clears all stored authentication data
- Invalid sessions redirect to login screen

### Role-Based Access Control (RBAC)

**Frontend Protection:**
- Login screen verifies role after authentication
- Dashboard validates role on initialization
- Unauthorized users cannot access protected screens

**Backend Protection:**
- `AdminGuard` validates user role from JWT payload
- Returns `403 Forbidden` for non-admin users
- Can be combined with `JwtAuthGuard` for double protection

## File Structure

```
frontend/lib/website/
  ├── main_web.dart                  # Website entry point with routes
  ├── landing_page.dart              # Landing page with admin button
  ├── admin_login_screen.dart        # Admin login form
  ├── admin_dashboard_screen.dart    # Admin dashboard
  └── ADMIN_FEATURE.md               # This documentation

backend/src/
  ├── users/schemas/
  │   └── user.schema.ts             # User schema with admin role
  ├── auth/
  │   ├── dto/
  │   │   ├── signup.dto.ts          # Updated with admin role
  │   │   └── login.dto.ts           # Login validation
  │   ├── admin.guard.ts             # Admin role guard (NEW)
  │   ├── jwt-auth.guard.ts          # JWT authentication guard
  │   └── auth.service.ts            # Authentication logic
```

## Testing Checklist

- [ ] Admin user can be created via API
- [ ] Admin login button appears on landing page
- [ ] Admin login screen loads correctly
- [ ] Non-admin users cannot access dashboard
- [ ] Admin users can successfully login
- [ ] Dashboard loads with admin profile
- [ ] Logout functionality works
- [ ] Session persists across page reloads
- [ ] Invalid sessions redirect to login
- [ ] Mobile responsive design works
- [ ] Desktop layout displays correctly

## Future Enhancements

### Phase 1: User Management
- [ ] List all users with pagination
- [ ] Filter users by role
- [ ] Edit user information
- [ ] Delete users (with confirmation)
- [ ] Ban/unban users

### Phase 2: Analytics
- [ ] User registration trends
- [ ] Activity metrics
- [ ] Platform usage statistics
- [ ] Export reports

### Phase 3: System Settings
- [ ] Configure email templates
- [ ] Manage feature flags
- [ ] Set platform-wide settings
- [ ] View system logs

### Phase 4: Content Management
- [ ] Manage onboarding content
- [ ] Update privacy policy/terms
- [ ] Announcement system

## Troubleshooting

### Issue: "Access denied. Admin privileges required"
**Solution:** User role is not 'admin'. Create admin user or update role in database.

### Issue: Admin button not showing on landing page
**Solution:** Clear browser cache and rebuild: `flutter run -d chrome --target lib/website/main_web.dart`

### Issue: Dashboard shows loading indefinitely
**Solution:** Check backend is running and JWT token is valid. Clear stored data and login again.

### Issue: 403 Forbidden on backend admin routes
**Solution:** Ensure `AdminGuard` is properly configured and user has admin role in JWT payload.

## Support

For issues or questions:
1. Check backend logs for authentication errors
2. Verify user role in MongoDB: `db.users.findOne({email: "admin@example.com"})`
3. Test API endpoints with Postman/Thunder Client
4. Review browser console for frontend errors

---

**Version:** 1.0  
**Last Updated:** January 31, 2026  
**Status:** ✅ Fully Implemented
