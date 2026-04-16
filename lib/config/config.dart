class Config {
  static const String publicDomain = 'api.betstrading.online';
  static const String landingPage = 'https://betstrading.online';
  static const String statusPage = 'https://api.betstrading.online/status';

  static const String instagramPage = 'https://www.instagram.com/betstrading/';
  static const String stripePublicKey = 'pk_test_51Ro4wcIoWhLn7aPbiJW4oRV3Gtvyijmw9hSGkn7pVMcOYZ4wpKmjRX1SA4tDPlJa8iKS1iRD5edE894KWgrRkqnM007ZLfNfKr'; //TEST
  static const String termsNConditionsPage = 'https://raw.githubusercontent.com/jesusramondovale/BetsTrading-Client/refs/heads/android-master/policies/privacy_policy_en.md';
  static const String codeVersion = '26.106.1';
  static const String admobAppId = 'ca-app-pub-2465898294053562/1629478765';
  static const String admobAdToken = 'ca-app-pub-2465898294053562/4804536511'; // REAL
  /// Intersticial obligatorio (apuestas / umbral API / daily reward).
  static const String admobInterstitialMandatoryId =
      'ca-app-pub-2465898294053562/3036757295';
  //static const String admobAdToken = 'ca-app-pub-3940256099942544/5224354917'; //TEST
  static const String ipGeolocalizerToken = 'd99daa2befa6f8';
  static const String serverCertificateHash = 'E475D88044C231E073B0B4F40B124D496FF01B0D0A964A26D458BFA9BC2BF249';
  static const String serverClientId = '1020559524014-ge0t5b3bhkpdpg8h958b4rf8o716l12r.apps.googleusercontent.com';

  // DEV
  static const double priceSimulation = 200.0;

  //TODO -> Values to be fetched from backend
  static const int priceBetPrize = 100000;
  static const int topUsersCount = 10;
  static const List<String> top10Rewards = [
    r'+2.000', r'+1.300', r'+1.000', r'+650', r'+400',
    r'+300', r'+200', r'+150', r'+100', r'+50',
  ];
}