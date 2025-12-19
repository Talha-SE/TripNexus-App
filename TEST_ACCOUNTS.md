# Test Accounts Reference

## Quick Login Credentials

After you insert the accounts into MongoDB, use these credentials to login:

### 1. Admin Account (Tourist Role)
- **Email:** `admin@tripnexus.com`
- **Password:** `Admin@123`
- **Role:** Tourist (with admin name for easy identification)

### 2. Travel Agency Account
- **Email:** `agency@tripnexus.com`
- **Password:** `Agency@123`
- **Role:** Advisor (Agency)
- **Business:** TripNexus Travel Agency

### 3. Individual Advisor Account #1
- **Email:** `individual@tripnexus.com`
- **Password:** `Individual@123`
- **Role:** Advisor (Individual)
- **Business:** John's Travel Consulting

### 4. Individual Advisor Account #2
- **Email:** `advisor@tripnexus.com`
- **Password:** `Advisor@123`
- **Role:** Advisor (Individual)
- **Business:** Sarah's Travel Experts

---

## How to Insert Accounts into MongoDB

### Option 1: MongoDB Compass (Easiest - GUI)
1. Download MongoDB Compass: https://www.mongodb.com/try/download/compass
2. Click "New Connection"
3. Paste your connection string (replace `<db_password>` with your actual password):
   ```
   mongodb+srv://rtalhaonline_db_user:<db_password>@cluster0.e38k9ah.mongodb.net/tripnexus_db?retryWrites=true&w=majority&appName=Cluster0
   ```
4. Click "Connect"
5. Navigate to: `tripnexus_db` → `users` collection
6. Click "ADD DATA" → "Insert Document"
7. Copy and paste each user object from `mongodb_insert_commands.js` (one at a time)
8. Click "Insert"

### Option 2: MongoDB Shell (Command Line)
1. Install MongoDB Shell: https://www.mongodb.com/try/download/shell
2. Open PowerShell and connect:
   ```powershell
   mongosh "mongodb+srv://rtalhaonline_db_user:<db_password>@cluster0.e38k9ah.mongodb.net/tripnexus_db?retryWrites=true&w=majority&appName=Cluster0"
   ```
3. Copy and paste the commands from `mongodb_insert_commands.js`

### Option 3: MongoDB Atlas Web UI
1. Go to https://cloud.mongodb.com/
2. Login to your Atlas account
3. Click on "Browse Collections"
4. Select `tripnexus_db` → `users`
5. Click "INSERT DOCUMENT"
6. Switch to "JSON view" ({}  icon)
7. Paste each user object from `mongodb_insert_commands.js`

---

## Important Configuration Steps

### Step 1: Update MongoDB Password in App
Edit `lib/config/app_config.dart` and replace `<db_password>` with your actual MongoDB password.

Current connection string in the app:
```dart
static const String mongoDbConnectionString = 'mongodb+srv://rtalhaonline_db_user:<db_password>@cluster0.e38k9ah.mongodb.net/tripnexus_db?retryWrites=true&w=majority&appName=Cluster0';
```

### Step 2: Insert Test Accounts (see above)

### Step 3: Hot Reload the App
If the app is already running, press `r` in the terminal to hot reload and see the UI changes.

Or restart the app:
```powershell
flutter run -d "adb-101182536D109344-o9cnec._adb-tls-connect._tcp"
```

---

## UI Changes Made

✅ **Welcome Screen Improvements:**
- Reduced top section (logo/title) from flex: 3 to flex: 2
- Increased bottom section (buttons) from flex: 2 to flex: 3
- Reduced icon size from 120 to 100
- Reduced title font size from 48 to 42
- Reduced spacing between elements
- Both Login and Sign Up buttons now visible without scrolling

✅ **Responsive Design:**
- SingleChildScrollView ensures content remains accessible on smaller screens
- Proper flex ratios maintain visual balance across different screen sizes

---

## Next Steps

1. ✅ MongoDB connection string updated in app
2. ✅ UI layout fixed (Login & Sign Up visible without scrolling)
3. ⏳ **You need to:** Replace `<db_password>` with your actual MongoDB password in `lib/config/app_config.dart`
4. ⏳ **You need to:** Insert test accounts into MongoDB using one of the methods above
5. ⏳ **You need to:** Hot reload or restart the app to see the changes
6. ⏳ **You need to:** Test login with the credentials above

---

## Files Generated

- `create_test_accounts.ps1` - PowerShell script that generates password hashes
- `mongodb_insert_commands.js` - Ready-to-use MongoDB insert commands
- `TEST_ACCOUNTS.md` - This file (quick reference)

---

## Troubleshooting

**Can't connect to MongoDB?**
- Make sure you replaced `<db_password>` with your actual password (no angle brackets)
- Check that your IP address is whitelisted in MongoDB Atlas (Network Access)
- Verify the connection string is correct

**App still shows scrolling requirement?**
- Press `r` in the terminal to hot reload
- Or stop and restart the app with `flutter run`
- Clear app data if needed

**Login fails even with correct credentials?**
- Verify accounts were inserted into MongoDB
- Check that password hashes match (they should be lowercase hex strings)
- Ensure MongoDB connection string in app has the correct password
