import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @connexion.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get connexion;

  /// No description provided for @inscription.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get inscription;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get passwordConfirmation;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get invalidEmail;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDontMatch;

  /// No description provided for @isRequired.
  ///
  /// In en, this message translates to:
  /// **'is required'**
  String get isRequired;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone is required'**
  String get phoneRequired;

  /// No description provided for @phoneLengthError.
  ///
  /// In en, this message translates to:
  /// **'Phone must be 8 digits'**
  String get phoneLengthError;

  /// No description provided for @verifyEmailMessage.
  ///
  /// In en, this message translates to:
  /// **'Please check your email to activate your account'**
  String get verifyEmailMessage;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get genericError;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get phoneInvalid;

  /// No description provided for @login_failed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get login_failed;

  /// No description provided for @validation_error.
  ///
  /// In en, this message translates to:
  /// **'Validation error'**
  String get validation_error;

  /// No description provided for @unverified_email.
  ///
  /// In en, this message translates to:
  /// **'Email not verified. Please check your email.'**
  String get unverified_email;

  /// No description provided for @profile_fetch_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch profile'**
  String get profile_fetch_error;

  /// No description provided for @token_missing.
  ///
  /// In en, this message translates to:
  /// **'Token missing in response'**
  String get token_missing;

  /// No description provided for @logout_failed.
  ///
  /// In en, this message translates to:
  /// **'Logout failed'**
  String get logout_failed;

  /// No description provided for @verification_email_resent.
  ///
  /// In en, this message translates to:
  /// **'Verification email resent'**
  String get verification_email_resent;

  /// No description provided for @email_sender.
  ///
  /// In en, this message translates to:
  /// **'A reset link has been sent to your email'**
  String get email_sender;

  /// No description provided for @errorSendingLink.
  ///
  /// In en, this message translates to:
  /// **'Error sending link'**
  String get errorSendingLink;

  /// No description provided for @tokenNotFound.
  ///
  /// In en, this message translates to:
  /// **'Authentication token not found.'**
  String get tokenNotFound;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get errorOccurred;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get networkError;

  /// No description provided for @allRoles.
  ///
  /// In en, this message translates to:
  /// **'All roles'**
  String get allRoles;

  /// No description provided for @allStates.
  ///
  /// In en, this message translates to:
  /// **'All states'**
  String get allStates;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @employeeManagement.
  ///
  /// In en, this message translates to:
  /// **'Employee Management'**
  String get employeeManagement;

  /// No description provided for @totalEmployees.
  ///
  /// In en, this message translates to:
  /// **'Total Employees'**
  String get totalEmployees;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get totalUsers;

  /// No description provided for @adding_employees.
  ///
  /// In en, this message translates to:
  /// **'Adding Employees'**
  String get adding_employees;

  /// No description provided for @searchByEmail.
  ///
  /// In en, this message translates to:
  /// **'Search by email'**
  String get searchByEmail;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @noUserFound.
  ///
  /// In en, this message translates to:
  /// **'No user found.'**
  String get noUserFound;

  /// No description provided for @modifyRole.
  ///
  /// In en, this message translates to:
  /// **'Modify Role'**
  String get modifyRole;

  /// No description provided for @userName.
  ///
  /// In en, this message translates to:
  /// **'User Name:'**
  String get userName;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @confirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get confirmation;

  /// No description provided for @deleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this?'**
  String get deleteConfirmation;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @searchUser.
  ///
  /// In en, this message translates to:
  /// **'Search for a user...'**
  String get searchUser;

  /// No description provided for @roleUpdated.
  ///
  /// In en, this message translates to:
  /// **'User role updated successfully.'**
  String get roleUpdated;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get sessionExpired;

  /// No description provided for @addEmployee.
  ///
  /// In en, this message translates to:
  /// **'Add Employee'**
  String get addEmployee;

  /// No description provided for @add_primary_material.
  ///
  /// In en, this message translates to:
  /// **'Add Primary Material'**
  String get add_primary_material;

  /// No description provided for @primary_material_Name.
  ///
  /// In en, this message translates to:
  /// **'Primary Material Name'**
  String get primary_material_Name;

  /// No description provided for @primary_material_max_quantity.
  ///
  /// In en, this message translates to:
  /// **'Primary Material Max Quantity'**
  String get primary_material_max_quantity;

  /// No description provided for @primary_material_min_quantity.
  ///
  /// In en, this message translates to:
  /// **'Primary Material Min Quantity'**
  String get primary_material_min_quantity;

  /// No description provided for @piece.
  ///
  /// In en, this message translates to:
  /// **'Piece'**
  String get piece;

  /// No description provided for @kg.
  ///
  /// In en, this message translates to:
  /// **'Kg'**
  String get kg;

  /// No description provided for @litre.
  ///
  /// In en, this message translates to:
  /// **'Litre'**
  String get litre;

  /// No description provided for @caissier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get caissier;

  /// No description provided for @livreur.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get livreur;

  /// No description provided for @patissier.
  ///
  /// In en, this message translates to:
  /// **'Pastry chef'**
  String get patissier;

  /// No description provided for @boulanger.
  ///
  /// In en, this message translates to:
  /// **'Baker'**
  String get boulanger;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @manager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get manager;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @loadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingMessage;

  /// No description provided for @searchByName.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get searchByName;

  /// No description provided for @enterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter quantity'**
  String get enterQuantity;

  /// No description provided for @updateConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to update this element?'**
  String get updateConfirmation;

  /// No description provided for @noPrimaryMaterialsFound.
  ///
  /// In en, this message translates to:
  /// **'No Primary Material found.'**
  String get noPrimaryMaterialsFound;

  /// No description provided for @primary_material_Updated.
  ///
  /// In en, this message translates to:
  /// **'Primary Material updated successfully.'**
  String get primary_material_Updated;

  /// No description provided for @primary_materialDeleted.
  ///
  /// In en, this message translates to:
  /// **'Primary Material deleted successfully.'**
  String get primary_materialDeleted;

  /// No description provided for @updateprimaryMaterial.
  ///
  /// In en, this message translates to:
  /// **'Update Primary Material'**
  String get updateprimaryMaterial;

  /// No description provided for @invalidQuantities.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid quantities.'**
  String get invalidQuantities;

  /// No description provided for @primary_material_Added.
  ///
  /// In en, this message translates to:
  /// **'Primary Material added successfully.'**
  String get primary_material_Added;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @productManagement.
  ///
  /// In en, this message translates to:
  /// **'Product Management'**
  String get productManagement;

  /// No description provided for @stockManagement.
  ///
  /// In en, this message translates to:
  /// **'Stock Management'**
  String get stockManagement;

  /// No description provided for @noProductFound.
  ///
  /// In en, this message translates to:
  /// **'No product found.'**
  String get noProductFound;

  /// No description provided for @totalProducts.
  ///
  /// In en, this message translates to:
  /// **'Total Products'**
  String get totalProducts;

  /// No description provided for @totalPrimaryMaterial.
  ///
  /// In en, this message translates to:
  /// **'Total Primary Material'**
  String get totalPrimaryMaterial;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @productPrice.
  ///
  /// In en, this message translates to:
  /// **'Product Price'**
  String get productPrice;

  /// No description provided for @productDescription.
  ///
  /// In en, this message translates to:
  /// **'Product Description'**
  String get productDescription;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @salty.
  ///
  /// In en, this message translates to:
  /// **'Salty'**
  String get salty;

  /// No description provided for @sweet.
  ///
  /// In en, this message translates to:
  /// **'Sweet'**
  String get sweet;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @save_new_localization.
  ///
  /// In en, this message translates to:
  /// **'Save new localization'**
  String get save_new_localization;

  /// No description provided for @updateProduct.
  ///
  /// In en, this message translates to:
  /// **'Update Product'**
  String get updateProduct;

  /// No description provided for @productAdded.
  ///
  /// In en, this message translates to:
  /// **'Product added successfully.'**
  String get productAdded;

  /// No description provided for @productUpdated.
  ///
  /// In en, this message translates to:
  /// **'Product updated successfully.'**
  String get productUpdated;

  /// No description provided for @productDeleted.
  ///
  /// In en, this message translates to:
  /// **'Product deleted successfully.'**
  String get productDeleted;

  /// No description provided for @chooseAnImage.
  ///
  /// In en, this message translates to:
  /// **'Choose an image'**
  String get chooseAnImage;

  /// No description provided for @deleteImage.
  ///
  /// In en, this message translates to:
  /// **'Delete image'**
  String get deleteImage;

  /// No description provided for @productwholesale_price.
  ///
  /// In en, this message translates to:
  /// **'Wholesale Price'**
  String get productwholesale_price;

  /// No description provided for @wholesalePriceError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid wholesale price < Sales Price'**
  String get wholesalePriceError;

  /// No description provided for @invalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price (e.g., 12.99)'**
  String get invalidPrice;

  /// No description provided for @requiredImage.
  ///
  /// In en, this message translates to:
  /// **'An image is required'**
  String get requiredImage;

  /// No description provided for @bakeryManagement.
  ///
  /// In en, this message translates to:
  /// **'Bakery Management'**
  String get bakeryManagement;

  /// No description provided for @editBakery.
  ///
  /// In en, this message translates to:
  /// **'Edit Bakery Profile'**
  String get editBakery;

  /// No description provided for @bakery_name.
  ///
  /// In en, this message translates to:
  /// **'Bakery Name'**
  String get bakery_name;

  /// No description provided for @bakery_address.
  ///
  /// In en, this message translates to:
  /// **'Bakery Address'**
  String get bakery_address;

  /// No description provided for @bakery_phone.
  ///
  /// In en, this message translates to:
  /// **'Bakery Phone Number'**
  String get bakery_phone;

  /// No description provided for @bakery_email.
  ///
  /// In en, this message translates to:
  /// **'Bakery Email'**
  String get bakery_email;

  /// No description provided for @hoursofoperation.
  ///
  /// In en, this message translates to:
  /// **'Hours of Operation'**
  String get hoursofoperation;

  /// No description provided for @bakery_description.
  ///
  /// In en, this message translates to:
  /// **'Bakery Description'**
  String get bakery_description;

  /// No description provided for @bakery_image.
  ///
  /// In en, this message translates to:
  /// **'Bakery Image'**
  String get bakery_image;

  /// No description provided for @updateBakery.
  ///
  /// In en, this message translates to:
  /// **'Update Bakery'**
  String get updateBakery;

  /// No description provided for @bakeryAdded.
  ///
  /// In en, this message translates to:
  /// **'Bakery added successfully.'**
  String get bakeryAdded;

  /// No description provided for @bakeryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Bakery updated successfully.'**
  String get bakeryUpdated;

  /// No description provided for @bakeryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Bakery deleted successfully.'**
  String get bakeryDeleted;

  /// No description provided for @requiredOpeningHours.
  ///
  /// In en, this message translates to:
  /// **'Please select opening hours'**
  String get requiredOpeningHours;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'sunday'**
  String get sunday;

  /// No description provided for @select_day.
  ///
  /// In en, this message translates to:
  /// **'Select a day'**
  String get select_day;

  /// No description provided for @add_day.
  ///
  /// In en, this message translates to:
  /// **'Add a day'**
  String get add_day;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get fillAllFields;

  /// No description provided for @endAfterStart.
  ///
  /// In en, this message translates to:
  /// **'The end date must be after the start date'**
  String get endAfterStart;

  /// No description provided for @deadlineBeforeEnd.
  ///
  /// In en, this message translates to:
  /// **'The deadline must be before the end date'**
  String get deadlineBeforeEnd;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @deadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadline;

  /// No description provided for @evaluer.
  ///
  /// In en, this message translates to:
  /// **'Evaluate'**
  String get evaluer;

  /// No description provided for @total_bakeries.
  ///
  /// In en, this message translates to:
  /// **'Total bakeries'**
  String get total_bakeries;

  /// No description provided for @nobakeryFound.
  ///
  /// In en, this message translates to:
  /// **'No bakery found.'**
  String get nobakeryFound;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
