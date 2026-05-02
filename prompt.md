# DevIO Project Context

## Project Overview
DevIO is a professional Flutter application designed to connect to local LLM (Large Language Model) servers from macOS desktop or mobile devices. It provides a clean, modern interface for interacting with locally hosted large language models, with a focus on privacy and security.

## Technical Stack
- **Framework**: Flutter 3.x
- **Language**: Dart (SDK >=3.0.0)
- **State Management**: flutter_bloc (v9.0.0)
- **Navigation**: go_router (v14.8.0)
- **Code Generation**: freezed, json_serializable
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage
- **Analytics**: Firebase Analytics
- **Push Notifications**: Firebase Messaging
- **Crash Reporting**: Firebase Crashlytics

## Architecture
- Clean Architecture with separation of concerns
- BLoC/Cubit Pattern for state management
- Feature-first Structure
- Repository Pattern for data access

## Directory Structure
```
lib/
├── blocs/          # Bloc state management
├── constants/      # App constants and configurations
├── cubits/         # Cubit state management
├── features/       # Feature modules
│   ├── llm/        # Core LLM functionality
│   └── settings/   # App configuration
├── models/         # Data models
├── providers/      # Provider implementations
├── repositories/   # Data repositories
├── screens/        # UI screens
├── services/       # Service implementations
├── theme/          # Theming and styling
├── utils/          # Utility functions
├── widgets/        # Reusable UI components
├── main.dart       # Application entry point
└── router.dart     # Navigation configuration
```

## Key Features
1. Local LLM Integration
   - Ollama server connection
   - Multiple model support
   - Performance metrics tracking
   - Connection management

2. Chat Capabilities
   - Multi-session management
   - Code highlighting
   - Image analysis
   - PDF support
   - Real-time indicators

3. Authentication & Privacy
   - Firebase authentication
   - Cloud sync (optional)
   - Local processing
   - Demo mode

## Development Guidelines

### Code Style
- Use `const` constructors for immutable widgets
- Leverage Freezed for immutable state classes
- Use arrow syntax for simple functions
- Prefer expression bodies for one-liners
- Use trailing commas for better formatting

### State Management
- Use Cubit for simple state
- Use Bloc for complex event-driven state
- Extend states with Freezed
- Handle state transitions in `mapEventToState`
- Prefer `context.read()` for events

### Firebase Integration
- Use Firebase Auth for authentication
- Structure Firestore data with proper security rules
- Handle Firebase exceptions with detailed logging
- Include timestamps and metadata in documents

### Performance
- Use `const` widgets
- Optimize lists with `ListView.builder`
- Use `cached_network_image` for remote images
- Optimize Firestore queries with indexes

### UI/UX
- Follow Material Design 3 guidelines
- Implement responsive layouts
- Use theme text styles
- Handle empty states
- Show loading indicators

### Error Handling
- Display errors using `SelectableText.rich`
- Handle empty states in UI
- Manage errors in Cubit/Bloc states
- Log errors with context

## Security Rules
- Firestore rules enforce user authentication
- Data access restricted to authenticated users
- Owner-based access control
- Validation for message and metadata structure
- Metrics update restrictions

## Environment Setup
- Required environment variables in `.env`
- Firebase configuration
- Ollama server configuration
- Platform-specific settings


## Deployment
- Platform-specific build commands
- Environment configuration
- Asset management
- Version management

This context should be used to provide accurate and consistent assistance for the DevIO project. 