import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:country_flags/country_flags.dart';

import 'package:client_0_0_1/AuthService.dart';
import 'package:client_0_0_1/helpers.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final _formKeys = List.generate(4, (_) => GlobalKey<FormBuilderState>());
  final GlobalKey<FormState> _creditCardFormKey = GlobalKey<FormState>();

  bool _autoValidateCreditCardForm = false;
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),

          child: Stepper(
            onStepTapped: _onStepTapped,
            currentStep: _currentStep,
            onStepContinue: _onStepContinue,
            onStepCancel: _onStepCancel,
            steps: _buildSteps(),
            controlsBuilder: _buildControls,
          ),
      ),
    );
  }

  void _onStepTapped(int step) {
    setState(() => _currentStep = step);
  }

  void _onStepContinue() {
    if (_currentStep == _formKeys.length - 1)
    {
      Helpers().unimplementedAction("signIn()", context);
    }
    else {
      switch (_currentStep) {
        case 2:

          if (_creditCardFormKey.currentState?.validate() ?? false) {

            setState(() {
              if (_currentStep < _formKeys.length - 1) {
                _currentStep++;
              }
            });
          } else {

            setState(() {
              _autoValidateCreditCardForm = true;
            });
          }

          break;

        /* TO-DO!!
        case 3:
          COMPRUEBA los validate() de todos los steps
          Helpers().SignIn()
          break;
         */

        default:

          setState(() {
            if (_currentStep < _formKeys.length - 1) {
              _currentStep++;
            }
          });
          break;
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

  List<Step> _buildSteps() {
    return [
      Step(
        title: Text('Personal info'),
        content: _buildBasicInfoStep(),
        isActive: _currentStep == 0,
      ),
      Step(
        title: Text('Address'),
        content: _buildAddressInfoStep(),
        isActive: _currentStep == 1,
      ),
      Step(
        title: Text('Credit card'),
        content: _buildCreditCardInfoStep(),
        isActive: _currentStep == 2,
      ),
      Step(
        title: Text('Credentials'),
        content: _buildCredentialsStep(),
        isActive: _currentStep == 3,
      ),
    ];
  }

  Widget _buildControls(BuildContext context, ControlsDetails details) {
    return Row(
      children: [
        if (_currentStep > 0)
          TextButton(
            onPressed: details.onStepCancel,
            child: const Text('Back'),
          ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () {
            if (_validateAndSaveCurrentStep()) {
              details.onStepContinue?.call();
            }
          },
          child: Text(_currentStep == _formKeys.length - 1 ? 'Sign In' : 'Continue'),
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

  Widget _buildBasicInfoStep() {
    return FormBuilder(
      key: _formKeys[0],
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 4.5),
            _buildTextField('Full Name', 'fullName', Icons.person, false),
            const SizedBox(height: 10.0),
            _buildTextField('Username', 'username', Icons.account_circle,false),
            const SizedBox(height: 10.0),
            _buildGenderDropdown(),
            const SizedBox(height: 10.0),
            _buildTextField(
              'Birthday',
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

  Widget _buildAddressInfoStep() {
    return FormBuilder(
      key: _formKeys[1],
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 4),
            _buildTextField('Address', 'address', Icons.location_on, false),
            const SizedBox(height: 10.0),
            _buildTextField('ZIP Code', 'zipCode', Icons.gps_fixed, false),
            const SizedBox(height: 10.0),
            _buildCountryDropdown(),
          ],
        ),
      ),
    );
  }

  List<String> _getTop50Countries() {
    return [
      'China', 'India', 'United States', 'Indonesia', 'Pakistan',
      'Brazil', 'Nigeria', 'Bangladesh', 'Russia', 'Mexico',
      'Japan', 'Ethiopia', 'Philippines', 'Egypt', 'Vietnam',
      'DR Congo', 'Turkey', 'Iran', 'Germany', 'Thailand',
      'United Kingdom', 'France', 'Italy', 'Tanzania', 'South Africa',
      'Myanmar', 'Kenya', 'South Korea', 'Colombia', 'Spain',
      // ... y 20 países más hasta completar 50 ...
    ];
  }

  String _selectedCountry = '';

  Widget _buildCountryDropdown() {
    return FormBuilderDropdown(
      name: 'country',
      decoration: InputDecoration(
        labelText: 'Country',
        prefixIcon: const Icon(Icons.flag),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      ),
      validator: FormBuilderValidators.required(),
      items: Helpers().getTopCountries().map((countryMap) {
        return DropdownMenuItem(
          alignment: AlignmentDirectional.center,
          value: countryMap['name'],
          child: Row(
            children: <Widget>[
              CountryFlag.fromCountryCode(
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

  Widget _buildCreditCardInfoStep() {
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
      cardNumberValidator: (value) => value != null && value.isNotEmpty && value.length == 19 ? null : 'Please enter card number',
      expiryDateValidator: (value) => value != null && value.isNotEmpty && value.length == 5 ? null : 'Enter a date',
      cvvValidator: (value) => value != null && value.isNotEmpty && (value.length == 3 || value.length == 4) ? null : 'Please enter CVV',
      cardHolderValidator: (value) => value != null && value.isNotEmpty ? null : 'Please enter card holder name',
    );
  }

  void _onCreditCardModelChange(CreditCardModel creditCardModel) {
    // Actualiza los controladores con el nuevo modelo
    _cardNumberController.text = creditCardModel.cardNumber;
    _expiryDateController.text = creditCardModel.expiryDate;
    _cardHolderNameController.text = creditCardModel.cardHolderName;
    _cvvCodeController.text = creditCardModel.cvvCode;
  }

  Widget _buildCredentialsStep() {
    return FormBuilder(
      key: _formKeys[3],
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 4),
            _buildEmailField('Email', 'email', Icons.email, false),
            const SizedBox(height: 10.0),
            _buildPasswordField('Password', 'password', Icons.lock, false, _formKeys[3], obscureText: true),
            const SizedBox(height: 10.0),
            _buildPasswordField('Confirm Password', 'confirmPassword', Icons.lock, false, _formKeys[3], obscureText: true),
            _buildTermsAndConditionsCheckbox(),

          ],
        ),
      ),
    );
  }

  Widget _buildEmailField(String label, String name, IconData icon, bool readonly, {void Function()? onTap, bool isIconEnabled = true}) {
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
      keyboardType: TextInputType.emailAddress, // Especifica el tipo de teclado para emails
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: 'This field is required'),
        FormBuilderValidators.email(errorText: 'Enter a valid email address'), // Validación de email
      ]),
    );
  }

  Widget _buildTermsAndConditionsCheckbox() {
    return FormBuilderCheckbox(
      name: 'acceptTerms',
      initialValue: false,
      title: RichText(
        text: TextSpan(
          children: [
            const TextSpan(
              text: 'I accept the ',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 16
              ),
            ),
            TextSpan(
              text: 'terms and conditions',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = ()
                {
                  //TO-DO
                  Helpers().unimplementedAction("seeTerms()", context);
                },
            ),
          ],
        ),
      ),
      validator: FormBuilderValidators.equal(
        true,
        errorText: 'Accept the terms and conditions to continue',
      ),
    );
  }

  Widget _buildTextField(String label, String name, IconData icon, bool readonly,{bool obscureText = false, void Function()? onTap}) {
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
      validator: FormBuilderValidators.required(
        errorText: 'This field is required',
      ),
    );
  }

  Widget _buildPasswordField(String label, String name, IconData icon, bool readonly, GlobalKey<FormBuilderState> formKey, {bool obscureText = true, void Function()? onTap}) {
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
          return 'This field is required';
        }
        if (name == 'confirmPassword') {
          final passwordValue = formKey.currentState?.fields['password']?.value;
          if (val != passwordValue) {
            return 'Passwords not matching';
          }
        }
        return null;
      },
    );
  }

  Widget _buildGenderDropdown() {
    return FormBuilderDropdown(
      name: 'gender',
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      ),
      validator: FormBuilderValidators.required(),
      items: [
        'Masculine',
        'Feminine',
        'Non-Binary',
        'Cisgender',
        'TDI 1.9',
        'Autobot',
        'Genderqueer',
        'Medabot Type KBT',
        'Sonic the Hedhehog',
        'Agender',
        'Bigender',
        'Napoleón Bonaparte',
        'Doraemon',
        'Transgender',
        'Transfeminine',
        'Decepticon',
        'Transmasculine',
        'LOL',
        'Apache Combat Helicopter',
        'Nigga',
        'Medabot Type KWG',
        'SSD Toshiba 512GB',
        'Neutrois',
        'Dont fucking know',
        'Snorlax',

        // .........
      ].map((gender) => DropdownMenuItem(
        value: gender,
        child: Text(gender),
      )).toList(),
    );
  }

  // Unused
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
      keyboardType: TextInputType.number, // Establece el tipo de teclado a numérico
      inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Acepta solo dígitos
      validator: FormBuilderValidators.compose([
        FormBuilderValidators.required(errorText: 'This field is required'),
        FormBuilderValidators.numeric(errorText: 'Please enter a valid number'), // Validación adicional para números
      ]),
    );
  }

  @override
  void dispose() {
    // Limpia los controladores cuando el widget se destruya
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
