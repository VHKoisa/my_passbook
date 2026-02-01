# My Passbook - Feature Roadmap

## ✅ Completed Features

### Authentication
- [x] Email/Password Sign Up
- [x] Email/Password Sign In
- [x] Google Sign In
- [x] Password Reset (Forgot Password)
- [x] Auth State Management with Riverpod
- [x] Protected Routes (Auth Guard)
- [x] Auto-redirect based on auth state
- [x] Sign Out functionality
- [x] Profile editing (display name)

### App Structure
- [x] Clean Architecture folder structure
- [x] Theme System (Light/Dark mode support)
- [x] Bottom Navigation with GoRouter
- [x] Shared Widgets (CustomButton, CustomTextField, LoadingOverlay)
- [x] Data Models (Transaction, Category, Budget, User)

### Firebase Setup
- [x] Firebase Core Configuration
- [x] Firebase Auth Integration
- [x] Firestore Service with CRUD operations
- [x] Multi-platform support (Web, Android, iOS, Windows)

### UI Pages (Fully Functional)
- [x] Login Page
- [x] Signup Page
- [x] Forgot Password Page
- [x] Dashboard Page - with real Firestore data
- [x] Transactions Page - full CRUD, search, filters
- [x] Add Transaction Page - with Firestore integration
- [x] Budgets Page - with budget creation
- [x] Reports Page - with real charts
- [x] Settings Page - with profile & logout

### Dashboard Features
- [x] Display real account balance from Firestore
- [x] Show recent transactions list
- [x] Quick action buttons functionality
- [x] Monthly income/expense summary cards
- [x] Budget status with progress bar
- [x] Pull-to-refresh functionality

### Transaction Management
- [x] Add new income transaction
- [x] Add new expense transaction
- [x] Edit existing transaction
- [x] Delete transaction with confirmation
- [x] Transaction list grouped by date
- [x] Filter transactions by type (income/expense)
- [x] Search transactions by description
- [x] Transaction details view (bottom sheet)
- [x] Swipe-to-delete functionality

### Budget Management
- [x] Create monthly budget
- [x] Set overall spending limit
- [x] Budget progress visualization
- [x] Budget status on dashboard
- [x] Real-time budget vs spending tracking

### Reports & Analytics
- [x] Monthly expense breakdown (Pie Chart)
- [x] Spending trends over time (Line Chart)
- [x] Category-wise spending analysis
- [x] Period filter (Week/Month/Year)
- [x] Summary cards (Total, Average, Count)

### Settings
- [x] User profile display with avatar
- [x] Edit profile (display name)
- [x] Theme selection dialog
- [x] Change password dialog
- [x] Logout with confirmation

### Category Management (Completed)
- [x] Create default categories on first login
- [x] Add custom categories
- [x] Edit category (name, icon, color)
- [x] Delete category (with reassignment option)
- [x] Category icons picker (72+ icons)
- [x] Category color picker (24 colors)
- [x] Separate categories for income/expense

### Offline Support
- [x] Cache transactions locally with Hive
- [x] Cache categories locally
- [x] Cache budgets locally
- [x] Connectivity monitoring
- [x] Offline banner notification
- [x] Auto-sync when online

### Notifications
- [x] Budget alerts (configurable threshold)
- [x] Daily expense reminder
- [x] Bill payment reminders (custom schedule)
- [x] Notification settings page
- [x] Enable/disable individual notification types

### Data Export
- [x] Export transactions to CSV
- [x] Export transactions to PDF
- [x] Date range selection for export
- [x] Transaction preview before export
- [x] Share exported files

### Split Transactions
- [x] Split expense between multiple people
- [x] Track who paid for split transactions
- [x] Equal or custom split amounts
- [x] Save friends/contacts for reuse
- [x] Add/edit/delete friends
- [x] View balances page (who owes whom)
- [x] Settle up functionality with friends
- [x] Net balance calculation (overall)
- [x] Split indicator in transaction list
- [x] Only user's share counts toward expenses

---

## 📋 To Be Implemented

### Transaction Management (Advanced)
- [ ] Filter transactions by date range
- [ ] Filter transactions by category
- [ ] Attach receipt/image to transaction
- [ ] Recurring transactions

### Category Management (Advanced)
- [ ] Category reordering

### Budget Management (Advanced)
- [ ] Set category-wise budgets
- [ ] Budget alerts (50%, 80%, 100% thresholds)
- [ ] Budget notifications
- [ ] Budget history/comparison
- [ ] Carry over unused budget (optional)

### Reports & Analytics (Advanced)
- [ ] Income vs Expense comparison (Bar Chart)
- [ ] Weekly/Monthly/Yearly view toggle
- [ ] Export reports as PDF
- [ ] Export data as CSV/Excel
- [ ] Custom date range reports

### Dashboard Widgets (Advanced)
- [ ] Top spending categories chart
- [ ] Quick add transaction FAB
- [ ] Savings goal progress

### Settings & Preferences
- [ ] Edit user profile
- [ ] Change profile picture
- [ ] Currency selection
- [ ] Date format preference
- [ ] First day of week setting
- [ ] Theme toggle (Light/Dark/System)
- [ ] Notification preferences
- [ ] Data backup to cloud
- [ ] Export all data
- [ ] Import data
- [ ] Delete account
- [ ] Privacy policy & Terms of Service

### Notifications
- [ ] Daily expense reminder
- [ ] Budget limit warnings
- [ ] Weekly spending summary
- [ ] Bill payment reminders
- [ ] Custom notification scheduling

### Security
- [ ] Biometric authentication (Fingerprint/Face ID)
- [ ] App lock with PIN
- [ ] Session timeout
- [ ] Secure data encryption

### Multi-Account Support
- [ ] Multiple wallets/accounts
- [ ] Bank account tracking
- [ ] Credit card tracking
- [ ] Cash wallet
- [ ] Transfer between accounts
- [ ] Account-wise reports

### Advanced Features
- [ ] Bill splitting
- [ ] Debt tracking (who owes you / you owe)
- [ ] Savings goals
- [ ] Financial insights with AI
- [ ] Smart categorization suggestions
- [ ] Receipt OCR scanning
- [ ] Bank SMS parsing (Android)
- [ ] Multi-currency support
- [ ] Currency conversion

### Social Features
- [ ] Share expenses with family
- [ ] Collaborative budgets
- [ ] Export & share reports

### Offline Support
- [ ] Offline transaction entry
- [ ] Local data caching with Hive
- [ ] Sync when online
- [ ] Conflict resolution

---

## 🎯 Priority Order (Recommended)

### Phase 1: Core Functionality
1. Dashboard with real data
2. Add/Edit/Delete transactions
3. Category management
4. Basic reports (pie chart)

### Phase 2: Budget & Analytics
5. Budget creation and tracking
6. Monthly reports
7. Spending trends
8. Export functionality

### Phase 3: Enhanced UX
9. Offline support
10. Notifications
11. Dark mode toggle
12. Profile management

### Phase 4: Advanced Features
13. Multi-account support
14. Biometric security
15. Receipt scanning
16. Recurring transactions

### Phase 5: Social & AI
17. Family sharing
18. AI insights
19. Smart categorization
20. Advanced analytics

---

## 📱 Platform-Specific Features

### Android
- [ ] Home screen widget
- [ ] SMS transaction parsing
- [ ] Google Drive backup

### iOS
- [ ] Home screen widget
- [ ] iCloud backup
- [ ] Siri shortcuts

### Web
- [ ] PWA support
- [ ] Keyboard shortcuts
- [ ] Desktop-optimized layout

---

## 🛠 Technical Debt & Improvements

- [ ] Unit tests for services
- [ ] Widget tests for UI
- [ ] Integration tests
- [ ] CI/CD pipeline setup
- [ ] Error tracking (Crashlytics)
- [ ] Analytics integration
- [ ] Performance optimization
- [ ] Accessibility improvements (a11y)
- [ ] Localization (multi-language support)

---

*Last Updated: February 1, 2026*
