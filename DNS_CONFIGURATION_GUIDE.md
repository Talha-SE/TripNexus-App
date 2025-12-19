# DNS Configuration Guide

## Overview
The app has been updated to use **system DNS** instead of hardcoded Google DNS (8.8.8.8), which was causing connection issues.

## What Changed

### 1. MongoDB Service
- The MongoDB connection now uses the system's DNS resolver
- Removed dependency on Google's DNS over HTTPS (dns.google.com)
- Respects device network settings

### 2. Android Network Configuration
- Added `network_security_config.xml` to use system DNS
- Updated `AndroidManifest.xml` to reference network security config
- Allows the app to use whatever DNS is configured on your device

## How to Use Cloudflare DNS (1.1.1.1)

### Option 1: Configure on Android Device (Recommended)
1. Open **Settings** on your Android device
2. Go to **Network & Internet** → **Wi-Fi**
3. Long-press your connected Wi-Fi network
4. Select **Modify network** or **Advanced**
5. Change **IP settings** from DHCP to **Static**
6. Set DNS servers:
   - **DNS 1**: `1.1.1.1` (Cloudflare)
   - **DNS 2**: `1.0.0.1` (Cloudflare backup)
7. Save and reconnect

### Option 2: Use Private DNS (Android 9+)
1. Open **Settings**
2. Go to **Network & Internet** → **Advanced** → **Private DNS**
3. Select **Private DNS provider hostname**
4. Enter: `1dot1dot1dot1.cloudflare-dns.com`
5. Save

### Option 3: Install Cloudflare App
1. Install **1.1.1.1: Faster Internet** from Play Store
2. Open the app and toggle the connection on
3. The app will route DNS through Cloudflare

## Automatic DNS (Default)
By default, the app now uses **automatic DNS** from your network provider or device settings. No configuration needed unless you want to change it.

## Benefits of This Approach

### System DNS (Current)
✅ Respects user's network preferences  
✅ Works with VPNs and custom DNS setups  
✅ No hardcoded dependencies  
✅ Follows platform best practices  
✅ Better privacy control  

### Cloudflare DNS (1.1.1.1)
✅ Faster DNS resolution  
✅ Enhanced privacy (doesn't log IP addresses)  
✅ Built-in security features  
✅ Better availability than some ISP DNS  
✅ Free and reliable  

## Troubleshooting

### If Connection Still Fails
1. **Check Internet Connection**: Ensure you have a stable internet connection
2. **Try Different Network**: Switch between Wi-Fi and mobile data
3. **Clear DNS Cache**: Restart your device to clear DNS cache
4. **Verify MongoDB Access**: Ensure MongoDB Atlas is accessible from your network
5. **Check Firewall**: Some networks block MongoDB ports (27017, 27018, etc.)

### Network Access Issues
If you're on a restrictive network (corporate, school, etc.):
- MongoDB Atlas uses port 27017
- Ensure this port is not blocked by your firewall
- Try using mobile data instead of Wi-Fi
- Check with your network administrator

## Technical Details

### DNS Resolution Flow
1. App makes MongoDB connection request
2. System DNS resolver queries configured DNS servers
3. DNS server returns MongoDB cluster IP addresses
4. App connects to MongoDB using resolved IPs

### Previous Issue
- The `mongo_dart` package was defaulting to Google DNS (8.8.8.8)
- Some networks block or throttle connections to dns.google.com
- This caused connection timeouts and failures

### Current Solution
- Removed DNS server specification from MongoDB connection
- App now uses Android's default DNS resolver
- Users can configure their preferred DNS at the system level
- More flexible and respects network policies

## Verification

After updating, verify the connection:
```bash
# Run the app
flutter run

# Check logs for successful MongoDB connection
# Look for: "✅ MongoDB Connected Successfully"
```

## Additional Notes

- DNS changes may require app restart
- System DNS changes take effect immediately
- VPN users: The app will use VPN's DNS settings
- No code changes needed to switch DNS providers
- All configuration is done at the device/system level
