// ignore_for_file: prefer_interpolation_to_compose_strings, use_build_context_synchronously, library_private_types_in_public_api
import 'dart:convert';
import 'dart:ui';

import 'package:betrader/services/FirebaseService.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:google_fonts/google_fonts.dart' hide Config;
import '../config/config.dart';
import '../locale/localized_texts.dart';
import 'package:country_flags/country_flags.dart';
import 'package:betrader/services/AuthService.dart';

import '../helpers/common.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cardHolderNameController = TextEditingController();
  final _cvvCodeController = TextEditingController();
  final _formKeys = List.generate(3, (_) => GlobalKey<FormBuilderState>());

  String _fullName = '';
  String _password = '';
  String _address = '';
  String _country = '';
  String _gender = '';
  String _email = '';
  DateTime _birthday = DateTime.now();
  String _username = '';
  String _profilePic = '';
  int _currentStep = 0;

  Future<void> _onStepContinue() async {
    if (_validateAndSaveCurrentStep()) {
      _updateFormData(context);
      if (_currentStep == 2) {
        String countryCode = Common().getCountryCode(_country);
        Common().postRequestWrapper('Auth', 'SendCode', {'email': _email, 'country': countryCode});
        popCodeDialog(context, _fullName, _password, _address, countryCode, _gender, _email, _birthday, _cardNumberController, _username, _profilePic);
      }
      if (_currentStep < 2) {
        setState(() {
          _currentStep++;
        });
      }
    }
  }

  void popCodeDialog(
      BuildContext aContext,
      String fullName,
      String password,
      String address,
      String countryCode,
      String gender,
      String email,
      DateTime birthday,
      TextEditingController cardNumberController,
      String username,
      String profilePic,
      ) {
    final strings = LocalizedStrings.of(aContext)!;
    final TextEditingController codeController = TextEditingController();
    final ValueNotifier<bool> isButtonEnabled = ValueNotifier(false);

    showDialog(
      context: aContext,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                strings.get('enterVerificationCodeMsg') ??
                    'Enter the verification code sent to your email',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  isButtonEnabled.value = value.trim().length >= 4;
                },
                style: GoogleFonts.montserrat(color: Colors.white),
                decoration: InputDecoration(
                  labelStyle: GoogleFonts.montserrat(color: Colors.white70),
                  floatingLabelStyle:
                  GoogleFonts.montserrat(color: Colors.blueAccent),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ValueListenableBuilder<bool>(
              valueListenable: isButtonEnabled,
              builder: (context, enabled, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        foregroundColor: Colors.white,
                        textStyle:
                        GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                      ),
                      onPressed: enabled
                          ? () async {
                        Navigator.of(context).pop();
                        Common().vibrate();

                        try {
                          final result = await AuthService().register(
                            FirebaseService().firebaseToken!,
                            fullName,
                            password,
                            address,
                            countryCode,
                            gender,
                            email,
                            codeController.text,
                            birthday,
                            cardNumberController.text,
                            username,
                            profilePic,
                          );

                          if (result['success'] == true) {
                            Common().logInPopDialog(
                              strings.get('registrationSuccessful') ??
                                  "Registration successful!",
                              aContext,
                            );
                          } else {
                            Common().showFloatingSnack(
                              aContext,
                              "Oops... error",
                              backgroundColor: Colors.red,
                            );
                          }
                        } catch (e) {
                          Common().showFloatingSnack(
                            aContext,
                            "Error: $e",
                            backgroundColor: Colors.red,
                          );
                        }
                      }
                          : null,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.send_rounded,
                                size: 26, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              strings.get('send') ?? "Send",
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!enabled)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: 1,
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }


  Future<void> _selectDate(BuildContext context) async {
    DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(today.year - 18, today.month, today.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(today.year - 18, today.month, today.day),
    );

    if (picked != null) {
      _formKeys[0].currentState?.fields['birthday']?.didChange(
        "${picked.day}-${picked.month}-${picked.year}",
      );
    }
  }

  void _onStepCancel() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      }
    });
  }

  void _updateFormData(context) {
    final basicInfoForm = _formKeys[0].currentState!;
    final addressInfoForm = _formKeys[1].currentState!;

    _fullName = basicInfoForm.fields['fullName']?.value ?? '';
    _address = addressInfoForm.fields['address']?.value ?? '';
    _country = addressInfoForm.fields['country']?.value ?? '';
    _gender = basicInfoForm.fields['gender']?.value ?? '';
    _username = basicInfoForm.fields['username']?.value ?? '';

    String? birthdayString = basicInfoForm.fields["birthday"]?.value;
    if (birthdayString != null && birthdayString.isNotEmpty) {
      List<String> parts = birthdayString.split('-');
      if (parts.length == 3) {
        String day = parts[0].length == 1 ? '0${parts[0]}' : parts[0];
        String month = parts[1].length == 1 ? '0${parts[1]}' : parts[1];
        String year = parts[2];
        String formattedBirthday = '$year-$month-$day';
        _birthday = DateTime.tryParse(formattedBirthday) ?? DateTime.now();
      }
    } else {
      _birthday = DateTime.now();
    }
  }

  List<Step> _buildSteps(context) {
    final strings = LocalizedStrings.of(context);
    return [
      Step(
        title: Text(strings?.get('personalInfo') ?? 'Personal info'),
        content: _buildBasicInfoStep(context),
        isActive: _currentStep == 0,
      ),
      Step(
        title: Text(strings?.get('address') ?? 'Address'),
        content: _buildAddressInfoStep(context),
        isActive: _currentStep == 1,
      ),
      Step(
        title: Text(strings?.get('credentials') ?? 'Credentials'),
        content: _buildCredentialsStep(context),
        isActive: _currentStep == 2,
      ),
    ];
  }

  bool _validateAndSaveCurrentStep() {
    final currentForm = _formKeys[_currentStep].currentState;
    return currentForm?.saveAndValidate() ?? false;
  }

  Widget _buildBasicInfoStep(context) {
    final strings = LocalizedStrings.of(context);
    return FormBuilder(
      key: _formKeys[0],
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 4.5),
            _buildTextField(
              context,
              strings?.get('fullName') ?? 'Full Name',
              'fullName',
              Icons.person,
              false,
            ),
            const SizedBox(height: 10.0),
            _buildTextField(
              context,
              strings?.get('username') ?? 'Username',
              'username',
              Icons.account_circle,
              false,
            ),
            const SizedBox(height: 10.0),
            _buildGenderDropdown(),
            const SizedBox(height: 10.0),
            _buildTextField(
              context,
              strings?.get('birthday') ?? 'Birthday',
              'birthday',
              Icons.calendar_today,
              true,
              onTap: () => _selectDate(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressInfoStep(context) {
    final strings = LocalizedStrings.of(context);
    return FormBuilder(
      key: _formKeys[1],
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 4),
            _buildTextField(
              context,
              strings?.get('address') ?? 'Address',
              'address',
              Icons.location_on,
              false,
            ),
            const SizedBox(height: 10.0),
            _buildTextField(
              context,
              strings?.get('zipCode') ?? 'ZIP Code',
              'zipCode',
              Icons.gps_fixed,
              false,
            ),
            const SizedBox(height: 10.0),
            _buildCountryDropdown(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryDropdown(context) {
    final strings = LocalizedStrings.of(context);
    return FormBuilderDropdown(
      name: 'country',
      decoration: InputDecoration(
        errorMaxLines: 2,
        errorStyle: const TextStyle(color: Colors.red),
        labelText: strings?.get('country') ?? 'Country',
        prefixIcon: const Icon(Icons.flag),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      ),
      validator: FormBuilderValidators.required(
        errorText:
        strings?.get('thisFieldIsRequired') ?? "This field is required",
      ),
      items: Common().getTopCountries().map((countryMap) {
        return DropdownMenuItem(
          alignment: AlignmentDirectional.center,
          value: countryMap['name'],
          child: Row(
            children: <Widget>[
              CountryFlag.fromCountryCode(
                countryMap['code']!,
                shape: const RoundedRectangle(5),
                height: 25,
                width: 40,
              ),
              const SizedBox(width: 10),
              Text(countryMap['name']!),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildControls(BuildContext context, ControlsDetails details) {
    final strings = LocalizedStrings.of(context);
    return Row(
      children: [
        if (_currentStep > 0)
          TextButton(
            onPressed: details.onStepCancel,
            child: Text(strings?.get('back') ?? 'Back'),
          ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () {
            if (_validateAndSaveCurrentStep()) {
              details.onStepContinue?.call();
            }
          },
          child: Text(
            _currentStep == _formKeys.length - 1
                ? strings?.get('signIn') ?? 'Sign In'
                : strings?.get('continueText') ?? 'Continue',
          ),
        ),
      ],
    );
  }

  Widget _buildCredentialsStep(context) {
    final strings = LocalizedStrings.of(context);
    return FormBuilder(
      key: _formKeys[2],
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 10.0),
            _buildEmailField(
              context,
              strings?.get('email') ?? 'Email',
              'email',
              Icons.email,
              false,
            ),
            const SizedBox(height: 10.0),
            _buildPasswordField(
              context,
              strings?.get('password') ?? 'Password',
              'password',
              Icons.lock,
              false,
              _formKeys[2],
              obscureText: true,
            ),
            const SizedBox(height: 10.0),
            _buildPasswordField(
              context,
              strings?.get('confirmPassword') ?? 'Confirm Password',
              'confirmPassword',
              Icons.lock,
              false,
              _formKeys[2],
              obscureText: true,
            ),
            _buildTermsAndConditionsCheckbox(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField(context, String label, String name, IconData icon,
      bool readonly,
      {void Function()? onTap, bool isIconEnabled = true}) {
    final strings = LocalizedStrings.of(context);
    return FormBuilderTextField(
      readOnly: readonly,
      name: name,
      decoration: InputDecoration(
        labelText: label,
        errorStyle: const TextStyle(color: Colors.red),
        errorMaxLines: 2,
        prefixIcon: isIconEnabled ? Icon(icon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      ),
      onTap: onTap,
      keyboardType: TextInputType.emailAddress,
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(
            errorText:
            strings?.get('thisFieldIsRequired') ?? 'This field is required'),
        FormBuilderValidators.email(
            errorText: strings?.get('enterValidEmail') ??
                'Enter a valid email address'),
      ]),
      onChanged: (value) {
        final trimmedValue = value?.trim();
        if (trimmedValue != null && trimmedValue.isNotEmpty) {
          final currentForm = _formKeys[_currentStep].currentState;
          if (currentForm?.fields[name]?.validate() ?? false) {
            _email = trimmedValue;
          }
        }
      },
    );
  }

  Widget _buildTermsAndConditionsCheckbox(context) {
    final strings = LocalizedStrings.of(context);
    return FormBuilderCheckbox(
      name: 'acceptTerms',
      initialValue: false,
      title: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: strings?.get('acceptTerms') ?? 'I accept the ',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            TextSpan(
              text:
              strings?.get('termsAndConditions') ?? 'terms and conditions',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.blue,
                fontWeight: FontWeight.w400,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Common()
                      .openInAppBrowser(context, Config.TERMS_N_CONDITIONS_PAGE);
                },
            ),
          ],
        ),
      ),
      validator: FormBuilderValidators.equal(
        true,
        errorText: strings?.get('acceptTermsToContinue') ??
            'Accept the terms and conditions to continue',
      ),
    );
  }

  Widget _buildTextField(context, String label, String name, IconData icon,
      bool readonly,
      {bool obscureText = false, void Function()? onTap}) {
    final strings = LocalizedStrings.of(context);
    return FormBuilderTextField(
      readOnly: readonly,
      name: name,
      decoration: InputDecoration(
        labelText: label,
        errorStyle: const TextStyle(color: Colors.red),
        prefixIcon: Icon(icon),
        errorMaxLines: 2,
        suffixIcon: name == 'fullName'
            ? GestureDetector(
          onTap: () async {
            final picked = await Common().pickImageFromGallery();
            if (picked.isNotEmpty) {
              setState(() {
                _profilePic = picked;
              });
            }
          },
          child: _profilePic.isEmpty
              ? const Icon(FontAwesomeIcons.camera)
              : Padding(
            padding: const EdgeInsets.all(6.0),
            child: CircleAvatar(
              backgroundImage: MemoryImage(
                base64Decode(_profilePic),
              ),
            ),
          ),
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      ),
      obscureText: obscureText,
      onTap: onTap,
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return strings?.get('thisFieldIsRequired') ?? 'This field is required';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(
      context, String label, String name, IconData icon, bool readonly,
      GlobalKey<FormBuilderState> formKey,
      {bool obscureText = true, void Function()? onTap}) {
    final strings = LocalizedStrings.of(context);
    return FormBuilderTextField(
      readOnly: readonly,
      name: name,
      decoration: InputDecoration(
        labelText: label,
        errorStyle: const TextStyle(color: Colors.red),
        errorMaxLines: 2,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      ),
      obscureText: obscureText,
      onTap: onTap,
      validator: (val) {
        if (val == null || val.isEmpty) {
          return strings?.get('thisFieldIsRequired') ?? 'This field is required';
        }
        if (name == 'confirmPassword') {
          _password =
              formKey.currentState?.fields['password']?.value.trim() ?? '';
          if (val != formKey.currentState?.fields['password']?.value.trim()) {
            return strings?.get('passwordsNotMatching') ??
                'Passwords not matching';
          }
        }
        final hasUppercase = val.contains(RegExp(r'[A-Z]'));
        final hasNumber = val.contains(RegExp(r'[0-9]'));
        final longEnough = val.length >= 12;

        if (!hasUppercase || !hasNumber || !longEnough) {
          return strings?.get('passwordRequirements') ??
              "Password must contain 12 characters, one uppercase and one number.";
        }

        return null;
      },
    );
  }

  Widget _buildGenderDropdown() {
    final strings = LocalizedStrings.of(context);
    return FormBuilderDropdown(
      name: 'gender',
      decoration: InputDecoration(
        errorStyle: const TextStyle(color: Colors.red),
        errorMaxLines: 2,
        labelText: strings?.get('gender') ?? 'Gender',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      ),
      validator: FormBuilderValidators.required(
        errorText:
        strings?.get('thisFieldIsRequired') ?? "This field is required",
      ),
      items: Common()
          .getAllGenders()
          .map(
            (gender) => DropdownMenuItem(
          value: gender,
          child: Text(gender),
        ),
      )
          .toList(),
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cardHolderNameController.dispose();
    _cvvCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(strings?.get('signIn') ?? 'Sign In'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/android12splash.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withValues(alpha: 0.2),
              ),
            ),
          ),
          Column(
            children: [
              Container(
                height: 1.0,
                color: Colors.black,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Stepper(
                    currentStep: _currentStep,
                    onStepContinue: _onStepContinue,
                    onStepCancel: _onStepCancel,
                    steps: _buildSteps(context),
                    controlsBuilder: _buildControls,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
