# Hospital Queue - Admin Panel

React admin panel for managing the hospital queue system.

## Setup

1. Install dependencies: npm install
2. Copy .env.example to .env.local and fill in your Firebase config
3. Start dev server: npm run dev

## Project structure

- src/pages/ - Top-level route pages
- src/components/ - Reusable UI components
- src/components/layout/ - Layout shell (sidebar, etc.)
- src/context/ - React context (auth state)
- src/lib/ - Firebase initialization
- src/api/ - Firestore CRUD helpers
- src/hooks/ - Custom React hooks
- src/constants/ - Shared constants

## First-time admin setup

After signing in once with a new email, manually create a document in Firestore:
- Collection: users
- Document ID: your Firebase Auth UID
- Fields: email (string), role (string, set to "admin"), name (string)

The auth context blocks anyone without role admin or receptionist.
