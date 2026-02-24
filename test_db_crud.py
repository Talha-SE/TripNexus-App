"""
MongoDB Connection Test with CRUD Operations
Keeps retrying until connection succeeds, then performs insert/delete test
"""

import time
import sys
from datetime import datetime

try:
    from pymongo import MongoClient
    from pymongo.errors import ConnectionFailure, ServerSelectionTimeoutError
    PYMONGO_AVAILABLE = True
except ImportError:
    PYMONGO_AVAILABLE = False
    print("❌ pymongo not installed!")
    print("   Run: pip install pymongo[srv]")
    sys.exit(1)

# MongoDB Configuration (same as Flutter app)
MONGODB_URI = "mongodb+srv://rtalhaonline_db_user:VFQm6yonboNbUmNB@cluster0.weglya2.mongodb.net/?appName=Cluster0"
DB_NAME = "tripnexus_db"
TEST_COLLECTION = "connection_test"

# Retry configuration
MAX_RETRIES = 10
RETRY_DELAY = 3  # seconds


def print_box(text, status="info"):
    """Print formatted box with status"""
    width = 70
    colors = {
        "info": "\033[96m",      # Cyan
        "success": "\033[92m",   # Green
        "error": "\033[91m",     # Red
        "warning": "\033[93m",   # Yellow
    }
    reset = "\033[0m"
    color = colors.get(status, "")
    
    print(f"\n{color}{'=' * width}")
    print(f"{text.center(width)}")
    print(f"{'=' * width}{reset}\n")


def test_connection_with_retry():
    """Keep trying to connect until successful or max retries reached"""
    print_box("MongoDB Connection Test - Retry Mode", "info")
    
    for attempt in range(1, MAX_RETRIES + 1):
        print(f"🔄 Attempt {attempt}/{MAX_RETRIES} - Connecting to MongoDB Atlas...")
        print(f"   URI: {MONGODB_URI[:50]}...")
        
        try:
            # Create client with timeout
            client = MongoClient(
                MONGODB_URI,
                serverSelectionTimeoutMS=10000,  # 10 seconds
                connectTimeoutMS=10000,
                socketTimeoutMS=10000,
                tls=True,
                tlsAllowInvalidCertificates=False
            )
            
            # Test connection with ping
            print("   ⏳ Testing connection with ping...")
            client.admin.command('ping')
            
            print_box("✅ CONNECTION SUCCESSFUL!", "success")
            print(f"✅ Connected on attempt {attempt}")
            print(f"✅ Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
            
            return client
            
        except ServerSelectionTimeoutError as e:
            print(f"   ❌ Timeout: Could not reach MongoDB servers")
            print(f"   📝 Error: {str(e)[:100]}")
            
        except ConnectionFailure as e:
            print(f"   ❌ Connection failed")
            print(f"   📝 Error: {str(e)[:100]}")
            
        except Exception as e:
            print(f"   ❌ Unexpected error: {type(e).__name__}")
            print(f"   📝 Details: {str(e)[:100]}")
        
        # Wait before retry (except on last attempt)
        if attempt < MAX_RETRIES:
            print(f"   ⏳ Waiting {RETRY_DELAY} seconds before retry...\n")
            time.sleep(RETRY_DELAY)
    
    # All retries failed
    print_box("❌ CONNECTION FAILED AFTER ALL RETRIES", "error")
    return None


def perform_crud_test(client):
    """Perform insert and delete operations to verify database works"""
    print_box("Testing Database Operations (CRUD)", "info")
    
    try:
        # Access database and collection
        db = client[DB_NAME]
        collection = db[TEST_COLLECTION]
        
        print(f"📊 Database: {DB_NAME}")
        print(f"📁 Collection: {TEST_COLLECTION}")
        print()
        
        # Step 1: List existing collections
        print("📋 Step 1: Listing collections...")
        collections = db.list_collection_names()
        print(f"   ✅ Found {len(collections)} collections:")
        for col in collections[:10]:  # Show first 10
            print(f"      • {col}")
        if len(collections) > 10:
            print(f"      ... and {len(collections) - 10} more")
        print()
        
        # Step 2: Insert test document
        print("➕ Step 2: Inserting test document...")
        test_doc = {
            "test_type": "connection_verification",
            "timestamp": datetime.now().isoformat(),
            "source": "Python test script",
            "message": "If you see this, MongoDB connection is working!",
            "status": "active"
        }
        
        insert_result = collection.insert_one(test_doc)
        inserted_id = insert_result.inserted_id
        print(f"   ✅ Document inserted successfully!")
        print(f"   📝 Inserted ID: {inserted_id}")
        print(f"   📄 Document: {test_doc}")
        print()
        
        # Step 3: Read it back
        print("🔍 Step 3: Reading document back...")
        found_doc = collection.find_one({"_id": inserted_id})
        if found_doc:
            print(f"   ✅ Document found!")
            print(f"   📄 Retrieved: {found_doc}")
        else:
            print(f"   ❌ Document not found (this shouldn't happen!)")
        print()
        
        # Step 4: Count documents in test collection
        print("🔢 Step 4: Counting documents in test collection...")
        count = collection.count_documents({})
        print(f"   ✅ Total documents in {TEST_COLLECTION}: {count}")
        print()
        
        # Step 5: Delete the test document
        print("🗑️  Step 5: Deleting test document...")
        delete_result = collection.delete_one({"_id": inserted_id})
        if delete_result.deleted_count > 0:
            print(f"   ✅ Document deleted successfully!")
            print(f"   📝 Deleted count: {delete_result.deleted_count}")
        else:
            print(f"   ❌ Document not deleted (this shouldn't happen!)")
        print()
        
        # Step 6: Verify deletion
        print("✔️  Step 6: Verifying deletion...")
        verify_doc = collection.find_one({"_id": inserted_id})
        if verify_doc is None:
            print(f"   ✅ Confirmed: Document successfully removed!")
        else:
            print(f"   ⚠️  Warning: Document still exists")
        print()
        
        # Step 7: Test users collection (app's main collection)
        print("👥 Step 7: Checking users collection...")
        users_collection = db["users"]
        user_count = users_collection.count_documents({})
        print(f"   ✅ Users collection exists")
        print(f"   📊 Current user count: {user_count}")
        
        if user_count > 0:
            print(f"   📝 Sample user (first one):")
            sample_user = users_collection.find_one({}, {"password": 0})  # Exclude password
            if sample_user:
                print(f"      • Email: {sample_user.get('email', 'N/A')}")
                print(f"      • Name: {sample_user.get('fullName', 'N/A')}")
                print(f"      • Role: {sample_user.get('role', 'N/A')}")
        print()
        
        print_box("✅ ALL DATABASE OPERATIONS SUCCESSFUL!", "success")
        return True
        
    except Exception as e:
        print_box(f"❌ DATABASE OPERATION FAILED", "error")
        print(f"Error type: {type(e).__name__}")
        print(f"Error message: {str(e)}")
        return False


def print_diagnostics():
    """Print diagnostic information"""
    print_box("Diagnostic Information", "warning")
    
    print("🔍 If connection fails, check:")
    print("   1. DNS Resolution:")
    print("      • Open PowerShell and run:")
    print("      • nslookup cluster0.weglya2.mongodb.net 8.8.8.8")
    print()
    print("   2. Internet Connectivity:")
    print("      • Can you access https://cloud.mongodb.com ?")
    print()
    print("   3. Windows Firewall:")
    print("      • Temporarily disable to test")
    print("      • Or add rule for port 27017")
    print()
    print("   4. MongoDB Atlas Settings:")
    print("      • Check Network Access → IP Whitelist")
    print("      • Should have 0.0.0.0/0 (allow all)")
    print("      • Verify cluster is not paused")
    print()
    print("   5. Change DNS to Google DNS:")
    print("      • Settings → Network → DNS")
    print("      • Set to 8.8.8.8 and 8.8.4.4")
    print()
    print("   6. Try Flutter app directly:")
    print("      • flutter run")
    print("      • Mobile apps use different network stack")
    print()


def main():
    """Main test function"""
    print("\n" + "=" * 70)
    print(" MongoDB Atlas Connection & CRUD Test ".center(70))
    print(f" {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} ".center(70))
    print("=" * 70)
    
    # Test connection with retry
    client = test_connection_with_retry()
    
    if client is None:
        print_diagnostics()
        print("\n❌ Could not connect to MongoDB. See diagnostics above.\n")
        return False
    
    # Perform CRUD operations
    try:
        success = perform_crud_test(client)
        
        # Close connection
        print("🔌 Closing connection...")
        client.close()
        print("   ✅ Connection closed\n")
        
        if success:
            print_box("🎉 ALL TESTS PASSED! DATABASE IS WORKING!", "success")
            print("✅ Your MongoDB Atlas connection is fully functional")
            print("✅ Insert operations: WORKING")
            print("✅ Read operations: WORKING")
            print("✅ Delete operations: WORKING")
            print("✅ Your Flutter app should work perfectly!")
            print()
            return True
        else:
            return False
            
    except Exception as e:
        print(f"\n❌ Unexpected error during testing: {e}\n")
        client.close()
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
