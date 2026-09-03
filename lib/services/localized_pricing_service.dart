import 'dart:ui';
import 'package:flutter/foundation.dart';

/// Dynamic Localized Pricing Service
/// Automatically detects user's device country/locale and formats real-world pricing
/// for In-App Purchases (Remove Ads, VIP Passes, etc.).
class LocalizedPricingService {
  static final LocalizedPricingService _instance =
      LocalizedPricingService._internal();
  factory LocalizedPricingService() => _instance;
  LocalizedPricingService._internal();

  /// Gets the player's 2-letter country code from the device (e.g. 'IN', 'US', 'GB', 'DE')
  static String get userCountryCode {
    try {
      final locale = PlatformDispatcher.instance.locale;
      return locale.countryCode?.toUpperCase() ?? 'US';
    } catch (_) {
      return 'US';
    }
  }

  /// Returns dynamically localized price string for the "Remove Ads VIP Pass"
  static String get removeAdsPriceString {
    final country = userCountryCode;

    switch (country) {
      case 'IN': // India
        return '₹99';
      case 'US': // United States
        return '\$0.99';
      case 'GB': // United Kingdom
        return '£0.89';
      case 'DE': // Germany
      case 'FR': // France
      case 'IT': // Italy
      case 'ES': // Spain
      case 'NL': // Netherlands
      case 'PT': // Portugal
      case 'AT': // Austria
      case 'BE': // Belgium
      case 'IE': // Ireland
      case 'FI': // Finland
      case 'GR': // Greece
        return '€0.99';
      case 'JP': // Japan
        return '¥150';
      case 'CA': // Canada
        return 'CA\$1.39';
      case 'AU': // Australia
        return 'AU\$1.49';
      case 'BR': // Brazil
        return 'R\$4.90';
      case 'MX': // Mexico
        return 'MX\$19';
      case 'ID': // Indonesia
        return 'Rp 16,000';
      case 'PH': // Philippines
        return '₱59';
      case 'VN': // Vietnam
        return '₫25,000';
      case 'KR': // South Korea
        return '₩1,500';
      case 'SA': // Saudi Arabia
      case 'AE': // UAE
        return '3.99 AED';
      case 'TR': // Turkey
        return '₺29.99';
      default:
        return '\$0.99';
    }
  }
}
