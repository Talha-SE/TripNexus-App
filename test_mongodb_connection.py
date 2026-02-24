import socket
import ssl
from datetime import datetime

try:
    from pymongo import MongoClient
except Exception:
    MongoClient = None

MONGODB_SRV = "mongodb+srv://rtalhaonline_db_user:VFQm6yonboNbUmNB@cluster0.weglya2.mongodb.net/?appName=Cluster0"
DB_NAME = "tripnexus_db"
HOSTS = [
    "cluster0.weglya2.mongodb.net",
    "cluster0-shard-00-00.weglya2.mongodb.net",
    "cluster0-shard-00-01.weglya2.mongodb.net",
    "cluster0-shard-00-02.weglya2.mongodb.net",
]


def print_header(title: str):
    print("\n" + "=" * 68)
    print(title)
    print("=" * 68)


def test_dns():
    print_header("TEST 1: DNS RESOLUTION")
    ok = True
    for host in HOSTS:
        try:
            ips = socket.getaddrinfo(host, None)
            ip_list = list({ip[4][0] for ip in ips})
            print(f"✅ {host} -> {', '.join(ip_list[:3])}")
        except Exception as e:
            ok = False
            print(f"❌ {host} -> {e}")
    return ok


def test_tls(host: str, port: int = 27017):
    print_header("TEST 2: TLS HANDSHAKE")
    context = ssl.create_default_context()
    try:
        with socket.create_connection((host, port), timeout=10) as sock:
            with context.wrap_socket(sock, server_hostname=host) as ssock:
                cert = ssock.getpeercert()
                print(f"✅ TLS OK -> {host}:{port}")
                print(f"   Subject: {cert.get('subject', '')}")
                print(f"   Issuer: {cert.get('issuer', '')}")
                return True
    except Exception as e:
        print(f"❌ TLS FAILED -> {host}:{port}")
        print(f"   Error: {e}")
        return False


def test_pymongo():
    print_header("TEST 3: PYMONGO CONNECTION")
    if MongoClient is None:
        print("❌ pymongo not installed")
        print("   Install: pip install pymongo[srv]")
        return False

    try:
        client = MongoClient(MONGODB_SRV, serverSelectionTimeoutMS=10000, tls=True)
        client.admin.command("ping")
        db = client[DB_NAME]
        collections = db.list_collection_names()
        print("✅ MongoDB ping OK")
        print(f"✅ Collections: {len(collections)}")
        for c in collections[:5]:
            print(f"   • {c}")
        client.close()
        return True
    except Exception as e:
        print("❌ MongoDB connection failed")
        print(f"   Error: {e}")
        return False


def main():
    print("MongoDB Python Connection Test")
    print(f"Time: {datetime.now().isoformat()}")

    dns_ok = test_dns()

    tls_ok = False
    if dns_ok:
        tls_ok = test_tls(HOSTS[0])

    mongo_ok = False
    if dns_ok:
        mongo_ok = test_pymongo()

    print_header("SUMMARY")
    print(f"DNS: {'OK' if dns_ok else 'FAILED'}")
    print(f"TLS: {'OK' if tls_ok else 'FAILED'}")
    print(f"MongoDB: {'OK' if mongo_ok else 'FAILED'}")

    if not dns_ok:
        print("\nNext step: Fix DNS (Windows). Try Google DNS: 8.8.8.8 / 8.8.4.4")
    elif not tls_ok:
        print("\nNext step: Check firewall/SSL interception (corporate proxy).")
    elif not mongo_ok:
        print("\nNext step: Verify Atlas IP whitelist, credentials, and cluster status.")


if __name__ == "__main__":
    main()
