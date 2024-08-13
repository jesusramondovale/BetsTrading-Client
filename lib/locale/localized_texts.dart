import 'package:flutter/material.dart';

class LocalizedStrings {
  LocalizedStrings(this.locale);

  final Locale locale;



  static LocalizedStrings? of(BuildContext context) {
    return Localizations.of<LocalizedStrings>(context, LocalizedStrings);
  }

  static final Map<String?, Map<String?, String?>> _localizedValues = {
    'en': {
      // Inglés
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
      'profilePictureUploadedSuccessfully':
          'Profile picture uploaded successfully',
      'errorUploadingProfilePic':
          'An error has occurred while uploading the profile pic',
      'noInfoAvailable': 'No info available!',
      'favs': 'Favourites',
      'currentBalance': 'Current balance',
      'mostCommon': 'Most common',
      'totalBet': 'My account',
      'recentBets': 'Recent bets',
      'liveBets': 'Trends',
      'darkMode': 'Dark mode',
      'attention': 'Attention!',
      'needToRestart':
          'The application needs to be restarted. Please enter again',
      'wallet': 'My wallet',
      'staked': 'Staked',
      'indexes': 'Indexes',
      'shares': 'Shares',
      'commodities': 'Commodities',
      'googleSignIn': 'Continue with Google',
      'appleSignIn': 'Continue with Apple ID',
      'commonSignIn': 'E-mail log-in',
      'backToSocialsLogin': 'Back to Social Login',
      'noLiveBets':
          'You have no live bets at the moment, go to the markets tab to create a new one.',
      'noClosedBets': 'There are no closed bets\n(for now ...) 😏',
      'changePassword': 'Change Password',
      'notifications': 'Notifications',
      'contentSettings': 'Content Settings',
      'paymentHistory': 'Payment History',
      'aboutUs': 'About Us',
      'versionCode': 'Version code: ',
      'close': 'Close',
      'current': 'Current',
      'updatedFavs' : 'Updated favorites!',
      'noFavsYet' : 'Youve got no favorites yet!',
      'removedSuccesfully' : 'Removed succesfully!',
      'betAmount': 'Bet Amount',
      'originValue': 'Origin Value',
      'currentValue': 'Current Value',
      'targetValue': 'Target Value',
      'targetDate': 'Target Date',
      'targetMargin': 'Target Margin',
      'winBonus': 'Win Bonus',
      'verify': 'Verify Account',
      'verified': 'Account Verified!',
      'ranking': 'Ranking'

    },
    'es': {
      // Español
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
      'pleaseEnterCardHolderName':
          'Por favor, introduce el nombre del titular de la tarjeta',
      'thisFieldIsRequired': 'Este campo es obligatorio',
      'enterValidEmail': 'Introduce una dirección de correo válida',
      'passwordsNotMatching': 'Las contraseñas no coinciden',
      'acceptTermsToContinue':
          'Acepta los términos y condiciones para continuar',
      'notAvailable': 'No disponible',
      'success': '¡Éxito!',
      'profilePictureUploadedSuccessfully': 'Foto de perfil subida con éxito',
      'errorUploadingProfilePic':
          'Ha ocurrido un error al subir la foto de perfil',
      'noInfoAvailable': '¡No hay información disponible!',
      'favs': 'Favoritos',
      'currentBalance': 'Balance actual',
      'mostCommon': 'Más comunes',
      'totalBet': 'Mi cuenta',
      'recentBets': 'Bets recientes',
      'liveBets': 'Tendencias',
      'darkMode': 'Modo oscuro',
      'attention': 'Atención!',
      'needToRestart': 'La aplicación debe reiniciarse. Entre de nuevo',
      'wallet': 'Mi cartera',
      'staked': 'Apostado',
      'indexes': 'Índices',
      'shares': 'Acciones',
      'commodities': 'Materias primas',
      'googleSignIn': 'Continuar con Google',
      'appleSignIn': 'Continuar con Apple ID',
      'commonSignIn': 'Inicio de sesión con e-mail',
      'backToSocialsLogin': 'Inicio de sesión social',
      'noLiveBets':
          'No tienes apuestas en directo en este momento, vaya a la pestaña de mercados para crear una nueva',
      'noClosedBets': 'No existen apuestas cerradas\n(por ahora...) 😏',
      'personalInfo': 'Información personal',
      'changePassword': 'Cambiar contraseña',
      'notifications': 'Notificaciones',
      'contentSettings': 'Ajustes de contenido',
      'paymentHistory': 'Historial de pagos',
      'aboutUs': 'Sobre nosotros',
      'versionCode': 'Versión de código: ',
      'close': 'Cierre',
      'current': 'Actual',
      'updatedFavs' : 'Favoritos actualizados!',
      'noFavsYet' : '¡Aún no tienes favoritos!',
      'removedSuccesfully' : 'Borrado con éxito!',
      'betAmount': 'Apostado',
      'originValue': 'Valor de Origen',
      'currentValue': 'Valor Actual',
      'targetValue': 'Valor Objetivo',
      'targetDate': 'Fecha Objetivo',
      'targetMargin': 'Margen Objetivo',
      'winBonus': 'Bono de acierto',
      'verify': 'Verificar Cuenta',
      'verified': 'Cuenta verificada!',
      'ranking': 'Rankings'
    },
    'fr': {
      // Francés
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
      'pleaseEnterCardHolderName':
          'Veuillez entrer le nom du titulaire de la carte',
      'thisFieldIsRequired': 'Ce champ est obligatoire',
      'enterValidEmail': 'Entrez une adresse e-mail valide',
      'passwordsNotMatching': 'Les mots de passe ne correspondent pas',
      'acceptTermsToContinue':
          'Acceptez les termes et conditions pour continuer',
      'notAvailable': 'Non disponible',
      'success': 'Succès!',
      'profilePictureUploadedSuccessfully':
          'Photo de profil téléchargée avec succès',
      'errorUploadingProfilePic':
          "Une erreur s'est produite lors du téléchargement de la photo de profil",
      'noInfoAvailable': 'Pas d\'info disponible!',
      'favs': 'Favoris',
      'currentBalance': 'Solde actuel',
      'mostCommon': 'Plus courants',
      'totalBet': 'Mon caccount',
      'recentBets': 'Paris Récents',
      'liveBets': 'Tendances',
      'darkMode': 'Mode Sombre',
      'attention': 'Attention',
      'needToRestart': "L'application doit être redémarrée. Entrez à nouveau",
      'wallet': 'Mon portefeuille',
      'staked': 'Misé',
      'indexes': 'Indices',
      'shares': ' Actions',
      'commodities': 'Matières premières',
      'googleSignIn': 'Connexion avec Google',
      'appleSignIn': 'Connexion avec Apple ID',
      'commonSignIn': 'Connexion avec e-mail',
      'backToSocialsLogin': 'Retour à la connexion sociale',
      'noLiveBets':
          'Vous n\'avez aucun pari en direct pour le moment, rendez-vous sur l\'onglet des marchés pour en créer un nouveau.',
      'noClosedBets': 'Il n\'y a pas encore de paris fermés',
      'personalInfo': 'Informations personnelles',
      'changePassword': 'Changer le mot de passe',
      'notifications': 'Notifications',
      'contentSettings': 'Paramètres de contenu',
      'paymentHistory': 'Historique de paiements',
      'aboutUs': 'À propos de nous',
      'versionCode': 'Code de version : ',
      'close': 'Clôture',
      'current': 'Actuel',
      'updatedFavs' : 'Favoris mis à jour',
      'noFavsYet' : 'Vous n\'avez pas encore de favoris !',
      'removedSuccesfully' : 'Supprimé avec succès',
      'betAmount': 'Montant de la Mise',
      'originValue': 'Valeur d\'Origine',
      'currentValue': 'Valeur Actuelle',
      'targetValue': 'Valeur Cible',
      'targetDate': 'Date Cible',
      'targetMargin': 'Marge Cible',
      'winBonus': 'Bonus de Gain',
      'verify': 'Vérifier le compte',
      'verified': 'Compte vérifié!',
      'ranking': 'Classement'
    },
    'it': {
      // Italiano
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
      'pleaseEnterCardHolderName':
          'Per favore, inserisci il nome del titolare della carta',
      'thisFieldIsRequired': 'Questo campo è obbligatorio',
      'enterValidEmail': 'Inserisci un indirizzo email valido',
      'passwordsNotMatching': 'Le password non corrispondono',
      'acceptTermsToContinue':
          'Accetta i termini e le condizioni per continuare',
      'notAvailable': 'Non disponibile',
      'success': 'Successo!',
      'profilePictureUploadedSuccessfully':
          'Immagine del profilo caricata con successo',
      'errorUploadingProfilePic':
          "Si è verificato un errore durante il caricamento dell'immagine del profilo",
      'noInfoAvailable': 'Nessuna informazione disponibile!',
      'favs': 'Preferiti',
      'currentBalance': 'Saldo attuale',
      'mostCommon': 'Più comuni',
      'totalBet': 'il mio Totale',
      'recentBets': 'Scommesse Recenti',
      'liveBets': 'Tendenze',
      'darkMode': 'Modalità Scuro',
      'attention': 'Attenzione!',
      'needToRestart': "L'applicazione deve essere riavviata. Entra di nuovo",
      'wallet': 'Portafoglio',
      'staked': 'Scommeso',
      'indexes': 'Indici',
      'shares': 'Azioni',
      'commodities': 'Materie prime',
      'googleSignIn': 'Accesso con Google',
      'appleSignIn': 'Accesso con Apple ID',
      'commonSignIn': 'Accesso con e-mail',
      'backToSocialsLogin': 'Torna al login social',
      'noLiveBets':
          'Non hai scommesse dal vivo in questo momento, vai alla scheda dei mercati per crearne una nuova.',
      'noClosedBets': 'Non ci sono scommesse chiuse\n(al momento ...) 😏 ',
      'changePassword': 'Cambia password',
      'notifications': 'Notifiche',
      'contentSettings': 'Impostazioni contenuto',
      'paymentHistory': 'Cronologia pagamenti',
      'aboutUs': 'Chi siamo',
      'versionCode': 'Codice versione: ',
      'close': 'Chiusura',
      'current': 'Attuale',
      'updatedFavs' : 'Preferiti aggiornati',
      'noFavsYet' : 'Non hai ancora preferiti!',
      'removedSuccesfully' : 'Rimosso con successo!',
      'betAmount': 'Importo della Scommessa',
      'originValue': 'Valore di Origine',
      'currentValue': 'Valore Attuale',
      'targetValue': 'Valore Obiettivo',
      'targetDate': 'Data Obiettivo',
      'targetMargin': 'Margine Obiettivo',
      'winBonus': 'Bonus di Vittoria',
      'betAmount': 'Wetteinsatz',
      'originValue': 'Ursprungswert',
      'currentValue': 'Aktueller Wert',
      'targetValue': 'Zielwert',
      'targetDate': 'Zieldatum',
      'targetMargin': 'Zielmarge',
      'winBonus': 'Gewinnbonus',
      'verify': 'Verifica Conto',
      'verified': 'Conto verificato!',
      'ranking': 'Classifica'
    },
    'de': {
      // Alemán
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
      'pleaseEnterCardHolderName':
          'Bitte geben Sie den Namen des Karteninhabers ein',
      'thisFieldIsRequired': 'Dieses Feld ist erforderlich',
      'enterValidEmail': 'Geben Sie eine gültige E-Mail-Adresse ein',
      'passwordsNotMatching': 'Passwörter stimmen nicht überein',
      'acceptTermsToContinue':
          'Akzeptieren Sie die Allgemeinen Geschäftsbedingungen, um fortzufahren',
      'notAvailable': 'Nicht verfügbar',
      'success': 'Erfolg!',
      'profilePictureUploadedSuccessfully':
          'Profilbild erfolgreich hochgeladen',
      'errorUploadingProfilePic':
          'Beim Hochladen des Profilbildes ist ein Fehler aufgetreten',
      'noInfoAvailable': 'Keine Informationen verfügbar!',
      'favs': 'Favoriten',
      'currentBalance': 'Aktueller saldo',
      'mostCommon': 'Am häufigsten',
      'totalBet': 'Gesamtwetteinsatz ',
      'liveBets': 'Trends',
      'recentBets': 'Letzte Wetten',
      'darkMode': 'Dunkler Modus',
      'attention': 'Achtung',
      'needToRestart':
          'Die Anwendung muss neu gestartet werden. Treten Sie erneut ein',
      'wallet': 'Meine Geldbörse',
      'staked': 'Gewettet',
      'indexes': 'Indizes',
      'shares': 'Unternehmensaktien',
      'commodities': 'Rohstoffe',
      'googleSignIn': 'Anmeldung mit Google',
      'appleSignIn': 'Anmeldung mit Apple ID',
      'commonSignIn': 'Allgemeine Anmeldung',
      'backToSocialsLogin': 'Zurück zum sozialen Login',
      'noLiveBets':
          'Sie haben derzeit keine Live-Wetten, gehen Sie zur Markt-Registerkarte, um eine neue zu erstellen.',
      'noClosedBets': 'Keine abgeschlossenen Wetten\n(bisher ...) 😏',
      'changePassword': 'Passwort ändern',
      'notifications': 'Benachrichtigungen',
      'contentSettings': 'Inhaltseinstellungen',
      'paymentHistory': 'Zahlungsverlauf',
      'aboutUs': 'Über uns',
      'versionCode': 'Version code: ',
      'close': 'Schlusskurs',
      'current': 'Aktuell',
      'updatedFavs' : 'Favoriten aktualisiert',
      'noFavsYet' : 'Sie haben noch keine Favoriten!',
      'removedSuccesfully' : 'Erfolgreich entfernt!',
      'verify': 'Konto bestätigen',
      'verified': 'Konto verifiziert!',
      'ranking': 'Rangliste'
    },
  };

  String? get menu => _localizedValues[locale.languageCode]?['menu'];
  String? get profile => _localizedValues[locale.languageCode]?['profile'];
  String? get home => _localizedValues[locale.languageCode]?['home'];
  String? get comingSoon =>
      _localizedValues[locale.languageCode]?['comingSoon'];
  String? get liveMarkets =>
      _localizedValues[locale.languageCode]?['liveMarkets'];
  String? get settings => _localizedValues[locale.languageCode]?['settings'];
  String? get fullName => _localizedValues[locale.languageCode]?['fullName'];
  String? get username => _localizedValues[locale.languageCode]?['username'];
  String? get email => _localizedValues[locale.languageCode]?['email'];
  String? get birthday => _localizedValues[locale.languageCode]?['birthday'];
  String? get address => _localizedValues[locale.languageCode]?['address'];
  String? get country => _localizedValues[locale.languageCode]?['country'];
  String? get lastSession =>
      _localizedValues[locale.languageCode]?['lastSession'];
  String? get logOut => _localizedValues[locale.languageCode]?['logOut'];
  String? get logIn => _localizedValues[locale.languageCode]?['logIn'];
  String? get forgotPassword =>
      _localizedValues[locale.languageCode]?['forgotPassword'];
  String? get exit => _localizedValues[locale.languageCode]?['exit'];
  String? get personalInfo =>
      _localizedValues[locale.languageCode]?['personalInfo'];
  String? get gender => _localizedValues[locale.languageCode]?['gender'];
  String? get continueText =>
      _localizedValues[locale.languageCode]?['continue'];
  String? get creditCard =>
      _localizedValues[locale.languageCode]?['creditCard'];
  String? get zipCode => _localizedValues[locale.languageCode]?['zipCode'];
  String? get back => _localizedValues[locale.languageCode]?['back'];
  String? get cardNumber =>
      _localizedValues[locale.languageCode]?['cardNumber'];
  String? get expireDate =>
      _localizedValues[locale.languageCode]?['expireDate'];
  String? get cardHolder =>
      _localizedValues[locale.languageCode]?['cardHolder'];
  String? get credentials =>
      _localizedValues[locale.languageCode]?['credentials'];
  String? get idCard => _localizedValues[locale.languageCode]?['idCard'];
  String? get password => _localizedValues[locale.languageCode]?['password'];
  String? get confirmPassword =>
      _localizedValues[locale.languageCode]?['confirmPassword'];
  String? get acceptTerms =>
      _localizedValues[locale.languageCode]?['acceptTerms'];
  String? get termsAndConditions =>
      _localizedValues[locale.languageCode]?['termsAndConditions'];
  String? get signIn => _localizedValues[locale.languageCode]?['signIn'];
  String? get pleaseEnterUsername =>
      _localizedValues[locale.languageCode]?['pleaseEnterUsername'];
  String? get pleaseEnterPassword =>
      _localizedValues[locale.languageCode]?['pleaseEnterPassword'];
  String? get connecting =>
      _localizedValues[locale.languageCode]?['connecting'];
  String? get registrationSuccessful =>
      _localizedValues[locale.languageCode]?['registrationSuccessful'];
  String? get pleaseEnterCardNumber =>
      _localizedValues[locale.languageCode]?['pleaseEnterCardNumber'];
  String? get enterDate => _localizedValues[locale.languageCode]?['enterDate'];
  String? get welcome => _localizedValues[locale.languageCode]?['welcome'];
  String? get pleaseEnterCVV =>
      _localizedValues[locale.languageCode]?['pleaseEnterCVV'];
  String? get pleaseEnterCardHolderName =>
      _localizedValues[locale.languageCode]?['pleaseEnterCardHolderName'];
  String? get thisFieldIsRequired =>
      _localizedValues[locale.languageCode]?['thisFieldIsRequired'];
  String? get enterValidEmail =>
      _localizedValues[locale.languageCode]?['enterValidEmail'];
  String? get passwordsNotMatching =>
      _localizedValues[locale.languageCode]?['passwordsNotMatching'];
  String? get acceptTermsToContinue =>
      _localizedValues[locale.languageCode]?['acceptTermsToContinue'];
  String? get notAvailable =>
      _localizedValues[locale.languageCode]?['notAvailable'];
  String? get success => _localizedValues[locale.languageCode]?['success'];
  String? get profilePictureUploadedSuccessfully =>
      _localizedValues[locale.languageCode]
          ?['profilePictureUploadedSuccessfully'];
  String? get errorUploadingProfilePic =>
      _localizedValues[locale.languageCode]?['errorUploadingProfilePic'];
  String? get noInfoAvailable =>
      _localizedValues[locale.languageCode]?['noInfoAvailable'];
  String? get favs => _localizedValues[locale.languageCode]?['favs'];
  String? get currentBalance =>
      _localizedValues[locale.languageCode]?['currentBalance'];
  String? get mostCommon =>
      _localizedValues[locale.languageCode]?['mostCommon'];
  String? get totalBet => _localizedValues[locale.languageCode]?['totalBet'];
  String? get recentBets =>
      _localizedValues[locale.languageCode]?['recentBets'];
  String? get darkMode => _localizedValues[locale.languageCode]?['darkMode'];
  String? get attention => _localizedValues[locale.languageCode]?['attention'];
  String? get needToRestart =>
      _localizedValues[locale.languageCode]?['needToRestart'];
  String? get liveBets => _localizedValues[locale.languageCode]?['liveBets'];
  String? get wallet => _localizedValues[locale.languageCode]?['wallet'];
  String? get staked => _localizedValues[locale.languageCode]?['staked'];
  String? get indexes => _localizedValues[locale.languageCode]?['indexes'];
  String? get shares => _localizedValues[locale.languageCode]?['shares'];
  String? get commodities =>
      _localizedValues[locale.languageCode]?['commodities'];
  String? get googleSignIn =>
      _localizedValues[locale.languageCode]?['googleSignIn'];
  String? get appleSignIn =>
      _localizedValues[locale.languageCode]?['appleSignIn'];
  String? get commonSignIn =>
      _localizedValues[locale.languageCode]?['commonSignIn'];
  String? get backToSocialsLogin =>
      _localizedValues[locale.languageCode]?['backToSocialsLogin'];
  String? get noLiveBets =>
      _localizedValues[locale.languageCode]?['noLiveBets'];
  String? get noClosedBets =>
      _localizedValues[locale.languageCode]?['noClosedBets'];
  String? get changePassword =>
      _localizedValues[locale.languageCode]?['changePassword'];
  String? get notifications =>
      _localizedValues[locale.languageCode]?['notifications'];
  String? get contentSettings =>
      _localizedValues[locale.languageCode]?['contentSettings'];
  String? get paymentHistory =>
      _localizedValues[locale.languageCode]?['paymentHistory'];
  String? get aboutUs => _localizedValues[locale.languageCode]?['aboutUs'];
  String? get versionCode =>
      _localizedValues[locale.languageCode]?['versionCode'];
  String? get close =>
      _localizedValues[locale.languageCode]?['close'];
  String? get current =>
      _localizedValues[locale.languageCode]?['current'];
  String? get updatedFavs =>
      _localizedValues[locale.languageCode]?['updatedFavs'];
  String? get noFavsYet =>
      _localizedValues[locale.languageCode]?['noFavsYet'];
  String? get removedSuccesfully =>
      _localizedValues[locale.languageCode]?['removedSuccesfully'];
  String? get betAmount =>
      _localizedValues[locale.languageCode]?['betAmount'];
  String? get originValue =>
      _localizedValues[locale.languageCode]?['originValue'];
  String? get currentValue =>
      _localizedValues[locale.languageCode]?['currentValue'];
  String? get targetValue =>
      _localizedValues[locale.languageCode]?['targetValue'];
  String? get targetDate =>
      _localizedValues[locale.languageCode]?['targetDate'];
  String? get targetMargin =>
      _localizedValues[locale.languageCode]?['targetMargin'];
  String? get winBonus =>
      _localizedValues[locale.languageCode]?['winBonus'];
  String? get verify =>
      _localizedValues[locale.languageCode]?['verify'];
  String? get verified =>
      _localizedValues[locale.languageCode]?['verified'];
  String? get ranking =>
      _localizedValues[locale.languageCode]?['ranking'];
}

class LocalizedStringsDelegate extends LocalizationsDelegate<LocalizedStrings> {
  const LocalizedStringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'es', 'fr', 'it', 'de'].contains(locale.languageCode);

  @override
  Future<LocalizedStrings> load(Locale locale) async {
    return LocalizedStrings(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<LocalizedStrings> old) => false;
}
