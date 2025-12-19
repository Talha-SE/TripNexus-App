// Connect to MongoDB and run these commands in MongoDB Shell or Compass

use tripnexus_db

// 1. Admin Account (Tourist role with admin privileges)
db.users.insertOne({
  email: "admin@tripnexus.com",
  password: "036242e1e6676e80783ced7d7d01eaadeee66cf59ed8e2aaa5c22a53156fa81f",
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
  password: "5dda3a3693e639513bdf7dba1cad768884c15fefb54da1f0cdb5f8fe36e39b6e",
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
  password: "e2cf75153390d423546b9988a8556b24acb78ca271386813b4aa4aa84a695f2c",
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
  password: "a7c43993c4a51f7d297559164c8e67187e7c44a0dfb68f68d0cf0ce3dd8b4e77",
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
