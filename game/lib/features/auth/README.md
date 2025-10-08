# Authentication Feature

This feature implements user authentication with a modern MVC architecture.

## Folder Structure

```
auth/
├── models/           # Data models
│   └── user_model.dart
├── views/            # UI screens
│   ├── auth_hub.dart
│   ├── login_screen.dart
│   └── register_screen.dart
├── controllers/      # Business logic
│   ├── login_controller.dart
│   └── register_controller.dart
├── services/         # API services
│   └── auth_service.dart
├── widgets/          # Reusable UI components
│   ├── auth_header.dart
│   ├── custom_button.dart
│   └── custom_text_field.dart
└── auth.dart         # Barrel file for exports
```

## Architecture

- **MVC Pattern**: Models handle data, Views handle UI, Controllers manage state and business logic
- **State Management**: GetX for reactive state management
- **Service Layer**: Separate API service for network calls
- **Reusable Widgets**: Custom components for consistent UI

## Features

### Auth Hub
- Welcome screen with features overview
- Options to sign in, register, or continue as guest
- Modern gradient design with feature highlights

### Login Screen
- Username and password fields with validation
- Password visibility toggle
- Error handling and user feedback
- Modern UI with custom components

### Register Screen
- Comprehensive registration form
- Real-time username availability check
- International phone number support
- Email validation
- Password strength requirements
- Visual feedback for form validation

## Usage

Import the barrel file:
```dart
import 'package:game/features/auth/auth.dart';
```

Or import specific files:
```dart
import 'package:game/features/auth/views/login_screen.dart';
import 'package:game/features/auth/controllers/login_controller.dart';
```

## State Management

Controllers use GetX observables for reactive state:
- `.obs` for observable values
- `Obx()` widgets for reactive UI updates
- Automatic cleanup with `onClose()`

## API Integration

The `AuthService` provides:
- `registerUser()` - Register new user
- `loginUser()` - Authenticate user
- `isUsernameAvailable()` - Check username availability

Responses are wrapped in `ApiResponse<T>` for consistent error handling.

## User Persistence

User data is stored locally using `UserPrefsService`:
- `saveUser()` - Save user data
- `loadUser()` - Load saved user
- `clearUser()` - Clear user data
- `isLoggedIn()` - Check login status
