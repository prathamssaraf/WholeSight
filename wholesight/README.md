# WholeSight - AI-Enhanced Nutrition & Health Assistant

<p align="center">
  <img src="assets/images/logo.png" alt="WholeSight Logo" width="200"/>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#installation">Installation</a> •
  <a href="#usage">Usage</a> •
  <a href="#ai-integration">AI Integration</a> •
  <a href="#roadmap">Roadmap</a> •
  <a href="#license">License</a>
</p>

WholeSight is a comprehensive Flutter-based mobile application designed to provide personalized nutrition tracking and recommendations. Leveraging artificial intelligence (via Google's Gemini), the app enhances the user experience while maintaining user agency, creating a balanced approach to nutrition management.

## Features

### Core Features

- **AI-Powered Food Recognition**: Take photos of meals for automatic identification and nutritional analysis
- **Multi-Modal Food Logging**: Support for camera, barcode scanning, voice input, and text search
- **Personalized Nutrition Insights**: AI-generated recommendations based on user goals and habits
- **Comprehensive Nutrition Tracking**: Detailed tracking of macronutrients, micronutrients, and daily calorie targets
- **Goal-Based Customization**: Support for different nutrition goals (weight loss, muscle gain, athletic performance)
- **User Profile Management**: Complete user authentication and profile management system
- **Meal Planning**: Assistance with meal planning based on nutritional targets and preferences

### Technical Highlights

- **Clean Architecture**: Clear separation between domain, data, and presentation layers
- **Flutter/Dart**: Cross-platform mobile development with modern UI
- **Firebase Backend**: Authentication, Firestore, and Storage integration
- **BLoC Pattern**: Reactive state management throughout the application
- **AI Integration**: Connected with Google's Gemini API for smart features
- **Barcode Scanning**: Product lookup using Open Food Facts database
- **Offline Support**: Local caching for use without internet connection

## Screenshots

<p align="center">
  <img src="screenshots/dashboard.png" width="200" />
  <img src="screenshots/food_logging.png" width="200" /> 
  <img src="screenshots/barcode_scanning.png" width="200" />
  <img src="screenshots/nutrition_insights.png" width="200" />
</p>

## Architecture

WholeSight follows Clean Architecture principles to ensure the codebase is maintainable, testable, and scalable:

### Layers

- **Domain Layer**: Core business logic and entities
  - Entities: Food, Meal, User, NutritionProfile
  - Repositories (interfaces): Define data access contracts
  - Use Cases: Business logic operations

- **Data Layer**: Data sources and repositories implementation
  - Models: Data transfer objects with mapping logic
  - Data Sources: Local and remote data access
  - Repository Implementations: Bridge between domain and data sources

- **Presentation Layer**: UI components and state management
  - Blocs: Manage state and business logic for UI
  - Pages: Application screens
  - Widgets: Reusable UI components

- **Services Layer**: External integrations and utilities
  - AI Services: Gemini API integration
  - Firebase Services: Authentication, database, storage
  - Nutrition Services: Food database, calculations

## Installation

### Prerequisites

- Flutter 3.7.0 or higher
- Dart 3.0.0 or higher
- Android Studio / VS Code with Flutter extensions
- Firebase project setup

### Getting Started

1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/wholesight.git
   cd wholesight
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Set up Firebase
   - Create a new Firebase project
   - Add Android and iOS apps to your Firebase project
   - Download and add the google-services.json and GoogleService-Info.plist files
   - Enable Authentication, Firestore, and Storage services

4. Set up Gemini API
   - Obtain an API key from Google AI Studio
   - Add your API key to the environment variables or secrets manager

5. Run the app
   ```bash
   flutter run
   ```

## Usage

### Food Logging

WholeSight offers multiple ways to log your food:

- **Search**: Find foods in our extensive database
- **Camera**: Take a photo of your meal for AI identification
- **Barcode Scanning**: Scan packaged foods for instant nutritional information
- **Voice**: Describe your meal using natural language
- **Custom**: Create your own food entries with detailed nutritional information

### Barcode Scanning

The barcode scanning feature connects to the Open Food Facts database to retrieve nutritional information for packaged foods:

1. Navigate to the Food Log page
2. Tap the + button to add a new food
3. Select the "Barcode" tab
4. Tap "Scan Barcode" and point your camera at a product barcode
5. Review the nutritional information
6. Tap "Add to Meal" to record your consumption

## AI Integration

WholeSight uses Google's Gemini for several smart features:

- **Food Recognition**: Identify foods and their approximate portions from photos
- **Nutrition Insights**: Personalized recommendations based on your eating patterns
- **Meal Suggestions**: Recommendations based on your nutritional goals and preferences
- **Natural Language Processing**: Understand food logging through voice input

## Roadmap

- [ ] Meal planning with grocery list generation
- [ ] Social features for sharing progress and recipes
- [ ] Integration with fitness tracking apps
- [ ] Restaurant menu analysis
- [ ] Expanded micronutrient tracking
- [ ] Meal timing optimization
- [ ] Premium subscription features

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributors

- Your Name (Lead Developer)
- Contributor 1 (UI/UX Designer)
- Contributor 2 (Backend Developer)

## Acknowledgments

- Open Food Facts for their extensive food database
- Flutter team for the amazing framework
- Firebase for the backend infrastructure
- Google's Gemini team for AI capabilities
