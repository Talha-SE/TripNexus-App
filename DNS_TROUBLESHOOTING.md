# DNS & MongoDB Connection Troubleshooting

## Issue Summary
The app is experiencing DNS resolution failures when trying to connect to MongoDB Atlas. This can manifest as either:
1. Google DNS errors (`dns.google.com` connection reset)
2. System DNS errors ("Failed host lookup" or "No address associated with hostname")

## Root Cause
- MongoDB's `mongo_dart` package uses DNS-over-HTTPS (DoH) with Google DNS for SRV record resolution
- Your network may be blocking Google DNS (`dns.google.com` on port 443)
- Your system DNS may also have issues resolving MongoDB Atlas hostnames

## Solutions

### Solution 1: Switch Networks (Recommended)
**Try switching between WiFi and mobile data:**
- If on WiFi, try switching to mobile data (4G/5G)
- If on mobile data, try connecting to a different WiFi network
- Some networks (corporate, school, public WiFi) block external DNS services

### Solution 2: Change Device DNS Settings
**On Android:**
1. Go to Settings → Network & Internet → Advanced → Private DNS
2. Select "Private DNS provider hostname"
3. Enter one of these:
   - `1.1.1.1` (Cloudflare)
   - `dns.google` (Google - if not blocked)
   - `dns.quad9.net` (Quad9)
4. Save and restart the app

### Solution 3: Check Network Restrictions
- **Disable VPN** if you're using one (VPNs can interfere with DNS)
- **Check firewall settings** on your router/network
- **Try a different time** - network issues can be temporary

### Solution 4: Use MongoDB Connection String Variants
If DNS issues persist, you can modify the MongoDB connection string in `lib/config/app_config.dart`:

**Current (uses SRV DNS):**
```dart
mongodb+srv://user:pass@cluster0.weglya2.mongodb.net/?appName=Cluster0
```

**Alternative (direct connection - requires specific node addresses):**
```dart
mongodb://user:pass@node1:27017,node2:27017,node3:27017/?ssl=true&authSource=admin
```

## Current App Behavior
The app has been configured with:
- **Extended timeouts**: 20 seconds (up from 15)
- **More retries**: 5 attempts (up from 3)
- **Better logging**: Shows specific DNS error types
- **Helpful messages**: Suggests network troubleshooting steps

##Verification
When the app successfully connects, you should see:
```
✅ MongoDB Connected Successfully
```

When DNS fails, you'll see one of:
```
⚠️ DNS Issue: Google DNS is blocked. Please check your network settings or use WiFi.
⚠️ DNS Issue: Cannot resolve MongoDB hostname. Please check your DNS settings or switch networks.
```

## Testing
1. **Quick test**: Try logging in with correct credentials
2. **If it fails 3+ times**: Switch networks (WiFi ↔ Mobile data)
3. **If still failing**: Check DNS settings as described above
4. **Last resort**: Contact your network administrator about DNS/firewall restrictions

## Technical Details
- Package: `mongo_dart` v0.10.3
- Connection Protocol: MongoDB+SRV (uses DNS SRV records)
- DNS Method: DNS-over-HTTPS (DoH) via Google DNS
- Atlas Cluster: `cluster0.weglya2.mongodb.net`
- Resolved Nodes: `cluster0-shard-00-{00,01,02}.weglya2.mongodb.net:27017`

## Previous Issues Fixed
- ✅ Weather screen overflow (reduced spacing)
- ✅ Extended connection retries and timeouts
- ✅ Better error messages for DNS issues
