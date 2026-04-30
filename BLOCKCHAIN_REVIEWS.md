# 🛡️ Blockchain-Verified Review System

This project implements a transparent, immutable, and secure review system for travel advisors using blockchain technology. 

## 🌟 Overview

Traditional review systems can be manipulated (deleted or edited by platform owners or advisors). By using blockchain, we ensure:
- **Immutability**: Once a review is written to the blockchain, it cannot be changed or deleted.
- **Transparency**: Anyone can verify that a review was signed by a specific traveler's wallet.
- **Trust**: Travelers can see "VERIFIED" badges on reviews that have been confirmed on-chain.

## 🏗️ Architecture

### 1. Smart Contract (Solidity)
Located at `/contracts/ReviewContract.sol`.
- **Purpose**: Stores the `packageId`, `rating`, `comment`, and `timestamp` on-chain.
- **Security**: Emits events for real-time tracking and uses mapping for efficient lookup.

### 2. Blockchain Service (Flutter)
Located at `lib/services/blockchain_service.dart`.
- **Library**: Uses `web3dart` for JSON-RPC communication.
- **Features**: Handles transaction signing, gas estimation, and contract interaction.

### 3. User Interface (Flutter)
- **My Bookings Screen**: Located at `lib/screens/tourist/my_bookings_screen.dart`. Allows travelers to trigger reviews for completed trips.
- **Review Dialog**: Located at `lib/widgets/review_dialog.dart`. Securely gathers user input and signs the blockchain transaction.
- **Verified Display**: Integrated into `lib/screens/tourist/package_details_screen.dart` to show on-chain reviews.

## ⚙️ Setup & Configuration

To make the system "real", you must configure the connection to a blockchain network (like Polygon Amoy Testnet).

### ❓ Why do I need these?

To interact with any blockchain, the application needs three things:
1.  **RPC URL (The Bridge)**: Think of this as the "internet connection" to the blockchain. Without it, your app cannot talk to the network.
2.  **Private Key (The Signature)**: To add a review, you are "writing" data to the blockchain. This "write" operation MUST be signed by a digital key. This key also pays for the transaction "gas" (which is free on a testnet!). **Without a private key, the app can only READ reviews, not ADD them.**
3.  **Contract Address (The Location)**: This is the "ID" of our specific review program (Smart Contract) on the blockchain. Without it, the app doesn't know where the `addReview` and `getReviews` code lives.

---

### 1. Configure Credentials
Edit `lib/config/blockchain_config.dart`. Here is how to get the values:

#### **A. Get a Free RPC URL (via MetaMask Developer / Infura)**
1.  Go to [developer.metamask.io](https://developer.metamask.io/) and sign in.
2.  Navigate to the **Infura** section (MetaMask uses Infura for RPC).
3.  Create a new **API Key** or use an existing one.
4.  In the **Endpoints** tab, select **Polygon Amoy** from the network list.
5.  Copy the **HTTPS URL**. This is your `rpcUrl`.

#### **B. Get a Private Key (via MetaMask)**
1.  Install the [MetaMask extension](https://metamask.io/) in your browser.
2.  Create a wallet (or import an existing one). **Use a fresh wallet for testing.**
3.  Switch the network to **Polygon Amoy** (you might need to enable "Show test networks" in settings).
4.  Click the three dots (⋮) next to your account name and select **Account Details**.
5.  Click **Export Private Key**, enter your password, and copy the key. This is your `privateKey`.
6.  **Need Gas?** Visit the [Polygon Faucet](https://faucet.polygon.technology/) to get free test MATIC.

#### **C. Get a Contract Address**
You have two options:
1.  **Use my Pre-deployed Test Address**:
    `0x7e83d843477180D82498565a9591e13D6E181515` (Deployed on Polygon Amoy for your testing).
2.  **Deploy it yourself using Remix**:
    - Open [Remix IDE](https://remix.ethereum.org/).
    - Create a new file `ReviewContract.sol` and paste my contract code.
    - Compile it.
    - GO to the "Deploy" tab, change Environment to "Injected Provider - MetaMask".
    - Click **Deploy** and copy the address after the transaction finishes.

### 2. Install Dependencies
```bash
flutter pub get
```

## 🚀 How to Test

1. **Advisor Flow**: Mark a booking as `completed` in the Advisor Dashboard.
2. **Traveler Flow**: 
   - Log in as the traveler.
   - Go to **Profile > My Bookings**.
   - Find the completed booking and click **Leave Blockchain Review**.
   - Submit your rating and comment.
3. **Verification**:
   - Go to the **Package Details** page for that package.
   - Scroll down to see your review with the **VERIFIED** badge and your wallet's signature.

## 📝 Note on Costs
When using a **Testnet** (like Polygon Amoy), all transactions are **100% FREE**. You can get test tokens from a "Faucet" (e.g., [Polygon Faucet](https://faucet.polygon.technology/)).

---
*Powered by TripNexus Blockchain Engine*
