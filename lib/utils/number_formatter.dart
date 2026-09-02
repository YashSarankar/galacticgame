/// Utility class for formatting idle game numbers and time durations.
class NumberFormatter {

  static const List<String> _suffixes = [
    '',
    'K', // Thousand (10^3)
    'M', // Million (10^6)
    'B', // Billion (10^9)
    'T', // Trillion (10^12)
    'Qa', // Quadrillion (10^15)
    'Qi', // Quintillion (10^18)
    'Sx', // Sextillion (10^21)
    'Sp', // Septillion (10^24)
    'Oc', // Octillion (10^27)
    'No', // Nonillion (10^30)
    'Dc', // Decillion (10^33)
    'Ud', // Undecillion (10^36)
    'Dd', // Duodecillion (10^39)
    'Td', // Tredecillion (10^42)
    'Qad', // Quattuordecillion (10^45)
    'Qid', // Quindecillion (10^48)
    'Sxd', // Sexdecillion (10^51)
    'Spd', // Septendecillion (10^54)
    'Ocd', // Octodecillion (10^57)
    'Nod', // Novemdecillion (10^60)
    'Vg', // Vigintillion (10^63)
  ];

  /// Formats currency with engineering / idle game abbreviations.
  static String formatCurrency(num value, {int decimals = 2}) {
    if (value.isNaN || value.isInfinite) return '0.00';
    final double val = value.toDouble();
    if (val < 0) return '-${formatCurrency(-val, decimals: decimals)}';
    if (val < 1000) {
      if (val == val.roundToDouble()) {
        return val.toInt().toString();
      }
      return val.toStringAsFixed(decimals);
    }

    int tier = 0;
    double scaled = val;
    while (scaled >= 1000.0 && tier < _suffixes.length - 1) {
      scaled /= 1000.0;
      tier++;
    }

    final String formatted = scaled.toStringAsFixed(decimals);
    return '$formatted${_suffixes[tier]}';

  }

  /// Formats currency with a leading dollar sign.
  static String formatCredits(num value, {int decimals = 2}) {
    return '\$${formatCurrency(value, decimals: decimals)}';
  }

  /// Formats Dark Matter / Gems.
  static String formatDarkMatter(num value) {
    return '${formatCurrency(value, decimals: 1)} DM';
  }

  /// Formats a duration into MM:SS or HH:MM:SS.
  static String formatDuration(Duration duration) {
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
  }

  /// Formats seconds to a compact string.
  static String formatSeconds(int totalSeconds) {
    return formatDuration(Duration(seconds: totalSeconds));
  }
}
