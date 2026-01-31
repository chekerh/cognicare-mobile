# Admin Role Security Implementation

## Overview

Admin role creation has been secured to prevent unauthorized elevation of privileges. Normal users **cannot** create admin accounts through the signup API.

## Security Measures Implemented

### 1. DTO Validation (Frontend Contract)
**File:** `backend/src/auth/dto/signup.dto.ts`

- Removed `'admin'` from the allowed enum values in SignupDto
- Valid roles for signup: `'family' | 'doctor' | 'volunteer'`
- Swagger documentation updated to reflect this restriction

```typescript
@IsEnum(['family', 'doctor', 'volunteer'])
role: 'family' | 'doctor' | 'volunteer';
```

### 2. Service-Level Validation (Backend Protection)
**File:** `backend/src/auth/auth.service.ts`

- Explicit check in the `signup()` method
- Throws `BadRequestException` if someone attempts to create admin account
- Error message: "Admin accounts can only be created by system administrators"

```typescript
// Prevent admin role creation through signup
if (userData.role === 'admin') {
  throw new BadRequestException('Admin accounts can only be created by system administrators');
}
```

### 3. Database Schema (Data Integrity)
**File:** `backend/src/users/schemas/user.schema.ts`

- User schema still includes 'admin' in the role enum
- This allows existing admin accounts to work properly
- Only prevents creation through the API, not database operations

```typescript
@Prop({ required: true, enum: ['family', 'doctor', 'volunteer', 'admin'] })
role: 'family' | 'doctor' | 'volunteer' | 'admin';
```

## Creating Admin Accounts

### Only Method: Manual Database Insertion

**Using MongoDB Shell:**
```javascript
db.users.insertOne({
  fullName: "Admin User",
  email: "admin@cognicare.com",
  passwordHash: "$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewfLkIwF5qcO7G6", // password: "admin123"
  role: "admin",
  createdAt: new Date(),
  updatedAt: new Date()
});
```

**Using init-mongo.js:**
Uncomment the admin user creation section in `backend/init-mongo.js` (development only)

**Using MongoDB Compass or Atlas:**
Manually insert document with role set to "admin"

## What Happens When Someone Tries to Create an Admin via API?

### Scenario 1: DTO Validation Failure
If someone sends a request with `role: "admin"`:

```bash
POST /api/v1/auth/signup
{
  "role": "admin",
  ...
}
```

**Response:** `400 Bad Request`
```json
{
  "statusCode": 400,
  "message": ["role must be one of the following values: family, doctor, volunteer"],
  "error": "Bad Request"
}
```

### Scenario 2: Service-Level Rejection
Even if validation is bypassed somehow, the service layer catches it:

**Response:** `400 Bad Request`
```json
{
  "statusCode": 400,
  "message": "Admin accounts can only be created by system administrators",
  "error": "Bad Request"
}
```

## Testing the Security

### Test 1: Try to signup as admin
```bash
curl -X POST http://localhost:3000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "fullName": "Test Admin",
    "email": "test@admin.com",
    "password": "test123",
    "role": "admin",
    "verificationCode": "123456"
  }'
```

**Expected:** 400 Bad Request error

### Test 2: Verify allowed roles work
```bash
curl -X POST http://localhost:3000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "fullName": "Test User",
    "email": "test@user.com",
    "password": "test123",
    "role": "family",
    "verificationCode": "123456"
  }'
```

**Expected:** 201 Created (after proper email verification)

### Test 3: Verify existing admin can login
1. Create admin manually in database
2. Login through admin login screen
3. Should successfully authenticate and access dashboard

## Security Benefits

✅ **Prevents Privilege Escalation:** Normal users cannot elevate themselves to admin
✅ **Defense in Depth:** Multiple layers of validation (DTO + Service)
✅ **Clear Error Messages:** Users understand why admin creation is rejected
✅ **Audit Trail:** Only database administrators can create admins
✅ **No Backdoors:** Even with API knowledge, cannot bypass restrictions

## Production Checklist

Before deploying to production:

- [ ] Ensure init-mongo.js admin creation is commented out
- [ ] Verify no default admin credentials in production
- [ ] Create production admin accounts through secure database access only
- [ ] Document admin credentials securely (password manager)
- [ ] Set up monitoring for failed admin creation attempts
- [ ] Review database access controls (who can insert documents)

## Related Files

- `backend/src/auth/dto/signup.dto.ts` - Signup validation
- `backend/src/auth/auth.service.ts` - Signup business logic
- `backend/src/users/schemas/user.schema.ts` - User data model
- `backend/src/auth/admin.guard.ts` - Admin route protection
- `backend/init-mongo.js` - Database initialization
- `frontend/lib/website/ADMIN_FEATURE.md` - Full admin feature documentation

---

**Implementation Date:** January 31, 2026  
**Security Level:** High  
**Status:** ✅ Implemented and Tested
