class Validators {
  Validators._();

  static String? validateParcelNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a parcel number';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Parcel number must be at least 2 characters';
    }
    if (trimmed.length > 20) {
      return 'Parcel number must be less than 20 characters';
    }
    return null;
  }

  static String? validateOwnerName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an owner name';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (trimmed.length > 100) {
      return 'Name must be less than 100 characters';
    }
    return null;
  }

  static String? validateBlockNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a block number';
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Please enter a block number';
    }
    return null;
  }

  static String? validateCommunity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a community name';
    }
    return null;
  }

  static String? validateCoordinates(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    final trimmed = value.trim();
    final parsed = double.tryParse(trimmed);
    if (parsed == null) {
      return 'Please enter a valid number for $fieldName';
    }
    return null;
  }

  static bool isValidParcelNumber(String value) {
    return validateParcelNumber(value) == null;
  }

  static bool isValidOwnerName(String value) {
    return validateOwnerName(value) == null;
  }

  static String sanitizeSearchInput(String input) {
    return input.trim().replaceAll(RegExp(r'[<>"''%;()&+]'), '');
  }
}
