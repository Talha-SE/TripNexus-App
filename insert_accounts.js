// Node.js script to insert test accounts into MongoDB Atlas
// Run with: node insert_accounts.js

const { MongoClient } = require('mongodb');

const uri = 'mongodb+srv://rtalhaonline_db_user:VFQm6yonboNbUmNB@cluster0.weglya2.mongodb.net/?appName=Cluster0';
const dbName = 'tripnexus_db';

const testAccounts = [
  {
    email: "admin@tripnexus.com",
    password: "036242e1e6676e80783ced7d7d01eaadeee66cf59ed8e2aaa5c22a53156fa81f",
    fullName: "Admin User",
    phoneNumber: "+1234567890",
    role: "tourist",
    profilePictureUrl: "",
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
    email: "traveler@tripnexus.com",
    password: "5dda3a3693e639513bdf7dba1cad768884c15fefb54da1f0cdb5f8fe36e39b6e",
    fullName: "John Traveler",
    phoneNumber: "+1234567891",
    role: "tourist",
    profilePictureUrl: "",
    createdAt: new Date(),
    updatedAt: new Date()
  },
  {
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
  },
  {
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
  }
];

async function insertAccounts() {
  const client = new MongoClient(uri);
  
  try {
    await client.connect();
    console.log('✅ Connected to MongoDB Atlas');
    
    const db = client.db(dbName);
    const usersCollection = db.collection('users');
    
    // Clear existing test accounts to avoid duplicates
    const testEmails = testAccounts.map(acc => acc.email);
    const deleteResult = await usersCollection.deleteMany({ email: { $in: testEmails } });
    console.log(`🗑️  Deleted ${deleteResult.deletedCount} existing test accounts`);
    
    // Insert new accounts
    const result = await usersCollection.insertMany(testAccounts);
    console.log(`✅ Inserted ${result.insertedCount} test accounts successfully!`);
    
    // Verify insertion
    console.log('\n📋 Inserted Accounts:');
    for (const account of testAccounts) {
      console.log(`   - ${account.email} (${account.role})`);
    }
    
    console.log('\n🔑 Login Credentials:');
    console.log('   admin@tripnexus.com → admin123tripnexus');
    console.log('   traveler@tripnexus.com → traveler123tripnexus');
    console.log('   agency@tripnexus.com → agency123tripnexus');
    console.log('   advisor@tripnexus.com → advisor123tripnexus');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  } finally {
    await client.close();
    console.log('\n✅ Connection closed');
  }
}

insertAccounts();
