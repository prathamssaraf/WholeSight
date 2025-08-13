# WholeSight - AI-Enhanced Nutrition & Health Assistant

![WholeSight Logo](assets/icons/logo.png)

WholeSight is a comprehensive Flutter-based nutrition and health assistant that combines AI-powered food recognition, intelligent meal logging, and personalized nutrition tracking to help users achieve their health goals.

## 🚀 Features

### 🔐 Authentication & Onboarding
- **Multi-Provider Authentication**: Google Sign-In, Apple Sign-In, and email/password
- **Interactive Onboarding**: Welcome screens with smooth animations
- **Secure User Management**: Firebase Authentication integration
- **Profile Setup**: Comprehensive nutrition profile creation

### 🍽️ Smart Food Logging
- **AI-Powered Food Recognition**: Camera-based food identification using Google Gemini
- **NutriBot Integration**: Describe food in text and get instant nutritional analysis
- **One-Click Food Logging**: Analyze food descriptions and add directly to food log
- **Barcode Scanning**: Instant product lookup via Open Food Facts API
- **Voice Input**: Speech-to-text food logging for hands-free entry
- **Manual Entry**: Comprehensive food database search and custom food creation
- **Meal Management**: Organize foods into breakfast, lunch, dinner, and snacks

### 📊 Comprehensive Dashboard
- **Real-time Progress Tracking**: Daily calorie and macro progress visualization
- **Nutrition Analytics**: Detailed macronutrient distribution charts
- **Goal Integration**: Dynamic targets based on user's selected goals
- **Interactive Charts**: Beautiful data visualization using FL Chart
- **Quick Actions**: Easy access to frequently used features

### 🎯 Goal Management
- **Six Goal Types**: 
  - Lose Weight (20% calorie deficit)
  - Maintain Weight (balanced approach)
  - Gain Weight (15% calorie surplus)
  - Build Muscle (high protein focus)
  - Improve Health (balanced nutrition)
  - Improve Athletic Performance (sports-optimized)
- **Smart Macro Adjustment**: Automatic macro target calculation based on goals
- **Personalized Targets**: Customizable calorie and macro targets
- **Progress Tracking**: Visual goal progress monitoring

### 🧠 AI & Intelligence
- **NutriBot AI Assistant**: Intelligent nutrition coach powered by Google Gemini
- **Smart Food Analysis**: Text-to-nutrition analysis with "Add to Log" functionality
- **Personalized Coaching**: Context-aware advice based on user goals and preferences
- **Quick & Detailed Analysis**: Concise daily summaries with option for comprehensive breakdowns
- **Conversation Memory**: Contextual conversations with access to user's food logs
- **USDA Food Database**: Comprehensive food nutrition data
- **Recipe Analysis**: Ingredient breakdown and nutrition calculation
- **Predictive Analytics**: Health trend analysis and insights

### 📱 User Experience
- **Material Design**: Modern, intuitive interface
- **Dark/Light Themes**: Adaptive theming support
- **Responsive Design**: Optimized for all screen sizes
- **Smooth Animations**: Engaging user interactions
- **Offline Support**: Local data storage with Hive

### 🔧 Technical Features
- **Clean Architecture**: Domain-driven design with proper separation of concerns
- **BLoC Pattern**: Robust state management with flutter_bloc
- **Dependency Injection**: GetIt for service locator pattern
- **Firebase Integration**: Firestore, Analytics, Storage, and Crashlytics
- **Local Storage**: Hive for efficient local data management
- **Network Handling**: Dio for HTTP requests with proper error handling

## 📱 Screenshots

### Onboarding & Authentication
- Welcome screens with smooth animations
- Multiple authentication options
- Profile setup wizard

### Food Logging & NutriBot
- Camera-based food recognition
- Barcode scanning interface
- Voice input for hands-free logging
- Manual food entry with search
- NutriBot AI assistant for nutrition coaching
- Text-based food analysis with direct logging

### Dashboard
- Daily progress overview
- Macronutrient distribution charts
- Goal progress tracking
- Nutrition analytics

### Profile & Goals
- Comprehensive goal selection
- Personalized target settings
- Progress tracking and insights

## 🏗️ Architecture

```
lib/
├── core/                 # Core utilities and shared components
│   ├── constants/        # App constants and configurations
│   ├── errors/          # Error handling and exceptions
│   ├── network/         # Network configurations and API client
│   ├── services/        # Core services (analytics, storage, etc.)
│   ├── theme/           # App theming and styling
│   └── utils/           # Utility functions and helpers
├── data/                # Data layer
│   ├── datasources/     # Local and remote data sources
│   ├── models/          # Data models and DTOs
│   └── repositories/    # Repository implementations
├── domain/              # Domain layer
│   ├── entities/        # Business entities
│   ├── repositories/    # Repository interfaces
│   └── usecases/        # Business use cases
├── presentation/        # Presentation layer
│   ├── bloc/            # BLoC state management
│   ├── pages/           # Screen implementations
│   └── widgets/         # Reusable widgets
└── services/            # External services
    ├── ai/              # AI and ML services
    ├── auth/            # Authentication services
    ├── firebase/        # Firebase services
    └── nutrition/       # Nutrition-related services
```

## 🛠️ Dependencies

### Core Dependencies
- **Flutter**: Cross-platform mobile framework
- **flutter_bloc**: State management
- **get_it**: Dependency injection
- **dartz**: Functional programming utilities

### Firebase
- **firebase_core**: Core Firebase functionality
- **firebase_auth**: Authentication
- **cloud_firestore**: NoSQL database
- **firebase_storage**: File storage
- **firebase_analytics**: Analytics tracking

### AI & ML
- **google_generative_ai**: Gemini AI integration
- **camera**: Camera functionality
- **image**: Image processing
- **tflite_flutter**: TensorFlow Lite support

### UI & UX
- **flutter_svg**: SVG support
- **fl_chart**: Chart visualization
- **lottie**: Animation support
- **google_fonts**: Font integration
- **shimmer**: Loading animations

### Utilities
- **dio**: HTTP client
- **hive**: Local database
- **shared_preferences**: Simple local storage
- **image_picker**: Image selection
- **flutter_barcode_scanner**: Barcode scanning
- **speech_to_text**: Voice input
- **permission_handler**: Permission management

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / VS Code
- Firebase project setup

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/prathamssaraf/WholeSight.git
cd WholeSight
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure environment variables**
```bash
# Create .env file in project root
cp .env.example .env
# Add your API keys and configurations
```

4. **Firebase Setup**
```bash
# Add your google-services.json (Android) and GoogleService-Info.plist (iOS)
# Configure Firebase project with Authentication, Firestore, and Storage
```

5. **Run the application**
```bash
flutter run
```

## 🧪 Testing

Run tests with:
```bash
flutter test
```

## 📦 Build

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 🔒 Security

- Environment variables stored in `.env` file (not committed)
- Firebase security rules implemented
- User data encryption and secure storage
- API keys and sensitive data properly protected

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

For support, email prathamssaraf@gmail.com or create an issue in the repository.

## 🙏 Acknowledgments

- **Google Gemini AI** for advanced food recognition
- **Open Food Facts** for comprehensive food database
- **USDA Food Database** for nutrition data
- **Flutter team** for the amazing framework
- **Firebase** for backend services

---

**WholeSight** - Transforming nutrition tracking through AI and intelligent automation.
