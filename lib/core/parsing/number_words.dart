class SpokenNumberParser {
  static const Map<String, int> _unitsAndTeens = {
    'zero': 0,
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
  };

  static const Map<String, int> _tens = {
    'twenty': 20,
    'thirty': 30,
    'forty': 40,
    'fourty': 40, // common typo/asr
    'fifty': 50,
    'sixty': 60,
    'seventy': 70,
    'eighty': 80,
    'ninety': 90,
  };

  /// Normalizes a phrase and extracts a list of numbers (as doubles).
  /// E.g. "120 over 80" -> [120.0, 80.0]
  /// E.g. "one twenty over eighty" -> [120.0, 80.0]
  /// E.g. "thirty six point five" -> [36.5]
  /// E.g. "glucose 120" -> [120.0]
  static List<double> extractNumbers(String input) {
    if (input.trim().isEmpty) return [];

    // Pre-clean input
    String text = input.toLowerCase();

    // Replace slashes or dashes used as separators with spaces or 'over'
    // E.g. 120/80 -> 120 over 80
    text = text.replaceAll('/', ' over ');
    text = text.replaceAll('-', ' ');
    text = text.replaceAll(',', ' ');

    // Normalize words
    final rawTokens = text
        .split(RegExp(r'\s+'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    // Group tokens around splitters like "over", "by", "slash", or distinct number clusters
    final segments = <List<String>>[];
    List<String> currentSegment = [];

    for (final token in rawTokens) {
      if (token == 'over' || token == 'by' || token == 'slash') {
        if (currentSegment.isNotEmpty) {
          segments.add(currentSegment);
          currentSegment = [];
        }
      } else {
        currentSegment.add(token);
      }
    }
    if (currentSegment.isNotEmpty) {
      segments.add(currentSegment);
    }

    final numbers = <double>[];
    for (final seg in segments) {
      final parsed = _parseSegment(seg);
      numbers.addAll(parsed);
    }

    return numbers;
  }

  static List<double> _parseSegment(List<String> tokens) {
    final result = <double>[];
    int i = 0;

    while (i < tokens.length) {
      // 1. Direct numeric check (e.g., "120", "36.5")
      final numDirect = double.tryParse(tokens[i]);
      if (numDirect != null) {
        // Check if next token is "point" or "dot" followed by a number
        if (i + 2 < tokens.length && (tokens[i + 1] == 'point' || tokens[i + 1] == 'dot')) {
          final frac = double.tryParse(tokens[i + 2]) ??
              _unitsAndTeens[tokens[i + 2]]?.toDouble();
          if (frac != null) {
            result.add(numDirect + (frac / 10.0));
            i += 3;
            continue;
          }
        }
        result.add(numDirect);
        i++;
        continue;
      }

      // 2. Check for spoken number starting at i
      final parsedGroup = _tryConsumeNumber(tokens, i);
      if (parsedGroup != null) {
        result.add(parsedGroup.value);
        i = parsedGroup.nextIndex;
      } else {
        // Skip non-number token (e.g. "degrees", "bpm", "mg/dl", filler words)
        i++;
      }
    }

    return result;
  }

  static _ParseResult? _tryConsumeNumber(List<String> tokens, int startIndex) {
    if (startIndex >= tokens.length) return null;

    int idx = startIndex;
    bool hasDecimals = false;
    double integerPart = 0;
    double decimalPart = 0;
    int decimalPlaces = 0;

    // Collect numeric tokens
    final numberTokens = <String>[];

    while (idx < tokens.length) {
      final token = tokens[idx];

      if (token == 'and') {
        // Skip 'and' in 'one hundred and twenty'
        idx++;
        continue;
      }

      if (token == 'point' || token == 'dot') {
        hasDecimals = true;
        idx++;
        // parse decimal digits
        while (idx < tokens.length) {
          final decToken = tokens[idx];
          final val = _unitsAndTeens[decToken] ?? int.tryParse(decToken);
          if (val != null && val >= 0 && val <= 9) {
            decimalPlaces++;
            decimalPart = decimalPart * 10 + val;
            idx++;
          } else {
            break;
          }
        }
        break;
      }

      if (_isNumericWord(token) || double.tryParse(token) != null) {
        numberTokens.add(token);
        idx++;
      } else {
        break;
      }
    }

    if (numberTokens.isEmpty && decimalPlaces == 0) {
      return null;
    }

    if (numberTokens.isNotEmpty) {
      integerPart = _evalIntegerTokens(numberTokens);
    }

    double finalValue = integerPart;
    if (hasDecimals && decimalPlaces > 0) {
      double divisor = 1;
      for (int k = 0; k < decimalPlaces; k++) {
        divisor *= 10;
      }
      finalValue += (decimalPart / divisor);
    }

    return _ParseResult(finalValue, idx);
  }

  static bool _isNumericWord(String token) {
    return _unitsAndTeens.containsKey(token) ||
        _tens.containsKey(token) ||
        token == 'hundred' ||
        token == 'thousand';
  }

  static double _evalIntegerTokens(List<String> tokens) {
    // If it's a single raw number token:
    if (tokens.length == 1) {
      final n = double.tryParse(tokens.first);
      if (n != null) return n;
    }

    // Handle compound cases like:
    // ["one", "twenty"] -> 120
    // ["one", "twenty", "five"] -> 125
    // ["two", "ten"] -> 210
    // ["one", "hundred", "twenty"] -> 120
    // ["seventy", "two"] -> 72
    // ["ninety", "eight"] -> 98

    // Special conversational shorthand: "one twenty" = 100 + 20 = 120, "one thirty" = 130
    if (tokens.length >= 2 &&
        _unitsAndTeens.containsKey(tokens[0]) &&
        _unitsAndTeens[tokens[0]]! >= 1 &&
        _unitsAndTeens[tokens[0]]! <= 9 &&
        _tens.containsKey(tokens[1])) {
      final hundreds = _unitsAndTeens[tokens[0]]! * 100;
      final tensVal = _tens[tokens[1]]!;
      double total = (hundreds + tensVal).toDouble();
      if (tokens.length >= 3 && _unitsAndTeens.containsKey(tokens[2])) {
        total += _unitsAndTeens[tokens[2]]!;
      }
      return total;
    }

    // Standard word parsing
    double current = 0;
    double total = 0;

    for (final token in tokens) {
      final rawNum = double.tryParse(token);
      if (rawNum != null) {
        current += rawNum;
        continue;
      }

      if (_unitsAndTeens.containsKey(token)) {
        current += _unitsAndTeens[token]!;
      } else if (_tens.containsKey(token)) {
        current += _tens[token]!;
      } else if (token == 'hundred') {
        current = (current == 0 ? 1 : current) * 100;
      } else if (token == 'thousand') {
        current = (current == 0 ? 1 : current) * 1000;
        total += current;
        current = 0;
      }
    }

    total += current;
    return total;
  }
}

class _ParseResult {
  final double value;
  final int nextIndex;

  _ParseResult(this.value, this.nextIndex);
}

