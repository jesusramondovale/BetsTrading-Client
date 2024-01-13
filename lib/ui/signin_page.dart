// ignore_for_file: prefer_interpolation_to_compose_strings, use_build_context_synchronously, library_private_types_in_public_api

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import '../locale/localized_texts.dart';
import 'package:country_flags/country_flags.dart';
import 'package:client_0_0_1/services/AuthService.dart';

import '../helpers/common.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final _formKeys = List.generate(4, (_) => GlobalKey<FormBuilderState>());
  final GlobalKey<FormState> _creditCardFormKey = GlobalKey<FormState>();

  String _idCard = '';
  String _fullName = '';
  String _password = '';
  String _address = '';
  String _country = '';
  String _gender = '';
  String _email = '';
  DateTime _birthday = DateTime.now();
  String _username = '';
  String _profilePic = '';


  final bool _autoValidateCreditCardForm = false;
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings?.signIn ?? 'Sign In'),
        elevation: 0,
      ),
        body: Container(
        child: Column(
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
          ),
        )
    );
  }

  void _updateFormData(context) {
    final strings = LocalizedStrings.of(context);
    final basicInfoForm = _formKeys[0].currentState!;
    final addressInfoForm = _formKeys[1].currentState!;
    final credentialsInfoForm = _formKeys[3].currentState!;

    _idCard = credentialsInfoForm.fields['idCard']?.value ?? '';
    _fullName = basicInfoForm.fields['fullName']?.value ?? '';
    _address = addressInfoForm.fields['address']?.value ?? '';
    _country = addressInfoForm.fields['country']?.value ?? '';
    _gender = basicInfoForm.fields['gender']?.value ?? '';
    _username = basicInfoForm.fields['username']?.value ?? '';

    String? birthdayString = strings?.birthday ?? basicInfoForm.fields['birthday']?.value;
    if (birthdayString != null && birthdayString.isNotEmpty) {
      List<String> parts = birthdayString.split('-');
      if (parts.length == 3) {
        String day = parts[0].length == 1 ? '0' + parts[0] : parts[0];
        String month = parts[1].length == 1 ? '0' + parts[1] : parts[1];
        String year = parts[2];
        String formattedBirthday = '$year-$month-$day';
        _birthday = DateTime.tryParse(formattedBirthday) ?? DateTime.now();
      }
    } else {
      _birthday = DateTime.now();
    }
  }
  Future<void> _onStepContinue() async {

    if (_validateAndSaveCurrentStep()) {
      if (_currentStep == 2) {
        _updateFormData(context);
      }

      if (_currentStep == 3) {
        _updateFormData(context);
        final result = await AuthService().register(
          _idCard,
          _fullName,
          _password,
          _address,
          _country,
          _gender,
          _email,
          _birthday,
          _cardNumberController.text,
          _username,
          _profilePic
        );

        if (result['success']) {
          Common().logInPopDialog("Registration successful!" , _username.trim(), context);
        } else {
          Common().popDialog("Oops...", "${result['message']}" , context);
        }
      }

      if (_currentStep < 3){
        setState(() {
          _currentStep++;
        });
      }

    }

  }
  void _onStepCancel() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      }
    });
  }
  List<Step> _buildSteps(context) {
    final strings = LocalizedStrings.of(context);
    return [
      Step(
        title: Text(strings?.personalInfo ?? 'Personal info'),
        content: _buildBasicInfoStep(context),
        isActive: _currentStep == 0,
      ),
      Step(
        title: Text(strings?.address ?? 'Address'),
        content: _buildAddressInfoStep(context),
        isActive: _currentStep == 1,
      ),
      Step(
        title: Text(strings?.creditCard ??'Credit card'),
        content: _buildCreditCardInfoStep(context),
        isActive: _currentStep == 2,
      ),
      Step(
        title: Text(strings?.credentials ?? 'Credentials'),
        content: _buildCredentialsStep(context),
        isActive: _currentStep == 3,
      ),
    ];
  }
  Widget _buildControls(BuildContext context, ControlsDetails details) {
    final strings = LocalizedStrings.of(context);
    return Row(
      children: [
        if (_currentStep > 0)
          TextButton(
            onPressed: details.onStepCancel,
            child: Text(strings?.back ?? 'Back'),
          ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () {
            if (_validateAndSaveCurrentStep()) {
              details.onStepContinue?.call();
            }
          },
          child: Text(_currentStep == _formKeys.length - 1 ? strings?.signIn ?? 'Sign In' :
                                                             strings?.continueText ?? 'Continue'),
        ),
      ],
    );
  }
  bool _validateAndSaveCurrentStep() {
    final currentForm = _formKeys[_currentStep].currentState;
    if (_currentStep == 2) {
      return _creditCardFormKey.currentState?.validate() ?? false;
    }
    if (currentForm?.saveAndValidate() ?? false) {
      return true;
    }
    return false;
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
      _formKeys[0].currentState?.fields['birthday']?.didChange(picked.day.toString()+"-"+picked.month.toString()+"-"+picked.year.toString());
    }
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
            _buildTextField(context, strings?.fullName ?? 'Full Name', 'fullName', Icons.person, false),
            const SizedBox(height: 10.0),
            _buildTextField(context , strings?.username ??'Username', 'username', Icons.account_circle, false),
            const SizedBox(height: 10.0),
            _buildGenderDropdown(),
            const SizedBox(height: 10.0),
            _buildTextField(
              context,
              strings?.birthday ?? 'Birthday',
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
            _buildTextField(context, strings?.address ?? 'Address', 'address', Icons.location_on, false),
            const SizedBox(height: 10.0),
            _buildTextField(context , strings?.zipCode ??'ZIP Code', 'zipCode', Icons.gps_fixed, false),
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
        labelText: strings?.country ?? 'Country',
        prefixIcon: const Icon(Icons.flag),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      ),
      validator: FormBuilderValidators.required(errorText: strings?.thisFieldIsRequired ?? "This field is required"),
      items: Common().getTopCountries().map((countryMap) {
        return DropdownMenuItem(
          alignment: AlignmentDirectional.center,
          value: countryMap['name'],
          child: Row(
            children: <Widget>[
              CountryFlag. fromCountryCode(
                countryMap['code']!,
                height: 25,
                width: 40,
                borderRadius: 5,
              ),
              const SizedBox(width: 10),
              Text(
                countryMap['name']!
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  Widget _buildCreditCardInfoStep(context) {
    final strings = LocalizedStrings.of(context);
    return CreditCardForm(
      cardNumber: _cardNumberController.text,
      expiryDate: _expiryDateController.text,
      cardHolderName: _cardHolderNameController.text,
      cvvCode: _cvvCodeController.text,
      onCreditCardModelChange: _onCreditCardModelChange,
      formKey: _creditCardFormKey,
      obscureCvv: false,
      obscureNumber: false,
      autovalidateMode: _autoValidateCreditCardForm ? AutovalidateMode.always : AutovalidateMode.disabled,
      cardNumberValidator: (value) => value != null && value.isNotEmpty && value.length == 19 ? null : strings?.pleaseEnterCardNumber ?? 'Please enter card number',
      expiryDateValidator: (value) => value != null && value.isNotEmpty && value.length == 5 ? null : strings?.enterDate ?? 'Enter a date',
      cvvValidator: (value) => value != null && value.isNotEmpty && (value.length == 3 || value.length == 4) ? null : strings?.pleaseEnterCVV ?? 'Please enter CVV',
      cardHolderValidator: (value) => value != null && value.isNotEmpty ? null : strings?.pleaseEnterCardHolderName ?? 'Please enter card holder name',
    );
  }
  void _onCreditCardModelChange(CreditCardModel creditCardModel) {
    _cardNumberController.text = creditCardModel.cardNumber;
    _expiryDateController.text = creditCardModel.expiryDate;
    _cardHolderNameController.text = creditCardModel.cardHolderName;
    _cvvCodeController.text = creditCardModel.cvvCode;
  }
  Widget _buildCredentialsStep(context) {
    final strings = LocalizedStrings.of(context);
    return FormBuilder(
      key: _formKeys[3],
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 4),
            _buildTextField(context , strings?.idCard ?? 'ID Card', 'idCard', Icons.credit_card, false),
            const SizedBox(height: 10.0),
            _buildEmailField(context, strings?.email ?? 'Email', 'email', Icons.email, false),
            const SizedBox(height: 10.0),
            _buildPasswordField(context, strings?.password ?? 'Password', 'password', Icons.lock, false, _formKeys[3], obscureText: true),
            const SizedBox(height: 10.0),
            _buildPasswordField(context, strings?.confirmPassword ?? 'Confirm Password', 'confirmPassword', Icons.lock, false, _formKeys[3], obscureText: true),
            _buildTermsAndConditionsCheckbox(context),
          ],
        ),
      ),
    );
  }
  Widget _buildEmailField(context, String label, String name, IconData icon, bool readonly, {void Function()? onTap, bool isIconEnabled = true}) {
    final strings = LocalizedStrings.of(context);
    return FormBuilderTextField(
      readOnly: readonly,
      name: name,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: isIconEnabled ? Icon(icon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      ),
      onTap: onTap,
      keyboardType: TextInputType.emailAddress,
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: strings?.thisFieldIsRequired ?? 'This field is required'),
        FormBuilderValidators.email(errorText: strings?.enterValidEmail ?? 'Enter a valid email address'),
      ]),
      onChanged: (value) {
        if (value != null && value.isNotEmpty) {
          final currentForm = _formKeys[_currentStep].currentState;
          if (currentForm?.fields[name]?.validate() ?? false) {
            _email = value;
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
              text: strings?.acceptTerms ?? 'I accept the ',
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16
              ),
            ),
            TextSpan(
              text: strings?.termsAndConditions ?? 'terms and conditions',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = ()
                {
                  //TO-DO
                  Common().unimplementedAction("seeTerms()", context);
                },
            ),
          ],
        ),
      ),
      validator: FormBuilderValidators.equal(
        true,
        errorText: strings?.acceptTermsToContinue?? 'Accept the terms and conditions to continue',
      ),
    );
  }
  Widget _buildTextField(context, String label, String name, IconData icon, bool readonly,{bool obscureText = false, void Function()? onTap}) {
    final strings = LocalizedStrings.of(context);
    return FormBuilderTextField(
      readOnly: readonly,
      name: name,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: name == 'fullName' ? IconButton(
          icon: const Icon(Icons.camera_alt),
          onPressed: () async {
            _profilePic = await Common().pickImageFromGallery();
          },
        ) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      ),
      obscureText: obscureText,
      onTap: onTap,
      validator: FormBuilderValidators.required(
        errorText: strings?.thisFieldIsRequired ?? 'This field is required',
      ),
    );
  }
  Widget _buildPasswordField(context , String label, String name, IconData icon, bool readonly, GlobalKey<FormBuilderState> formKey, {bool obscureText = true, void Function()? onTap}) {
    final strings = LocalizedStrings.of(context);
    return FormBuilderTextField(
      readOnly: readonly,
      name: name,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      ),
      obscureText: obscureText,
      onTap: onTap,
      validator: (val) {
        if (val == null || val.isEmpty) {
          return strings?.thisFieldIsRequired?? 'This field is required';
        }
        if (name == 'confirmPassword') {
          final passwordBytes = utf8.encode(formKey.currentState?.fields['password']?.value.trim());
          final hashedPassword = sha256.convert(passwordBytes);
           _password = hashedPassword.toString();
          if (val != formKey.currentState?.fields['password']?.value.trim()) {
            return strings?.passwordsNotMatching ?? 'Passwords not matching';
          }
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
        labelText: strings?.gender ??'Gender',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      ),
      validator: FormBuilderValidators.required(errorText: strings?.thisFieldIsRequired ?? "This field is required"),
      items: Common().getAllGenders().map((gender) => DropdownMenuItem(
        value: gender,
        child: Text(gender),
      )).toList(),
    );
  }

  /* Unused
  Widget _buildNumericField(String label, String name, IconData icon, bool readonly, {bool obscureText = false, void Function()? onTap, bool isIconEnabled = true}) {
    return FormBuilderTextField(
      readOnly: readonly,
      name: name,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: isIconEnabled ? Icon(icon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      ),
      obscureText: obscureText,
      onTap: onTap,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: 'This field is required'),
        FormBuilderValidators.numeric(errorText: 'Please enter a valid number'),
      ]),
    );
  } */

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cardHolderNameController.dispose();
    _cvvCodeController.dispose();
    super.dispose();
  }

  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cardHolderNameController = TextEditingController();
  final _cvvCodeController = TextEditingController();
}
