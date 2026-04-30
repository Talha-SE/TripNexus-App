# TripNexus Tourism App - Complete Code-Verified Report

This report is based on direct code inspection of the Flutter application and Solidity contract in this repository.

## 1. Project completion status from code

### 1.1 Implemented and working modules

1. Role-based authentication and session restore
2. Tourist and advisor dashboards with separate flows
3. Trip creation, listing, and deletion
4. AI trip planning with Mistral API and plan saving
5. Landmark image scanning with Mistral vision and saved landmarks library
6. Live weather module using Open-Meteo APIs
7. News and local events feed using Google News RSS parsing
8. Package marketplace (browse, filter, details, booking, chat)
9. Advisor package CRUD and booking status lifecycle
10. Local notification system plus weather/news notification schedulers
11. Blockchain-backed review submission and review retrieval

### 1.2 Partially implemented or simulated modules

1. DID verification screen is simulated UI flow with mock DID string and delayed animations, not real SSI wallet integration
2. Two-factor security screen is UI simulation with local toggles and mocked QR and blockchain approval steps
3. Privacy and account security actions include coming-soon placeholders for change password, session management, and account deletion
4. Manual weather check in create-trip screen uses WeatherService with OpenWeatherMap key placeholder, so this specific function depends on external key setup
5. Blockchain traveler name resolution in advisor analytics expects walletAddress in users collection, but registration flow does not capture wallet addresses

Conclusion: the core app is functionally complete for tourism operations and blockchain reviews, with some advanced security features still in demo/simulated form.

## 2. Complete app working flow

### 2.1 Startup and routing

1. App initializes theme mode, notification services, weather/news notification services, and auth service during splash
2. Session is restored from local preferences
3. User is routed to tourist dashboard or advisor dashboard based on saved role
4. MongoDB connection is established asynchronously after startup

### 2.2 Authentication flow

1. Register supports three roles: tourist, advisor individual, advisor agency
2. Passwords are hashed with SHA-256 before storage
3. Login validates email plus hashed password against MongoDB
4. Session state is persisted in SharedPreferences and restored at next app launch

### 2.3 Tourist flow

1. Create trips with destination, date range, budget, activities, and eco flag
2. Save and view trips in list view with mixed manual and AI planning usage
3. Generate detailed AI itineraries and save plans in saved_trip_plans collection
4. Scan landmarks from camera/gallery, analyze via Mistral vision, persist image plus analysis in saved_landmarks
5. Browse advisor packages with search, sort, and filters
6. View package details, book package (cash flow), open package chat
7. View own bookings and submit blockchain review once booking is completed
8. View weather forecasts and city tabs using Open-Meteo with periodic refresh
9. View travel/news alerts from RSS feed and open external article links

### 2.4 Advisor flow

1. Create and manage packages (draft/live style status handling)
2. Receive and manage bookings: pending, accepted, rejected, completed
3. Use package message center for traveler conversations
4. View blockchain analytics per package (reviews, averages, counts)
5. See blockchain review indicator on completed bookings when traveler has submitted on-chain review

## 3. Blockchain implementation details

### 3.1 How blockchain is used

Blockchain is used for review integrity only. It stores package reviews in a smart contract so reviews are immutable once submitted.

On-chain fields stored in ReviewContract:
1. traveler address
2. packageId
3. rating
4. comment
5. timestamp

Off-chain field in MongoDB:
1. booking.reviewSubmitted boolean is set true after successful transaction, so user cannot submit duplicate review from booking UI

### 3.2 Network and contract

1. Network: Polygon Amoy testnet
2. Chain ID: 80002
3. RPC: Infura Amoy endpoint configured in code
4. Deployed contract address present in config and loaded by BlockchainService
5. Solidity contract includes addReview, getReviews, getReviewCount, and ReviewAdded event

### 3.3 End-to-end blockchain review flow

1. Tourist opens completed booking and taps Leave Blockchain Review
2. ReviewDialog collects rating and comment
3. BlockchainService signs and sends transaction via web3dart using configured private key
4. Tx hash is shown in UI, with explorer link support
5. Booking record is updated with reviewSubmitted true in MongoDB
6. Reviews are read from chain and shown in package details and advisor analytics

### 3.4 Important blockchain realities in current code

1. This is testnet deployment, not mainnet
2. App uses a hardcoded private key for signing, which is acceptable for classroom/demo but not production
3. If configured account has zero test MATIC, submit transaction fails

## 4. Functional requirements (code-verified)

FR-01: System shall support role-based user registration for tourist, advisor individual, and advisor agency.

FR-02: System shall hash user passwords before storing credentials.

FR-03: System shall support login and persistent session restoration.

FR-04: System shall route authenticated users to role-specific dashboards.

FR-05: Tourist shall create trip records with destination, schedule, and optional budget.

FR-06: Tourist shall add and manage trip activities.

FR-07: Tourist shall generate AI itinerary plans based on destination, duration, interests, and optional budget.

FR-08: Tourist shall save generated AI plans and reopen them later.

FR-09: Tourist shall scan landmark images from camera or gallery and receive AI analysis.

FR-10: Tourist shall save and delete recognized landmarks.

FR-11: Tourist shall browse live packages with search and filter support.

FR-12: Tourist shall view package details including itinerary, includes/excludes, advisor info, and blockchain reviews.

FR-13: Tourist shall create package bookings and view booking status.

FR-14: Tourist shall chat with advisors per package.

FR-15: Advisor shall create, edit, publish, and delete travel packages.

FR-16: Advisor shall view and update booking status through pending, accepted, rejected, completed states.

FR-17: System shall allow blockchain review submission only from completed bookings.

FR-18: System shall record transaction-backed review status and prevent duplicate review submission from booking UI.

FR-19: Advisor shall view blockchain review analytics by package.

FR-20: System shall provide weather forecasts for selected cities and news/event feed.

FR-21: System shall issue local notifications for weather/news based on user settings.

FR-22: System shall provide settings pages for privacy/security preferences.

## 5. Non-functional requirements (observed from implementation)

NFR-01 Security: Password hashing is implemented, but secrets (DB URI, AI key, blockchain private key) are hardcoded and must be externalized for production.

NFR-02 Availability: App handles startup errors and can route user even when some services fail during init.

NFR-03 Performance: Startup initializes major services in parallel and uses UI patterns such as lazy lists and caching packages.

NFR-04 Data Integrity: MongoDB collections are separated by domain, and booking lifecycle plus reviewSubmitted flag enforce core process integrity.

NFR-05 Usability: App has role-specific UX, refresh patterns, status badges, and consistent navigation.

NFR-06 Maintainability: Code is modularized into screens, services, models, widgets, and config layers.

NFR-07 Portability: Flutter architecture supports multi-platform targets, with current primary operational focus on mobile UX.

NFR-08 Auditability: Blockchain tx hash is exposed to user and contract stores immutable review history.

NFR-09 Scalability concern: Some data queries are in-memory filtered/sorted and may need indexing/pagination hardening for large-scale production.

## 6. Tools and technologies used

### 6.1 Core platform

1. Flutter
2. Dart SDK ^3.10.0
3. Material design widgets and custom theming

### 6.2 Backend and persistence

1. MongoDB Atlas via mongo_dart
2. SharedPreferences for session and local settings
3. sqflite included for local data usage
4. flutter_secure_storage dependency present

### 6.3 AI and external APIs

1. Mistral API (trip planning and landmark analysis)
2. Open-Meteo geocoding and forecast APIs
3. Google News RSS with XML parsing
4. URL launcher for opening external content

### 6.4 Notifications

1. flutter_local_notifications
2. timezone package for scheduling context
3. In-app notification handling and persisted notification list

### 6.5 Blockchain stack

1. Solidity smart contract (ReviewContract)
2. web3dart for contract calls and signed transactions
3. Polygon Amoy testnet (chainId 80002)
4. Infura RPC endpoint
5. Tx hash and explorer-link-based verification UX

### 6.6 Developer tooling and dependencies

1. http and dio for network calls
2. provider state package present
3. google_fonts, cached_network_image, image_picker, intl, xml

## 7. Final assessment

From code verification, the project is complete for its core tourism lifecycle:
1. user onboarding
2. trip planning
3. package commerce flow
4. advisor management flow
5. immutable blockchain review flow on Polygon Amoy

Not yet production-complete areas are mainly advanced security and operational hardening:
1. remove hardcoded secrets
2. replace simulated DID/2FA flows with real backend/wallet integrations
3. complete coming-soon account security actions
4. add deployment and key management pipeline for blockchain contract operations

## 8. Test cases

### 8.1 Functional test cases

| TC ID | Requirement | Precondition | Steps | Expected result |
|---|---|---|---|---|
| TC-FR-01 | FR-01, FR-02 | App connected to MongoDB | 1. Open Register screen 2. Select Tourist 3. Enter valid form values 4. Submit | User account is created and login session starts; password is stored hashed, not plaintext |
| TC-FR-02 | FR-01 | App connected to MongoDB | 1. Register advisor individual 2. Fill advisor fields 3. Submit | Advisor user is created with advisor role and routed to advisor dashboard |
| TC-FR-03 | FR-01 | Existing user with email already in DB | 1. Try registering with duplicate email 2. Submit | Registration is rejected with duplicate-email message |
| TC-FR-04 | FR-03, FR-04 | Existing registered user | 1. Open Login 2. Enter valid credentials 3. Submit | Login succeeds and user is routed to role-correct dashboard |
| TC-FR-05 | FR-03 | Existing registered user | 1. Login once 2. Force close app 3. Reopen app | Session restores from SharedPreferences and skips welcome/login |
| TC-FR-06 | FR-05, FR-06 | Logged-in tourist | 1. Open Create Trip 2. Fill destination, dates, activities 3. Save | Trip is inserted in trips collection and appears in trip list |
| TC-FR-07 | FR-07, FR-08 | Logged-in tourist and valid Mistral API key | 1. Open AI Trip Planner 2. Enter destination, duration, interests 3. Generate 4. Save | Plan is generated and persisted in saved_trip_plans collection |
| TC-FR-08 | FR-09, FR-10 | Logged-in tourist, camera/gallery permission granted, valid Mistral API key | 1. Open Landmark Scanner 2. Capture or pick image 3. Run analysis 4. Save | Analysis text is returned and record is saved in saved_landmarks with image path |
| TC-FR-09 | FR-11, FR-12 | At least one live package exists | 1. Open Advisor Packages 2. Search and filter 3. Open package details | Filtered package list displays; details screen shows itinerary and advisor info |
| TC-FR-10 | FR-13 | Logged-in tourist and selected package | 1. Open package details 2. Tap Book 3. Confirm cash booking | Booking row is created in package_bookings with pending status |
| TC-FR-11 | FR-14 | Existing booking and both users valid | 1. Tourist opens package chat 2. Send message 3. Advisor opens messages | Message appears in advisor conversation and unread count updates |
| TC-FR-12 | FR-15 | Logged-in advisor | 1. Open Create Package 2. Fill mandatory fields 3. Save as draft/live | Package is stored in packages collection with correct status |
| TC-FR-13 | FR-16 | Logged-in advisor and pending booking exists | 1. Open advisor bookings tab 2. Accept booking 3. Mark completed | Booking status transitions pending -> accepted -> completed |
| TC-FR-14 | FR-17 | Logged-in tourist and completed booking exists | 1. Open My Bookings 2. Verify review button is visible only on completed booking | Review action is shown only for completed status bookings |
| TC-FR-15 | FR-17, FR-18 | Completed booking, valid blockchain config, test MATIC available | 1. Submit blockchain review from dialog 2. Wait for tx hash | Transaction succeeds, tx hash shown, booking.reviewSubmitted becomes true |
| TC-FR-16 | FR-18 | Same booking already reviewed | 1. Reopen My Bookings 2. Check reviewed booking row | Leave review button is disabled/replaced by Review Submitted state |
| TC-FR-17 | FR-19 | Advisor has at least one package and on-chain review exists | 1. Open advisor analytics tab 2. Refresh | Package-level review count, average rating, and list of on-chain reviews load |
| TC-FR-18 | FR-20 | Internet available | 1. Open Weather screen 2. Search city 3. Open News screen | Weather forecast and news feed load successfully |
| TC-FR-19 | FR-21 | Notification permissions granted and toggles enabled | 1. Keep app running 2. Trigger weather/news update cycle | Local notifications appear and are stored in app notification list |
| TC-FR-20 | FR-22 | User logged in | 1. Open privacy/security settings 2. Toggle available switches | Toggle states persist; coming-soon actions show placeholder snackbars |

### 8.2 Blockchain-specific edge test cases

| TC ID | Focus | Precondition | Steps | Expected result |
|---|---|---|---|---|
| TC-BC-01 | No gas handling | Valid blockchain config but account has 0 test MATIC | 1. Attempt review submission | Submission fails with insufficient-funds error guidance |
| TC-BC-02 | Invalid contract address | Contract address changed to invalid value | 1. Open package details 2. Fetch reviews | Reviews fail gracefully (empty/error handling), app does not crash |
| TC-BC-03 | Duplicate review prevention (UI) | Completed booking already reviewed | 1. Reopen booking list | UI prevents second submission via reviewSubmitted flag |
| TC-BC-04 | Analytics consistency | On-chain review exists | 1. Submit review 2. Open advisor analytics | Review appears in analytics with rating and timestamp parsing |

### 8.3 Non-functional and reliability test cases

| TC ID | Category | Test action | Expected result |
|---|---|---|---|
| TC-NFR-01 | Startup performance | Cold start app on mid-range device | Splash completes and app becomes interactive within acceptable UX time for demo build |
| TC-NFR-02 | Resilience | Disable internet during startup | App handles startup error path and routes to welcome without hard crash |
| TC-NFR-03 | Data integrity | Create booking then update status from advisor dashboard | Single booking record reflects status transitions correctly in MongoDB |
| TC-NFR-04 | Auditability | Submit blockchain review and copy tx hash | Hash is visible and can be opened in PolygonScan link flow |
| TC-NFR-05 | Usability | Switch between tourist tabs and return to previous module | Navigation remains consistent, no broken state in main flows |
| TC-NFR-06 | Notification reliability | Enable/disable notification toggles, then force update check | Notification behavior respects toggles correctly |
| TC-NFR-07 | Security baseline | Inspect registration/login DB values | Password stored as SHA-256 hash, not plaintext |
| TC-NFR-08 | Known limitation validation | Open DID and 2FA screens | Flows behave as UI simulation (no real wallet/SSI verification backend) |

### 8.4 Minimum acceptance test set for final demo

1. Register and login both tourist and advisor roles
2. Create and list one tourist trip
3. Generate and save one AI trip plan
4. Scan and save one landmark
5. Advisor creates one live package
6. Tourist books that package
7. Advisor accepts and completes booking
8. Tourist submits blockchain review and captures tx hash
9. Advisor sees blockchain review in analytics
10. Weather and news screens both return live data

