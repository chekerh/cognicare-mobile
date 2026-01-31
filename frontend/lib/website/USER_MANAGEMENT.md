# User Management Feature

## Overview

The admin dashboard now includes a comprehensive user management system that allows administrators to view, edit, and delete users.

## Features

### 1. User List View
- **View All Users**: Displays all users in the system with their details
- **Search**: Search by name or email in real-time
- **Filter by Role**: Filter users by role (All, Family, Doctor, Volunteer, Admin)
- **User Count**: Shows filtered count vs total count
- **Responsive Design**: Adapts to mobile and desktop layouts

### 2. User Information Display
Each user card shows:
- Profile avatar with initial
- Full name
- Email address
- Phone number (if available)
- Role badge with color coding:
  - **Admin**: Purple
  - **Doctor**: Yellow/Accent
  - **Volunteer**: Green/Secondary
  - **Family**: Blue/Primary

### 3. Edit User
- Click the edit icon to modify user details
- Editable fields:
  - Full Name
  - Email
  - Phone (optional)
  - Role (Family, Doctor, Volunteer, Admin)
- **Admin Promotion**: When promoting a user to admin, a warning message appears
- Updates are saved to the backend immediately
- Success/error notifications

### 4. Delete User
- Click the delete icon to remove a user
- Confirmation dialog before deletion
- Permanent deletion from the database
- Success/error notifications

### 5. Real-time Statistics
Dashboard now shows actual user counts:
- Total Users
- Families count
- Doctors count
- Volunteers count

## File Structure

```
frontend/lib/
  services/
    admin_service.dart           # Admin API service for user operations
  website/
    user_management_screen.dart  # User management UI
    admin_dashboard_screen.dart  # Updated with real stats
    main_web.dart                # Updated with route
```

## API Endpoints Used

- `GET /api/v1/users` - Fetch all users (with optional role filter)
- `GET /api/v1/users/:id` - Fetch single user by ID
- `PATCH /api/v1/users/:id` - Update user information
- `DELETE /api/v1/users/:id` - Delete user

## Usage

### Access User Management

1. Login as admin at `/admin-login`
2. Navigate to Admin Dashboard
3. Click "User Management" card
4. View and manage all users

### Search Users

Type in the search bar to filter by:
- User's full name
- Email address

### Filter by Role

Click on role filter chips:
- All Users
- Family
- Doctor
- Volunteer
- Admin

### Edit a User

1. Click the edit icon (pencil) on user card
2. Modify the fields in the dialog
3. Click "Save" to update
4. Changes are applied immediately

### Delete a User

1. Click the delete icon (trash) on user card
2. Confirm deletion in the dialog
3. User is permanently removed

## Security

- All operations require admin authentication
- JWT token must be valid and belong to an admin user
- Backend validates admin role on every request
- Unauthorized users are redirected to login

## Navigation Routes

- `/` - Landing page
- `/admin-login` - Admin login
- `/admin-dashboard` - Admin dashboard
- `/admin-users` - User management (new)

## Screenshots Flow

1. **Dashboard**: Shows "User Management" card
2. **User List**: All users with search and filters
3. **Edit Dialog**: Modal to edit user details
4. **Delete Confirmation**: Safety dialog before deletion

## Future Enhancements

- [ ] Pagination for large user lists
- [ ] Bulk operations (delete multiple users)
- [ ] Export users to CSV/Excel
- [ ] User activity logs
- [ ] Password reset for users (admin-initiated)
- [ ] User creation from admin panel
- [ ] Sort by name, email, role, date created

---

**Status**: ✅ Fully Implemented  
**Last Updated**: January 31, 2026
