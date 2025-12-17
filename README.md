# Mental Capacity Assessment App

A Flutter application designed for healthcare professionals to conduct and manage mental capacity assessments in hospital settings.

## Features

### Core Functionality
- **JWT Authentication**: Secure token-based authentication with automatic token refresh
- **Separate Login & Register**: Beautiful, modern login and registration screens
- **Enhanced Splash Screen**: Professional animated splash screen with responsive design
- **Secure Login System**: Healthcare professional authentication with role-based access
- **Password Security**: Strong password validation with encryption (SHA-256)
- **Comprehensive Assessment Forms**: Structured questionnaires based on mental capacity assessment standards
- **Patient Data Management**: Secure storage and retrieval of patient assessment data
- **Assessment History**: Complete audit trail of all assessments
- **Search & Filter**: Quick access to patient records and assessments
- **Professional Reporting**: Detailed assessment reports with recommendations
- **Responsive Design**: Fully responsive UI that works on all screen sizes (mobile, tablet, desktop)
- **API Integration**: Ready for backend API integration with configurable endpoints

### Assessment Components
- Patient information collection
- Understanding assessment
- Information retention evaluation
- Decision-making capacity analysis
- Communication ability assessment
- Support and accommodation documentation
- Overall capacity determination
- Professional recommendations

### Commercial Features
- **HIPAA Compliant**: Secure data storage and handling
- **Multi-user Support**: Role-based access for different healthcare professionals
- **Audit Trail**: Complete record of all assessment activities
- **Export Capabilities**: Generate reports for medical records
- **Offline Functionality**: Work without internet connection
- **Data Backup**: Secure local and cloud backup options

## Technical Stack

- **Framework**: Flutter 3.10+
- **Language**: Dart
- **Database**: SQLite (local storage)
- **Security**: 
  - JWT Authentication
  - Flutter Secure Storage
  - Password hashing (SHA-256)
  - Token-based authentication
- **API**: HTTP client with configurable endpoints
- **UI**: Material Design 3 with responsive design
- **Platforms**: iOS, Android
- **Dependencies**:
  - `http`: API communication
  - `jwt_decoder`: JWT token validation
  - `flutter_dotenv`: Environment configuration
  - `flutter_secure_storage`: Secure token storage
  - `crypto`: Password hashing
  - `connectivity_plus`: Network connectivity checks

## Installation

### Prerequisites
- Flutter SDK 3.10 or higher
- Dart SDK 3.0 or higher
- Android Studio / Xcode for device deployment

### Setup
1. Clone the repository
2. Navigate to the project directory
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Create a `.env` file in the root directory (see Configuration section below)
5. Run the application:
   ```bash
   flutter run
   ```

### Configuration

Create a `.env` file in the root directory with the following variables:

```env
# API Configuration
API_BASE_URL=https://api.healthcare.org

# Database Configuration (for future use)
# DATABASE_URL=your_database_url_here
# DATABASE_NAME=mental_capacity_assessment
# DATABASE_USER=your_username
# DATABASE_PASSWORD=your_password

# JWT Configuration
# JWT_SECRET=your_jwt_secret_key_here
# JWT_EXPIRATION_DAYS=30

# App Configuration
# APP_ENV=production
# DEBUG_MODE=false
```

**Note**: The app will work in offline mode if the API is not configured. Authentication will fall back to local storage.

## Usage

### First Time Setup
1. Launch the app
2. You'll see the enhanced splash screen
3. If you don't have an account, tap "Sign Up" to register:
   - Full Name
   - Username/Staff ID
   - Email Address
   - Password (must meet security requirements)
   - Professional Role
   - Department
4. If you have an account, enter your credentials:
   - Username/Staff ID
   - Password
5. Optionally check "Remember me" to stay logged in

### Conducting an Assessment
1. Tap "New Assessment" from the home screen
2. Enter patient information
3. Complete the assessment questionnaire
4. Review and finalize the assessment
5. Save the completed assessment

### Managing Assessments
- View all assessments from the home screen
- Search by patient name, ID, or assessor
- Sort by date or patient name
- Tap any assessment to view detailed results

## Security & Compliance

### Data Protection
- **JWT Authentication**: Secure token-based authentication
- **Password Encryption**: SHA-256 hashing for passwords
- **Secure Storage**: Tokens stored in Flutter Secure Storage
- **Token Refresh**: Automatic token refresh on expiration
- **Offline Mode**: Works without internet connection
- All patient data is encrypted at rest
- Secure authentication system
- Local data storage (no cloud transmission by default)
- Automatic session timeout
- Audit logging for all activities
- **Password Requirements**:
  - Minimum 8 characters
  - At least one uppercase letter
  - At least one lowercase letter
  - At least one number
  - At least one special character

### Healthcare Compliance
- Designed to meet healthcare data protection standards
- Supports clinical documentation requirements
- Maintains assessment integrity and traceability
- Professional-grade security measures

## Customization for Hospitals

### Branding
- Customizable app colors and logos
- Hospital-specific terminology
- Department-specific workflows

### Integration Options
- EMR/EHR system integration
- Hospital authentication systems
- Reporting system integration
- Data export formats

### Deployment Options
- Enterprise app distribution
- Mobile Device Management (MDM) support
- Centralized configuration management
- Remote updates and maintenance

## Support & Maintenance

### Technical Support
- 24/7 technical support for critical issues
- Regular app updates and security patches
- Training materials and documentation
- User support and troubleshooting

### Professional Services
- Custom implementation consulting
- Staff training programs
- Integration services
- Ongoing maintenance contracts

## License

This application is designed for commercial use in healthcare settings. Contact for licensing and deployment options.

## Contact

For commercial licensing, customization, or deployment inquiries, please contact:
- Email: [Your Contact Email]
- Phone: [Your Contact Phone]
- Website: [Your Website]

---

**Note**: This application is intended for use by qualified healthcare professionals only. All assessments should be conducted in accordance with local clinical guidelines and legal requirements.