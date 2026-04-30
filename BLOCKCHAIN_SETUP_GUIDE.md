# Blockchain Review System - Setup Guide

## Issue: Review Submission Failing

### Root Cause
The blockchain review submission is failing with error: "type 'Null' is not a subtype of type 'String'"

This error occurs because **the account doesn't have test MATIC tokens** to pay for gas fees on the Polygon Amoy testnet.

## Solution: Get Test MATIC Tokens

### Step 1: Identify Your Wallet Address
The wallet address from your blockchain config is:
```
Private Key: 5b962b59fbfb145fee3c76ffcd431aa32f08bbdbf176594e9e9005a7d922c999
```

To get the public address from this private key:
1. Go to https://www.rapidtables.com/web/tools/sha256-hash/
2. Or use MetaMask to import the private key

### Step 2: Get Test MATIC from Faucet
1. **Visit Polygon Faucet**: https://faucet.polygon.technology/
2. **Select Network**: Choose "Polygon Amoy" (testnet)
3. **Enter Your Address**: Paste your wallet address
4. **Submit**: You'll receive 0.5 test MATIC in a few minutes

### Alternative Faucets (if first one doesn't work):
- https://www.alchemy.com/faucets/polygon-amoy
- https://amoy-faucet.polygon.technology/

### Step 3: Verify Balance
After getting test MATIC, the app will now show your balance in the console logs:
```
💰 Account Balance: 500000000000000000 wei (0.5 MATIC)
```

### Step 4: Submit Review Again
Once you have test MATIC, try submitting the review again. You should see:
```
✅ Transaction sent successfully!
🔗 Transaction Hash: 0x...
```

## Enhanced Error Messages

The app now provides better error messages:

- **"Insufficient funds"** → Get test MATIC from faucet
- **"Transaction nonce error"** → Try again (network issue)
- **"Gas estimation failed"** → Contract may not exist at the address

## Debugging Console Logs

When you submit a review, check the console for these logs:
```
🔗 Submitting review to blockchain...
📦 Package ID: 069ba71f970a244e8d000000
⭐ Rating: 5
💬 Comment: Test review
👤 Account Address: 0x...
💰 Account Balance: 500000000000000000 wei
📤 Sending transaction...
✅ Transaction sent successfully!
🔗 Transaction Hash: 0x...
```

## Configuration Details

### Blockchain Config
- **Network**: Polygon Amoy Testnet
- **RPC URL**: https://polygon-amoy.infura.io/v3/b5b2244437a54855abbcd31ca64155f0
- **Contract Address**: 0x7e83d843477180D82498565a9591e13D6E181515
- **Chain ID**: 80002

### Smart Contract
The ReviewContract.sol has been deployed to Polygon Amoy testnet. You can verify the contract at:
https://amoy.polygonscan.com/address/0x7e83d843477180D82498565a9591e13D6E181515

## Testing the Fix

1. **Get Test MATIC** (see Step 2 above)
2. **Hot Reload**: Press `r` in the Flutter terminal
3. **Navigate** to My Bookings → Completed booking
4. **Click** "Leave a Review"
5. **Enter** rating and comment
6. **Submit** to Blockchain
7. **Wait** for confirmation (usually 2-5 seconds)
8. **Success** message should appear: "Review successfully added to blockchain!"

## Troubleshooting

### Error: "Insufficient funds"
- **Solution**: Get test MATIC from faucet (see Step 2)

### Error: "Transaction hash is empty"
- **Solution**: Check RPC URL is working. Try running: `curl https://polygon-amoy.infura.io/v3/b5b2244437a54855abbcd31ca64155f0`

### Error: "Gas estimation failed"
- **Solution**: Contract may not be deployed correctly. Verify contract address on PolygonScan.

### Review Not Showing After Submission
- Blockchain transactions take 2-5 seconds to confirm
- The app waits 2 seconds before closing the dialog
- Reviews are stored permanently on the blockchain

## Security Note

⚠️ **IMPORTANT**: The private key in this config is for TESTNET ONLY. Never use this key for real funds or commit real private keys to git repositories.

In production, you would:
1. Use a wallet like MetaMask for transaction signing
2. Store private keys securely (never in code)
3. Connect to mainnet with proper security measures
