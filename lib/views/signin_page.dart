import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:client_0_0_1/AuthService.dart';
import 'package:client_0_0_1/helpers.dart';

class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final GlobalKey<FormBuilderState> _basicInfoFormKey = GlobalKey<FormBuilderState>();
  final GlobalKey<FormBuilderState> _addressInfoFormKey = GlobalKey<FormBuilderState>();
  final GlobalKey<FormBuilderState> _additionalInfoFormKey = GlobalKey<FormBuilderState>();
  final GlobalKey<FormBuilderState> _credentialsInfoFormKey = GlobalKey<FormBuilderState>();
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
          onStepTapped: (step) {
            setState(() {
              _currentStep = step;
            });
          },
          currentStep: _currentStep,
          onStepContinue: () {
            setState(() {
              if (_currentStep < 3) {
                _currentStep += 1;
              }
            });
          },
          onStepCancel: () {
            setState(() {
              if (_currentStep > 0) {
                _currentStep -= 1;
              }
            });
          },
          steps: [
            Step(
              title: const Text('Personal Info'),
              content: _buildBasicInfoStep(),
            ),
            Step(
              title: const Text('Address'),
              content: _buildAddressInfoStep(),
            ),
            Step(
              title: const Text('Additional Info'),
              content: _buildAdditionalInfoStep(),
            ),
            Step(
              title: const Text('Credentials'),
              content: _buildCredentialsStep(),
            ),
          ],
          controlsBuilder: (BuildContext context, ControlsDetails controlsDetails) {
            return Row(
              children: [
                if (controlsDetails.onStepCancel != null && _currentStep > 0)
                  TextButton(
                    onPressed: controlsDetails.onStepCancel,
                    child: const Text('Back'),
                  ),
                const SizedBox(width: 8),
                if (controlsDetails.onStepContinue != null)
                  TextButton(
                    onPressed: () {
                      GlobalKey<FormBuilderState> currentInfoformKey = _basicInfoFormKey;
                      switch(_currentStep){
                        case 0:
                          currentInfoformKey = _basicInfoFormKey;
                        case 1:
                          currentInfoformKey = _addressInfoFormKey;
                        case 2:
                          currentInfoformKey = _additionalInfoFormKey;
                        case 3:
                          currentInfoformKey = _credentialsInfoFormKey;
                      }
                      if (currentInfoformKey.currentState!.saveAndValidate()) {
                        bool isStepValid = validateCurrentStep();
                        if (isStepValid) {
                          controlsDetails.onStepContinue!();
                        }
                      }
                    },
                    child: const Text('Continue'),
                  ),
              ],
            );
          },

        ),
      ),
    );
  }

  bool validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        String fullName = _basicInfoFormKey.currentState!.fields['fullName']!.value;
        String userName = _basicInfoFormKey.currentState!.fields['username']!.value;
        return fullName.isNotEmpty && userName.isNotEmpty;

      case 1:
        String address = _addressInfoFormKey.currentState!.fields['address']!.value;
        String zipCode = _addressInfoFormKey.currentState!.fields['zipCode']!.value;
        String country = _addressInfoFormKey.currentState!.fields['country']!.value;
        return address.isNotEmpty && zipCode.isNotEmpty && country.isNotEmpty;

      case 2:
        String creditCard = _additionalInfoFormKey.currentState!.fields['creditCard']!.value;
        String email = _additionalInfoFormKey.currentState!.fields['email']!.value;
        return creditCard.isNotEmpty && email.isNotEmpty;

      case 3:
        String password = _credentialsInfoFormKey.currentState!.fields['password']!.value;
        String confirmPassword = _credentialsInfoFormKey.currentState!.fields['confirmPassword']!.value;
        return password.isNotEmpty && confirmPassword.isNotEmpty;

      default:
        return false;
    }
  }


  Widget _buildBasicInfoStep() {
    return FormBuilder(
      key: _basicInfoFormKey,
      child: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 3.5),
            _buildTextField('Full Name', 'fullName', Icons.person),
            const SizedBox(height: 10.0),
            _buildTextField('Username', 'username', Icons.account_circle),
            const SizedBox(height: 10.0),
            _buildGenderDropdown(),
            const SizedBox(height: 10.0),
            _buildTextField('Birthday', 'birthday', Icons.calendar_today, obscureText: false),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressInfoStep() {
    return FormBuilder(
      key: _addressInfoFormKey,
      child: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 3.5),
            _buildTextField('Address', 'address', Icons.location_on),
            const SizedBox(height: 10.0),
            _buildTextField('ZIP Code', 'zipCode', Icons.gps_fixed),
            const SizedBox(height: 10.0),
            _buildTextField('Country', 'country', Icons.flag),

          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoStep() {
    return FormBuilder(
      key: _additionalInfoFormKey,
      child: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 3.5),
            _buildTextField('Credit Card', 'creditCard', Icons.credit_card),
            const SizedBox(height: 10.0),
            _buildTextField('Email', 'email', Icons.email),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialsStep() {
    return FormBuilder(
      key: _credentialsInfoFormKey,
      child: SingleChildScrollView(
        physics: ClampingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 3.5),
            _buildTextField('Password', 'password', Icons.lock, obscureText: true),
            const SizedBox(height: 10.0),
            _buildTextField('Confirm Password', 'confirmPassword', Icons.lock, obscureText: true),

          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String name, IconData icon, {bool obscureText = false}) {
    return FormBuilderTextField(
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
      validator: FormBuilderValidators.required(
        errorText: 'This field is required',
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return FormBuilderDropdown(
      name: 'gender',
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: Icon(Icons.person_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      ),

      validator: FormBuilderValidators.required(),
      items: [
        'Masculine',
        'Feminine',
        'Androgynous',
        'TDI-1.9',
        'Bigender',
        'Gamma Ray Toaster',
        'Demiboy',
        'Ice Cream Bubble Machine',
        'Demigirl',
        'Apache helicopter',
        'Two-spirit',
        'Agender',
        'Edible Umbrella',
        'Neutrois',
        'Pangender',
        'Knuckles the Echidna',
        'Genderqueer',
        'Non-binary',
        'Genderfluid',
        'Cisgender',
        'Transgender',
        'Other (Are you fucking kidding me ?)'
      ]
          .map((gender) => DropdownMenuItem(
        value: gender,
        child: Text(gender),
      ))
          .toList(),
    );
  }

}
