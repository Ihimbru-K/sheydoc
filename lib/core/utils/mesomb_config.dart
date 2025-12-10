
class MeSombConfig {

  static const String applicationKey = 'MobileAppKey';
  static const String accessKey = '270bb91d-da09-4560-90cf-58a82b115cf7';
  static const String secretKey = 'f4941e90-a40e-4a3a-9ded-2b67423e5d60';


  static const String mtnService = 'MTN';
  static const String orangeService = 'ORANGE';

  // Cameroon country code
  static const String countryCode = '+237';


  static bool isConfigured() {
    return applicationKey != 'MobileAppKey' &&
        accessKey != '270bb91d-da09-4560-90cf-58a82b115cf7' &&
        secretKey != 'f4941e90-a40e-4a3a-9ded-2b67423e5d60';
  }


  static String formatPhoneNumber(String phone) {
    String formatted = phone.replaceAll(' ', '').replaceAll('-', '');

    // Remove country code if present
    if (formatted.startsWith('+237')) {
      formatted = formatted.substring(4);
    } else if (formatted.startsWith('237')) {
      formatted = formatted.substring(3);
    } else if (formatted.startsWith('0')) {
      formatted = formatted.substring(1);
    }

    return formatted;
  }

  /// Validate Cameroon phone number
  static bool isValidCameroonNumber(String phone) {
    final formatted = formatPhoneNumber(phone);
    // Cameroon numbers are 9 digits and start with 6
    return formatted.length == 9 && formatted.startsWith('6');
  }
}