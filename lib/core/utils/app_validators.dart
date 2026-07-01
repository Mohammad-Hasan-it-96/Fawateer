import 'num_input.dart';

class AppValidators {
  static String? Function(String?) required(String message) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return message;
      }
      return null;
    };
  }

  /// Validator for a required price: must be present, a valid finite number, and
  /// not negative. Messages are passed in so they can be localized by the caller.
  static String? Function(String?) price({
    required String requiredMsg,
    required String invalidMsg,
    required String negativeMsg,
  }) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) return requiredMsg;
      final v = NumInput.parseFlexibleNumber(value);
      if (v == null) return invalidMsg; // non-numeric or non-finite
      if (v < 0) return negativeMsg;
      return null;
    };
  }

  /// Validator for an optional numeric field (cost / quantity / low-stock).
  /// Empty is allowed (treated as 0 downstream); a non-empty value must be a
  /// valid finite, non-negative number.
  static String? Function(String?) optionalNonNegative({
    required String invalidMsg,
    required String negativeMsg,
  }) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) return null;
      final v = NumInput.parseFlexibleNumber(value);
      if (v == null) return invalidMsg;
      if (v < 0) return negativeMsg;
      return null;
    };
  }
}
