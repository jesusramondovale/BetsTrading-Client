import 'package:flutter/material.dart';

class LocalizedStrings {
  LocalizedStrings(this.locale);

  final Locale locale;


  static LocalizedStrings? of(BuildContext context) {
    return Localizations.of<LocalizedStrings>(context, LocalizedStrings);
  }

  static final Map<String?, Map<String?, String?>> _localizedValues = {
    'en': { // Inglés
      'home': 'Home',
      'comingSoon': 'Coming soon...',
      'liveMarkets': 'Live Markets',
      'settings': 'Settings',
      'fullName': 'Full Name',
      'username': 'Username',
      'email': 'e-mail',
      'birthday': 'Birthday',
      'address': 'Address',
      'country': 'Country',
      'lastSession': 'Last Session',
      'logOut': 'Log Out',
      'logIn': 'Log In',
      'forgotPassword': 'Forgot Password?',
      'exit': 'Exit',
      'personalInfo': 'Personal Info',
      'gender': 'Gender',
      'continue': 'Continue',
      'creditCard': 'Credit Card',
      'zipCode': 'Zip Code',
      'back': 'Back',
      'cardNumber': 'Card Number',
      'expireDate': 'Expire Date',
      'cardHolder': 'Card Holder',
      'credentials': 'Credentials',
      'idCard': 'ID Card',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'acceptTerms': 'I accept the',
      'termsAndConditions': ' terms and conditions',
      'signIn': 'Sign In',
      'pleaseEnterUsername': 'Please enter your user name',
      'pleaseEnterPassword': 'Please enter your password',
      'connecting': 'Connecting ...',
      'welcome': 'Welcome',
      'registrationSuccessful': 'Registration successful!',
      'pleaseEnterCardNumber': 'Please enter card number',
      'enterDate': 'Enter a date',
      'pleaseEnterCVV': 'Please enter CVV',
      'pleaseEnterCardHolderName': 'Please enter card holder name',
      'thisFieldIsRequired': 'This field is required',
      'enterValidEmail': 'Enter a valid email address',
      'passwordsNotMatching': 'Passwords not matching',
      'acceptTermsToContinue': 'Accept the terms and conditions to continue',
      'notAvailable': 'Not available',
      'success': 'Success!',
      'profilePictureUploadedSuccessfully': 'Profile picture uploaded successfully',
      'errorUploadingProfilePic': 'An error has occurred while uploading the profile pic',
      'noInfoAvailable': 'No info available!',
      'favs': 'Favourites',
      'currentBalance': 'Current balance',
      'mostCommon': 'Most common',
      'totalBet': 'My account',
      'recentBets': 'Recent bets',
      'liveBets': 'Live bets',
      'darkMode': 'Dark mode',
      'attention': 'Attention!',
      'needToRestart': 'The application needs to be restarted. Please enter again',
      'wallet':'My wallet',
      'staked' : 'Staked'
    },
    'es': { // Español
      'home': 'Inicio',
      'comingSoon': 'Próximamente...',
      'liveMarkets': 'Mercados',
      'settings': 'Ajustes',
      'fullName': 'Nombre Completo',
      'username': 'Nombre de Usuario',
      'email': 'Correo Electrónico',
      'birthday': 'Fecha de Nacimiento',
      'address': 'Dirección',
      'country': 'País',
      'lastSession': 'Última Sesión',
      'logOut': 'Cerrar Sesión',
      'logIn': 'Iniciar Sesión',
      'forgotPassword': '¿Olvidaste tu contraseña?',
      'exit': 'Salir',
      'personalInfo': 'Información Personal',
      'gender': 'Género',
      'continue': 'Continuar',
      'creditCard': 'Tarjeta de Crédito',
      'zipCode': 'Código Postal',
      'back': 'Volver',
      'cardNumber': 'Número de Tarjeta',
      'expireDate': 'Fecha de Expiración',
      'cardHolder': 'Titular de la Tarjeta',
      'credentials': 'Credenciales',
      'idCard': 'Documento de Identidad',
      'password': 'Contraseña',
      'confirmPassword': 'Confirmar Contraseña',
      'acceptTerms': 'Acepto los',
      'termsAndConditions': ' términos y condiciones',
      'signIn': 'Registrarse',
      'pleaseEnterUsername': 'Por favor, ingresa tu nombre de usuario',
      'pleaseEnterPassword': 'Por favor, ingresa tu contraseña',
      'connecting': 'Conectando ...',
      'welcome': 'Bienvenido',
      'registrationSuccessful': '¡Registro exitoso!',
      'pleaseEnterCardNumber': 'Por favor, introduce el número de la tarjeta',
      'enterDate': 'Introduce una fecha',
      'pleaseEnterCVV': 'Por favor, introduce el CVV',
      'pleaseEnterCardHolderName': 'Por favor, introduce el nombre del titular de la tarjeta',
      'thisFieldIsRequired': 'Este campo es obligatorio',
      'enterValidEmail': 'Introduce una dirección de correo válida',
      'passwordsNotMatching': 'Las contraseñas no coinciden',
      'acceptTermsToContinue': 'Acepta los términos y condiciones para continuar',
      'notAvailable': 'No disponible',
      'success': '¡Éxito!',
      'profilePictureUploadedSuccessfully': 'Foto de perfil subida con éxito',
      'errorUploadingProfilePic': 'Ha ocurrido un error al subir la foto de perfil',
      'noInfoAvailable': '¡No hay información disponible!',
      'favs': 'Favoritos',
      'currentBalance': 'Balance actual',
      'mostCommon': 'Más comunes',
      'totalBet': 'Mi cuenta',
      'recentBets': 'Apuestas recientes',
      'liveBets': 'Apuestas en directo',
      'darkMode': 'Modo oscuro',
      'attention': 'Atención!',
      'needToRestart': 'La aplicación debe reiniciarse. Entre de nuevo',
      'wallet':'Mi cartera',
      'staked' : 'Apostado'
    },
    'fr': { // Francés
      'home': 'Accueil',
      'comingSoon': 'Bientôt disponible...',
      'liveMarkets': 'Marchés en Direct',
      'settings': 'Paramètres',
      'fullName': 'Nom Complet',
      'username': "Nom d'utilisateur",
      'email': 'e-mail',
      'birthday': 'Anniversaire',
      'address': 'Adresse',
      'country': 'Pays',
      'lastSession': 'Dernière Session',
      'logOut': 'Déconnexion',
      'logIn': 'Connexion',
      'forgotPassword': 'Mot de passe oublié?',
      'exit': 'Sortir',
      'personalInfo': 'Infos Personnelles',
      'gender': 'Genre',
      'continue': 'Continuer',
      'creditCard': 'Carte de Crédit',
      'zipCode': 'Code Postal',
      'back': 'Retour',
      'cardNumber': 'Numéro de Carte',
      'expireDate': 'Date d’Expiration',
      'cardHolder': 'Titulaire de la Carte',
      'credentials': 'Identifiants',
      'idCard': 'Carte d’Identité',
      'password': 'Mot de passe',
      'confirmPassword': 'Confirmer le Mot de Passe',
      'acceptTerms': "J'accepte les",
      'termsAndConditions': ' termes et conditions',
      'signIn': 'Se Connecter',
      'pleaseEnterUsername': 'Veuillez entrer votre nom d’utilisateur',
      'pleaseEnterPassword': 'Veuillez entrer votre mot de passe',
      'connecting': 'Connexion ...',
      'welcome': 'Bienvenue',
      'registrationSuccessful': 'Inscription réussie!',
      'pleaseEnterCardNumber': 'Veuillez entrer le numéro de carte',
      'enterDate': 'Entrez une date',
      'pleaseEnterCVV': 'Veuillez entrer le CVV',
      'pleaseEnterCardHolderName': 'Veuillez entrer le nom du titulaire de la carte',
      'thisFieldIsRequired': 'Ce champ est obligatoire',
      'enterValidEmail': 'Entrez une adresse e-mail valide',
      'passwordsNotMatching': 'Les mots de passe ne correspondent pas',
      'acceptTermsToContinue': 'Acceptez les termes et conditions pour continuer',
      'notAvailable': 'Non disponible',
      'success': 'Succès!',
      'profilePictureUploadedSuccessfully': 'Photo de profil téléchargée avec succès',
      'errorUploadingProfilePic': "Une erreur s'est produite lors du téléchargement de la photo de profil",
      'noInfoAvailable': 'Pas d\'info disponible!',
      'favs': 'Favoris',
      'currentBalance': 'Solde actuel',
      'mostCommon': 'Plus courants',
      'totalBet': 'Mon caccount',
      'recentBets': 'Paris Récents',
      'liveBets': 'Paris en direct',
      'darkMode': 'Mode Sombre',
      'attention': 'Attention',
      'needToRestart' : "L'application doit être redémarrée. Entrez à nouveau",
      'wallet': 'Mon portefeuille',
      'staked' : 'Misé'
    },
    'it': { // Italiano
      'home': 'Home',
      'comingSoon': 'Prossimamente...',
      'liveMarkets': 'Mercati dal Vivo',
      'settings': 'Impostazioni',
      'fullName': 'Nome Completo',
      'username': 'Nome Utente',
      'email': 'e-mail',
      'birthday': 'Compleanno',
      'address': 'Indirizzo',
      'country': 'Paese',
      'lastSession': 'Ultima Sessione',
      'logOut': 'Esci',
      'logIn': 'Accedi',
      'forgotPassword': 'Hai dimenticato la password?',
      'exit': 'Esci',
      'personalInfo': 'Informazioni Personali',
      'gender': 'Genere',
      'continue': 'Continua',
      'creditCard': 'Carta di Credito',
      'zipCode': 'Codice Postale',
      'back': 'Indietro',
      'cardNumber': 'Numero di Carta',
      'expireDate': 'Data di Scadenza',
      'cardHolder': 'Intestatario della Carta',
      'credentials': 'Credenziali',
      'idCard': 'Carta d’Identità',
      'password': 'Password',
      'confirmPassword': 'Conferma Password',
      'acceptTerms': 'Accetto i ',
      'termsAndConditions': ' termini e le condizioni',
      'signIn': 'Accedi',
      'pleaseEnterUsername': 'Per favore, inserisci il tuo nome utente',
      'pleaseEnterPassword': 'Per favore, inserisci la tua password',
      'connecting': 'Connessione ...',
      'welcome': 'Benvenuto',
      'registrationSuccessful': 'Registrazione completata!',
      'pleaseEnterCardNumber': 'Per favore, inserisci il numero della carta',
      'enterDate': 'Inserisci una data',
      'pleaseEnterCVV': 'Per favore, inserisci il CVV',
      'pleaseEnterCardHolderName': 'Per favore, inserisci il nome del titolare della carta',
      'thisFieldIsRequired': 'Questo campo è obbligatorio',
      'enterValidEmail': 'Inserisci un indirizzo email valido',
      'passwordsNotMatching': 'Le password non corrispondono',
      'acceptTermsToContinue': 'Accetta i termini e le condizioni per continuare',
      'notAvailable': 'Non disponibile',
      'success': 'Successo!',
      'profilePictureUploadedSuccessfully': 'Immagine del profilo caricata con successo',
      'errorUploadingProfilePic': "Si è verificato un errore durante il caricamento dell'immagine del profilo",
      'noInfoAvailable': 'Nessuna informazione disponibile!',
      'favs': 'Preferiti',
      'currentBalance': 'Saldo attuale',
      'mostCommon': 'Più comuni',
      'totalBet': 'il mio Totale',
      'recentBets': 'Scommesse Recenti',
      'liveBets': 'Scommesse live',
      'darkMode': 'Modalità Scuro',
      'attention': 'Attenzione!',
      'needToRestart' : "L'applicazione deve essere riavviata. Entra di nuovo",
      'wallet': 'Portafoglio',
      'staked' : 'Scommeso'
    },
    'de': { // Alemán
      'home': 'Startseite',
      'comingSoon': 'Demnächst...',
      'liveMarkets': 'Live-Märkte',
      'settings': 'Einstellungen',
      'fullName': 'Vollständiger Name',
      'username': 'Benutzername',
      'email': 'E-Mail',
      'birthday': 'Geburtstag',
      'address': 'Adresse',
      'country': 'Land',
      'lastSession': 'Letzte Sitzung',
      'logOut': 'Abmelden',
      'logIn': 'Anmelden',
      'forgotPassword': 'Passwort vergessen?',
      'exit': 'Verlassen',
      'personalInfo': 'Persönliche Infos',
      'gender': 'Geschlecht',
      'continue': 'Fortsetzen',
      'creditCard': 'Kreditkarte',
      'zipCode': 'Postleitzahl',
      'back': 'Zurück',
      'cardNumber': 'Kartennummer',
      'expireDate': 'Ablaufdatum',
      'cardHolder': 'Karteninhaber',
      'credentials': 'Anmeldeinformationen',
      'idCard': 'Personalausweis',
      'password': 'Passwort',
      'confirmPassword': 'Passwort bestätigen',
      'acceptTerms': 'Ich akzeptiere die',
      'termsAndConditions': ' Geschäftsbedingungen',
      'signIn': 'Anmelden',
      'pleaseEnterUsername': 'Bitte geben Sie Ihren Benutzernamen ein',
      'pleaseEnterPassword': 'Bitte geben Sie Ihr Passwort ein',
      'connecting': 'Verbinden ...',
      'welcome': 'Willkommen',
      'registrationSuccessful': 'Registrierung erfolgreich!',
      'pleaseEnterCardNumber': 'Bitte geben Sie die Kartennummer ein',
      'enterDate': 'Geben Sie ein Datum ein',
      'pleaseEnterCVV': 'Bitte geben Sie die CVV ein',
      'pleaseEnterCardHolderName': 'Bitte geben Sie den Namen des Karteninhabers ein',
      'thisFieldIsRequired': 'Dieses Feld ist erforderlich',
      'enterValidEmail': 'Geben Sie eine gültige E-Mail-Adresse ein',
      'passwordsNotMatching': 'Passwörter stimmen nicht überein',
      'acceptTermsToContinue': 'Akzeptieren Sie die Allgemeinen Geschäftsbedingungen, um fortzufahren',
      'notAvailable': 'Nicht verfügbar',
      'success': 'Erfolg!',
      'profilePictureUploadedSuccessfully': 'Profilbild erfolgreich hochgeladen',
      'errorUploadingProfilePic': 'Beim Hochladen des Profilbildes ist ein Fehler aufgetreten',
      'noInfoAvailable': 'Keine Informationen verfügbar!',
      'favs': 'Favoriten',
      'currentBalance': 'Aktueller saldo',
      'mostCommon': 'Am häufigsten',
      'totalBet': 'Gesamtwetteinsatz ',
      'liveBets': 'Live-Wetten',
      'recentBets': 'Letzte Wetten',
      'darkMode': 'Dunkler Modus',
      'attention': 'Achtung',
      'needToRestart' : 'Die Anwendung muss neu gestartet werden. Treten Sie erneut ein',
      'wallet': 'Meine Geldbörse',
      'staked' : 'Gewettet'
    },
  };


  String? get menu => _localizedValues[locale.languageCode]?['menu'];
  String? get profile => _localizedValues[locale.languageCode]?['profile'];
  String? get home => _localizedValues[locale.languageCode]?['home'];
  String? get comingSoon => _localizedValues[locale.languageCode]?['comingSoon'];
  String? get liveMarkets => _localizedValues[locale.languageCode]?['liveMarkets'];
  String? get settings => _localizedValues[locale.languageCode]?['settings'];
  String? get fullName => _localizedValues[locale.languageCode]?['fullName'];
  String? get username => _localizedValues[locale.languageCode]?['username'];
  String? get email => _localizedValues[locale.languageCode]?['email'];
  String? get birthday => _localizedValues[locale.languageCode]?['birthday'];
  String? get address => _localizedValues[locale.languageCode]?['address'];
  String? get country => _localizedValues[locale.languageCode]?['country'];
  String? get lastSession => _localizedValues[locale.languageCode]?['lastSession'];
  String? get logOut => _localizedValues[locale.languageCode]?['logOut'];
  String? get logIn => _localizedValues[locale.languageCode]?['logIn'];
  String? get forgotPassword => _localizedValues[locale.languageCode]?['forgotPassword'];
  String? get exit => _localizedValues[locale.languageCode]?['exit'];
  String? get personalInfo => _localizedValues[locale.languageCode]?['personalInfo'];
  String? get gender => _localizedValues[locale.languageCode]?['gender'];
  String? get continueText => _localizedValues[locale.languageCode]?['continue'];
  String? get creditCard => _localizedValues[locale.languageCode]?['creditCard'];
  String? get zipCode => _localizedValues[locale.languageCode]?['zipCode'];
  String? get back => _localizedValues[locale.languageCode]?['back'];
  String? get cardNumber => _localizedValues[locale.languageCode]?['cardNumber'];
  String? get expireDate => _localizedValues[locale.languageCode]?['expireDate'];
  String? get cardHolder => _localizedValues[locale.languageCode]?['cardHolder'];
  String? get credentials => _localizedValues[locale.languageCode]?['credentials'];
  String? get idCard => _localizedValues[locale.languageCode]?['idCard'];
  String? get password => _localizedValues[locale.languageCode]?['password'];
  String? get confirmPassword => _localizedValues[locale.languageCode]?['confirmPassword'];
  String? get acceptTerms => _localizedValues[locale.languageCode]?['acceptTerms'];
  String? get termsAndConditions => _localizedValues[locale.languageCode]?['termsAndConditions'];
  String? get signIn => _localizedValues[locale.languageCode]?['signIn'];
  String? get pleaseEnterUsername => _localizedValues[locale.languageCode]?['pleaseEnterUsername'];
  String? get pleaseEnterPassword => _localizedValues[locale.languageCode]?['pleaseEnterPassword'];
  String? get connecting => _localizedValues[locale.languageCode]?['connecting'];
  String? get registrationSuccessful => _localizedValues[locale.languageCode]?['registrationSuccessful'];
  String? get pleaseEnterCardNumber => _localizedValues[locale.languageCode]?['pleaseEnterCardNumber'];
  String? get enterDate => _localizedValues[locale.languageCode]?['enterDate'];
  String? get welcome => _localizedValues[locale.languageCode]?['welcome'];
  String? get pleaseEnterCVV => _localizedValues[locale.languageCode]?['pleaseEnterCVV'];
  String? get pleaseEnterCardHolderName => _localizedValues[locale.languageCode]?['pleaseEnterCardHolderName'];
  String? get thisFieldIsRequired => _localizedValues[locale.languageCode]?['thisFieldIsRequired'];
  String? get enterValidEmail => _localizedValues[locale.languageCode]?['enterValidEmail'];
  String? get passwordsNotMatching => _localizedValues[locale.languageCode]?['passwordsNotMatching'];
  String? get acceptTermsToContinue => _localizedValues[locale.languageCode]?['acceptTermsToContinue'];
  String? get notAvailable => _localizedValues[locale.languageCode]?['notAvailable'];
  String? get success => _localizedValues[locale.languageCode]?['success'];
  String? get profilePictureUploadedSuccessfully => _localizedValues[locale.languageCode]?['profilePictureUploadedSuccessfully'];
  String? get errorUploadingProfilePic => _localizedValues[locale.languageCode]?['errorUploadingProfilePic'];
  String? get noInfoAvailable => _localizedValues[locale.languageCode]?['noInfoAvailable'];
  String? get favs => _localizedValues[locale.languageCode]?['favs'];
  String? get currentBalance => _localizedValues[locale.languageCode]?['currentBalance'];
  String? get mostCommon => _localizedValues[locale.languageCode]?['mostCommon'];
  String? get totalBet => _localizedValues[locale.languageCode]?['totalBet'];
  String? get recentBets => _localizedValues[locale.languageCode]?['recentBets'];
  String? get darkMode => _localizedValues[locale.languageCode]?['darkMode'];
  String? get attention => _localizedValues[locale.languageCode]?['attention'];
  String? get needToRestart => _localizedValues[locale.languageCode]?['needToRestart'];
  String? get liveBets => _localizedValues[locale.languageCode]?['liveBets'];
  String? get wallet => _localizedValues[locale.languageCode]?['wallet'];
  String? get staked => _localizedValues[locale.languageCode]?['staked'];
}

class LocalizedStringsDelegate extends LocalizationsDelegate<LocalizedStrings> {
  const LocalizedStringsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'es', 'fr', 'it', 'de'].contains(locale.languageCode);

  @override
  Future<LocalizedStrings> load(Locale locale) async {
    return LocalizedStrings(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<LocalizedStrings> old) => false;
}

