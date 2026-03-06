class TypeUtils {
  /// Safely parses an integer from a dynamic value.
  /// Handles [int], [String], and [null].
  static int? parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  /// Safely parses an integer with a fallback value.
  static int parseIntRequired(dynamic value, {int fallback = 0}) {
    return parseInt(value) ?? fallback;
  }
}
