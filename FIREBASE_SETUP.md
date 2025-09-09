# Firebase Setup for Giro Libero

This document explains how to set up and use Firebase integration in the Giro Libero fitness app.

## Firebase Configuration Files

### 1. firebase.json
Defines the Firebase project configuration and deployment rules.

### 2. firestore.rules
Contains security rules for the Firestore database:
- Users can read/write their own profile data
- Fitness locations are publicly readable, but only admins can create/update them
- Reviews are publicly readable, but users can only create/edit their own
- Workouts are private to each user
- Location suggestions can be created by anyone, but only admins can approve/reject them

### 3. firestore.indexes.json
Defines composite indexes required for complex queries:
- Fitness locations by validation status and rating
- Fitness locations by type and rating
- Reviews by location and creation date
- Workouts by user and date
- Location suggestions by status and creation date

## Data Schema

The app uses the following Firestore collections:

### users/{userId}
- User profile data
- Admin status
- Preferences and favorite locations

### fitness_locations/{locationId}
- Location details (name, description, coordinates, etc.)
- Validation status and admin approval
- Average rating and review count
- Equipment list and status

### reviews/{reviewId}
- User reviews for fitness locations
- Ratings and comments
- Equipment-specific reviews

### workouts/{workoutId}
- User workout data
- Exercise details and statistics
- Location associations

### location_suggestions/{suggestionId}
- User-submitted location suggestions
- Admin review status
- Approval/rejection workflow

## Getting Started

1. **Authentication**: Users must sign up/sign in to use the app
2. **Data Migration**: Admins can use the "Migra Dati" button in the admin panel to populate Firebase with sample data
3. **Admin Access**: Users with `isAdmin: true` in their user document have access to admin features

## Firebase Services Used

- **Firebase Auth**: User authentication and management
- **Cloud Firestore**: NoSQL database for app data
- **Security Rules**: Database access control
- **Composite Indexes**: Optimized querying for complex filters

## Development Notes

- All dates are stored as Firestore Timestamps
- Images are stored as URL strings (external hosting)
- Real-time updates are implemented using Firestore streams
- Error handling includes user-friendly Italian messages
- The app follows the repository pattern for data access