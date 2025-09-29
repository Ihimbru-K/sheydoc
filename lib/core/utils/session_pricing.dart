class SessionPricing {
  static const double basePrice = 3000.0;
  static const double pricePer15MinBlock = 750.0;

  static double calculatePrice(int durationMinutes) {
    if (durationMinutes <= 30) return basePrice;
    final additionalMinutes = durationMinutes - 30;
    final additionalBlocks = (additionalMinutes / 15).ceil();
    return basePrice + (additionalBlocks * pricePer15MinBlock);
  }
}