# Script to create test accounts in MongoDB
# Replace <db_password> with your actual MongoDB password below
$MONGODB_PASSWORD = "YOUR_ACTUAL_PASSWORD_HERE"
$MONGODB_URI = "mongodb+srv://rtalhaonline_db_user:$MONGODB_PASSWORD@cluster0.e38k9ah.mongodb.net/tripnexus_db?retryWrites=true&w=majority&appName=Cluster0"

# Function to generate SHA-256 hash
function Get-SHA256Hash {
    param([string]$text)
    $hash = [System.BitConverter]::ToString((New-Object System.Security.Cryptography.SHA256Managed).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($text))).Replace('-','').ToLower()
    return $hash
}

# Test account passwords (as requested by user)
$passwords = @{
    "admin" = "admin123tripnexus"
    "traveler" = "traveler123tripnexus"
    "agency" = "agency123tripnexus"
    "advisor" = "advisor123tripnexus"
}

# Generate password hashes
$adminHash = Get-SHA256Hash $passwords["admin"]
$travelerHash = Get-SHA256Hash $passwords["traveler"]
$agencyHash = Get-SHA256Hash $passwords["agency"]
$advisorHash = Get-SHA256Hash $passwords["advisor"]

Write-Host "Password Hashes Generated:" -ForegroundColor Green
Write-Host "Admin: $adminHash"
Write-Host "Traveler: $travelerHash"
Write-Host "Agency: $agencyHash"
Write-Host "Advisor: $advisorHash"
Write-Host ""

# MongoDB shell commands to insert test accounts
$mongoCommands = @"
// Connect to MongoDB and run these commands in MongoDB Shell or Compass

use tripnexus_db

// 1. Admin Account (Tourist role with admin privileges)
db.users.insertOne({
  email: "admin@tripnexus.com",
  password: "$adminHash",
  fullName: "Admin User",
  phoneNumber: "+1234567890",
  role: "tourist",
  profilePictureUrl: "",
  createdAt: new Date(),
  updatedAt: new Date()
})

// 2. Traveler Account (Tourist role)
db.users.insertOne({
  email: "traveler@tripnexus.com",
  password: "$travelerHash",
  fullName: "John Traveler",
  phoneNumber: "+1234567891",
  role: "tourist",
  profilePictureUrl: "",
  createdAt: new Date(),
  updatedAt: new Date()
})

// 3. Travel Agency Account
db.users.insertOne({
  email: "agency@tripnexus.com",
  password: "$agencyHash",
  fullName: "TripNexus Agency",
  phoneNumber: "+1234567892",
  role: "advisor_agency",
  businessName: "TripNexus Travel Agency",
  licenseNumber: "AGC-2024-001",
  rating: 4.8,
  totalBookings: 150,
  specializations: ["luxury travel", "group tours", "corporate events"],
  profilePictureUrl: "",
  createdAt: new Date(),
  updatedAt: new Date()
})

// 4. Advisor Account (Individual Advisor)
db.users.insertOne({
  email: "advisor@tripnexus.com",
  password: "$advisorHash",
  fullName: "Sarah Advisor",
  phoneNumber: "+1234567893",
  role: "advisor_individual",
  businessName: "Sarah's Travel Experts",
  licenseNumber: "ADV-2024-002",
  rating: 4.9,
  totalBookings: 120,
  specializations: ["family travel", "honeymoon packages", "cultural tours"],
  profilePictureUrl: "",
  createdAt: new Date(),
  updatedAt: new Date()
})

// Verify accounts were created
db.users.find({}, { email: 1, fullName: 1, role: 1, _id: 0 })
"@

# Save MongoDB commands to file
$mongoCommands | Out-File -FilePath "mongodb_insert_commands.js" -Encoding UTF8

Write-Host "MongoDB Commands saved to: mongodb_insert_commands.js" -ForegroundColor Cyan
Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Test Accounts to Create:" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. ADMIN ACCOUNT (Tourist role)" -ForegroundColor Magenta
Write-Host "   Email: admin@tripnexus.com"
Write-Host "   Password: $($passwords['admin'])"
Write-Host ""
Write-Host "2. TRAVELER ACCOUNT (Tourist role)" -ForegroundColor Magenta
Write-Host "   Email: traveler@tripnexus.com"
Write-Host "   Password: $($passwords['traveler'])"
Write-Host ""
Write-Host "3. TRAVEL AGENCY ACCOUNT" -ForegroundColor Magenta
Write-Host "   Email: agency@tripnexus.com"
Write-Host "   Password: $($passwords['agency'])"
Write-Host "   Business: TripNexus Travel Agency"
Write-Host ""
Write-Host "4. ADVISOR ACCOUNT" -ForegroundColor Magenta
Write-Host "   Email: advisor@tripnexus.com"
Write-Host "   Password: $($passwords['advisor'])"
Write-Host "   Business: Sarah's Travel Experts"
Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Next Steps:" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "1. Replace 'YOUR_ACTUAL_PASSWORD_HERE' at the top of this script with your MongoDB password"
Write-Host "2. Install MongoDB Shell: https://www.mongodb.com/try/download/shell"
Write-Host "3. Connect to your cluster:"
Write-Host "   mongosh `"$MONGODB_URI`""
Write-Host "4. Copy and paste the commands from 'mongodb_insert_commands.js'"
Write-Host ""
Write-Host "OR use MongoDB Compass (GUI):" -ForegroundColor Cyan
Write-Host "1. Download: https://www.mongodb.com/try/download/compass"
Write-Host "2. Connect using: $MONGODB_URI"
Write-Host "3. Navigate to tripnexus_db > users collection"
Write-Host "4. Click 'ADD DATA' > 'Insert Document'"
Write-Host "5. Copy each user object from mongodb_insert_commands.js"
Write-Host ""
