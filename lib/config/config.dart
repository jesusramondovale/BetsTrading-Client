class Config {


  static const PUBLIC_DOMAIN = 'api.betstrading.online';
  static const LANDING_PAGE = 'https://betstrading.online';
  static const INSTAGRAM_PAGE = 'https://www.instagram.com/betstrading/';
  static const STRIPE_PUBLIC_KEY = 'pk_test_51Ro4wcIoWhLn7aPbiJW4oRV3Gtvyijmw9hSGkn7pVMcOYZ4wpKmjRX1SA4tDPlJa8iKS1iRD5edE894KWgrRkqnM007ZLfNfKr'; //TEST
  static const TERMS_N_CONDITIONS_PAGE = 'https://raw.githubusercontent.com/jesusramondovale/BetsTrading-Client/refs/heads/android-master/policies/privacy_policy_en.md';
  static const CODE_VERSION = '25.315.1';
  static const ADMOB_APP_ID = 'ca-app-pub-2465898294053562/1629478765';
  static const ADMOB_AD_TOKEN = 'ca-app-pub-2465898294053562/4804536511'; // REAL
  //static const ADMOB_AD_TOKEN = 'ca-app-pub-3940256099942544/5224354917'; //TEST
  static const IP_GEOLOCALIZER_TOKEN = 'd99daa2befa6f8';
  static const SERVER_CERTIFICATE_HASH = 'E475D88044C231E073B0B4F40B124D496FF01B0D0A964A26D458BFA9BC2BF249';
  static const SERVER_CLIENT_ID = '1020559524014-ge0t5b3bhkpdpg8h958b4rf8o716l12r.apps.googleusercontent.com';
  static const KYC_API_BASE_URL = 'https://verify.didit.me/es/session/AhhJH5Rk2w0L?step=start';

  // DEV
  static const PRICE_SIMULATION = 200.0;

  //TODO -> Values to be fetched from backend
  static const PRICE_BET_PRIZE = 100000;
  static const List<String> TOP5_REWARDS_USD = [r'+$2,500', r'+$1,500', r'+$1,000', r'+$750', r'+$500'];
  static const List<String> TOP5_REWARDS_EUR = [r'+2.000€', r'+1.300€', r'+1.000€', r'+650€', r'+400€'];
}