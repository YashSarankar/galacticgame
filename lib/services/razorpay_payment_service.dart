import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Service managing Razorpay payment gateway integration for VIP Pass & In-App Purchases
class RazorpayPaymentService {
  static const String testKeyId = 'rzp_test_jX0oGdLK69tv2V';

  Razorpay? _razorpay;
  void Function(String paymentId)? _onSuccessCallback;
  void Function(String message)? _onFailureCallback;

  void init() {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final paymentId = response.paymentId ?? 'pay_test_success';
    debugPrint('Razorpay Payment Success: $paymentId');
    _onSuccessCallback?.call(paymentId);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    final message = response.message ?? 'Payment cancelled or failed';
    debugPrint('Razorpay Payment Error: Code: ${response.code} | Message: $message');
    _onFailureCallback?.call(message);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('Razorpay External Wallet: ${response.walletName}');
    // External wallet redirect treated as success for testing
    _onSuccessCallback?.call('wallet_${response.walletName}');
  }

  /// Opens the Razorpay checkout interface for VIP Commander Lifetime Pass
  void startVipPassPayment({
    required void Function(String paymentId) onSuccess,
    required void Function(String error) onFailure,
    int amountInPaise = 9900, // ₹99 = 9900 paise
  }) {
    _onSuccessCallback = onSuccess;
    _onFailureCallback = onFailure;

    // If running on desktop/web/simulator where native SDK is unavailable, simulate test payment
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      debugPrint('Non-mobile platform detected. Simulating test payment response...');
      Future.delayed(const Duration(milliseconds: 600), () {
        onSuccess('simulated_test_pay_${DateTime.now().millisecondsSinceEpoch}');
      });
      return;
    }

    if (_razorpay == null) {
      init();
    }

    final options = {
      'key': testKeyId,
      'amount': amountInPaise,
      'name': 'Galactic Merge Tycoon',
      'description': 'VIP Commander Lifetime License',
      'timeout': 300,
      'theme': {
        'color': '#00F0FF',
      },
      'prefill': {
        'contact': '9876543210',
        'email': 'commander@galacticgame.com',
      },
      'send_sms_hash': true,
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      debugPrint('Error opening Razorpay checkout: $e');
      onFailure('Failed to open payment sheet: $e');
    }
  }
}
