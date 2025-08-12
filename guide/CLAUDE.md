# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter-based mother connection platform that connects mothers experiencing similar challenges. The app is built using MVVM architecture with Firebase as the backend, targeting web deployment via GitHub Pages.

## Development Commands

### Flutter Commands
- `flutter run -d web` - Run the app in web browser
- `flutter build web --base-href /momsbond.com/` - Build for GitHub Pages deployment
- `flutter test` - Run unit tests
- `flutter clean` - Clean build cache
- `flutter pub get` - Install dependencies

### Web Deployment
- Built web files are placed in `/docs` folder for GitHub Pages
- Base href is configured for GitHub Pages deployment at `/momsbond.com/`

## Architecture Overview

### MVVM Pattern
The app follows Model-View-ViewModel architecture:
- **Models**: Data structures in `lib/models/`
- **Views**: UI screens in `lib/views/`
- **ViewModels**: Business logic in `lib/viewmodels/`
- **Provider**: Used for state management across the app

### Key Components

#### Authentication System
- **SimpleAuthManager** (`lib/Database_logic/simple_auth_manager.dart`): Custom authentication using Firebase Firestore
- Uses username/password with local storage for persistence
- Handles user sessions and "remember me" functionality

#### Firebase Integration
- **Firestore**: Primary database for users, conversations, and matching
- **Configuration**: Firebase options in `lib/Database_logic/firebase_options.dart`
- **Deployment**: Configured in `firebase.json` with GitHub Pages integration

#### Core Features
1. **User Onboarding**: Mother stage selection and challenge identification
2. **Matching System**: Connects mothers based on shared challenges and stages
3. **Chat System**: Real-time conversations with 5-minute duration limit
4. **Connection Tracking**: Feedback system to track successful connections

### Project Structure
```
lib/
├── Database_logic/          # Firebase and authentication logic
├── Templates/              # Reusable UI components
├── assets/                 # Image assets
├── config/                 # App configuration and localization
├── models/                 # Data models
├── viewmodels/            # Business logic and state management
└── views/                 # UI screens
```

#### Key Files
- `lib/main.dart`: App initialization with Firebase and Provider setup
- `lib/config/app_config.dart`: Centralized text strings and configuration
- `lib/config/locale_helper.dart`: Internationalization helper (English/Spanish)
- `lib/Database_logic/simple_matching.dart`: User matching algorithm

### Navigation Flow
1. **Homepage** → **Login/Signup**
2. **Stage Selection** → **Challenges Selection**  
3. **Dashboard** → **Loading** → **Messages/Chat**

## Copy and Messaging Strategy

This app specifically targets mothers who have experienced the loss of their fathers. The copy is carefully crafted to create emotional resonance and safe space for vulnerable sharing.

### Stage Selection Copy
**Main prompt**: "what stage are you in?" with subtitle "this helps us match you with the best fit :)"

**Stage options focus on age at time of father's death**:
- "My father passed when i was young" - Targets women who lost fathers in childhood/adolescence
- "My Father passed when i was old" - Targets women who lost fathers as adults
- "trying moms?" / "teen mom?" / "adult mom?" - Additional motherhood stage options

**Why this approach**: The stages aren't about current motherhood phase, but about the formative experience of father loss. This creates more precise emotional matching between users who share similar grief timelines.

### Challenge Questions (Grief-Focused Set 1)
**Question 1**: "Do you ever wake up feeling disconnected—like part of you didn't come back after he passed?"
- **Purpose**: Identifies dissociation and identity fragmentation after loss
- **Target emotion**: Feeling incomplete or fundamentally changed

**Question 2**: "Do you find yourself crying about him sometimes—maybe when you least expect it?"
- **Purpose**: Validates unexpected grief waves and emotional triggers
- **Target emotion**: Unpredictable grief responses and vulnerability

**Question 3**: "Do you catch yourself holding your breath—waiting for something to trigger your grief again?"
- **Purpose**: Addresses hypervigilance and anxiety around grief triggers
- **Target emotion**: Living in fear of emotional overwhelm

**Why these questions**: They move beyond surface-level "sadness" to capture the complex, ongoing ways father loss impacts daily life. Each targets a different aspect of complicated grief that mothers may struggle to articulate.

### Chat Pre-populated Starter Text
**Text**: "Losing him broke something in me I've never talked about. I act strong, but underneath that I've been "

**Why this starter**:
- **"broke something in me"**: Acknowledges fundamental damage/change
- **"I've never talked about"**: Creates permission for untold stories
- **"I act strong, but underneath"**: Addresses the performance of strength while validating hidden struggles
- **Incomplete sentence**: Invites completion and personal disclosure
- **"I've been ___"**: Opens space for current emotional state

This starter specifically helps users bypass small talk and immediately access vulnerable, authentic sharing about their grief experience.

### Homepage Copy
**Main description**: "We built a space that connects you with moms who've been in your place."
**Card subtitle**: "We connect you with moms who feel exactly what you're feeling."

**Purpose**: Emphasizes understanding through shared experience rather than generic support.

## Development Notes

### Firebase Configuration
- Project uses two Firebase projects: emotion-e305b (main) and mymomsapp-59faa (legacy Android)
- Web deployment configured for emotion-e305b project

### Chat System
- 5-minute conversation limit (configurable in AppConfig)
- Real-time messaging with automatic conversation ending
- Post-chat feedback system for connection quality

### State Management
- Provider pattern used throughout the app
- ViewModels extend ChangeNotifier for reactive UI updates
- Shared preferences for local storage persistence

### Localization
- Supports English and Spanish
- Text strings centralized in `lib/config/app_config.dart`
- Uses `AppTexts` and `AppTextsEs` classes for translations

### Testing
- Unit tests in `test/` directory
- Tests focus on core functionality like matching algorithms and ViewModels