// ignore_for_file: prefer_interpolation_to_compose_strings, use_build_context_synchronously, library_private_types_in_public_api
import 'package:betrader/services/FirebaseService.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../locale/localized_texts.dart';
import 'package:country_flags/country_flags.dart';
import 'package:betrader/services/AuthService.dart';

import '../helpers/common.dart';
import 'camera_page.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final _formKeys = List.generate(3, (_) => GlobalKey<FormBuilderState>());


  String _idCard = '';
  bool _idCardSet = false;
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

  @override
  Widget build(BuildContext context) {
    final strings = LocalizedStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings?.signIn ?? 'Sign In'),
        elevation: 0,
      ),
        body: Column(
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
    );
  }

  void _updateFormData(context) {
    final basicInfoForm = _formKeys[0].currentState!;
    final addressInfoForm = _formKeys[1].currentState!;
    final credentialsInfoForm = _formKeys[2].currentState!;

    _idCard = credentialsInfoForm.fields['idCard']?.value ?? '';
    _fullName = basicInfoForm.fields['fullName']?.value ?? '';
    _address = addressInfoForm.fields['address']?.value ?? '';
    _country = addressInfoForm.fields['country']?.value ?? '';
    _gender = basicInfoForm.fields['gender']?.value ?? '';
    _username = basicInfoForm.fields['username']?.value ?? '';

    String? birthdayString = basicInfoForm.fields["birthday"]?.value;
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
      _updateFormData(context);
      if (_currentStep == 2) {

        String _countryCode = Common().getCountryCode(_country);
        final result = await AuthService().register(
          _idCard,
          FirebaseService().firebaseToken!,
          _fullName,
          _password,
          _address,
          _countryCode,
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Oops... ${result['message']}"),
              backgroundColor: Colors.red,
            ),
          );

        }
      }

      if (_currentStep < 2){
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
        title: Text(strings?.credentials ?? 'Credentials'),
        content: _buildCredentialsStep(context),
        isActive: _currentStep == 2,
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

    if (_currentStep == 2 && !_idCardSet) return false;
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
                shape: RoundedRectangle(5),
                height: 25,
                width: 40,
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

  Widget _buildCredentialsStep(context) {
    final strings = LocalizedStrings.of(context);
    return FormBuilder(
      key: _formKeys[2],
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 4),
            _buildTextField(context , strings?.idCard ?? 'ID Card', 'idCard', Icons.credit_card, true),
            const SizedBox(height: 10.0),
            _buildEmailField(context, strings?.email ?? 'Email', 'email', Icons.email, false),
            const SizedBox(height: 10.0),
            _buildPasswordField(context, strings?.password ?? 'Password', 'password', Icons.lock, false, _formKeys[2], obscureText: true),
            const SizedBox(height: 10.0),
            _buildPasswordField(context, strings?.confirmPassword ?? 'Confirm Password', 'confirmPassword', Icons.lock, false, _formKeys[2], obscureText: true),
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
              text: strings?.acceptTerms ?? 'I accept the ',
              style: TextStyle(
                  color:  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
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
                  /// TO-DO TERMS&CONDITIONS VIEW
                  Common().unimplementedAction(context , '(Terms & Conditions');
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
      initialValue: (name == 'idCard' ? strings!.takeIdPhoto ?? "Take a photo of your document" : null ),
      name: name,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon:
        name == 'fullName' ?
        IconButton(
          icon: const Icon(Icons.camera_alt),
          onPressed: () async {
            _profilePic = await Common().pickImageFromGallery();
          },
        ) :
        (name == 'idCard' ?
        IconButton(
          icon: const Icon(Icons.camera_alt),
          onPressed: () async {
             _navigateToCameraPage();
          },
        ): null ),
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

  void _navigateToCameraPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CameraPage(countryCode: Common().getCountryCode(_country))),
    );

    if (result != null) {
      setState(() {
        _idCard = result;
        _idCardSet = true;
        _formKeys[2].currentState?.fields['idCard']?.didChange(result);

      });

    }
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

           _password = formKey.currentState?.fields['password']?.value.trim();
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
