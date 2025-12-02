/// constants.dart - Application constants and reference data
///
/// Part of AgriFlow - Irish Cattle Portfolio Management
library;

// 32 Irish Counties
const List<String> irishCounties = [
  'Antrim',
  'Armagh',
  'Carlow',
  'Cavan',
  'Clare',
  'Cork',
  'Derry',
  'Donegal',
  'Down',
  'Dublin',
  'Fermanagh',
  'Galway',
  'Kerry',
  'Kildare',
  'Kilkenny',
  'Laois',
  'Leitrim',
  'Limerick',
  'Longford',
  'Louth',
  'Mayo',
  'Meath',
  'Monaghan',
  'Offaly',
  'Roscommon',
  'Sligo',
  'Tipperary',
  'Tyrone',
  'Waterford',
  'Westmeath',
  'Wexford',
  'Wicklow',
];

/// App version
const String appVersion = '1.0.0';

/// Firestore collection names
const String portfoliosCollection = 'portfolios';
const String pricePulsesCollection = 'price_pulses';
const String usersCollection = 'users';
const String preferencesCollection = 'preferences';

/// Weight bucket display names
const Map<String, String> weightBucketNames = {
  'w400_500': '400-500 kg',
  'w500_600': '500-600 kg',
  'w600_700': '600-700 kg',
  'w700_plus': '700+ kg',
};

/// Default values
const double defaultDesiredPrice = 4.20;
const int defaultQuantity = 30;
const String defaultCounty = 'Cork';

// NOTE: County median prices are fetched dynamically from PricePulseService.
// DO NOT hardcode price data here. Use:
//   await pricePulseService.getCountyPrices(breed: ..., weightBucket: ...)
