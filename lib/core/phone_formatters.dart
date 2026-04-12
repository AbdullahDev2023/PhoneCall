import 'package:intl/intl.dart';

String normalizedDigits(String input) {
  return input.replaceAll(RegExp(r'[^0-9+]'), '');
}

String formatPhoneNumber(String input) {
  final value = normalizedDigits(input);
  if (value.isEmpty) {
    return '';
  }
  if (value.startsWith('+') && value.length > 3) {
    return '${value.substring(0, 3)} ${_groupDigits(value.substring(3))}'
        .trim();
  }
  return _groupDigits(value);
}

String _groupDigits(String input) {
  final buffer = StringBuffer();
  for (var index = 0; index < input.length; index++) {
    if (index > 0 && index % 3 == 0) {
      buffer.write(' ');
    }
    buffer.write(input[index]);
  }
  return buffer.toString();
}

String initialsForName(String value) {
  final parts =
      value
          .trim()
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .toList();
  if (parts.isEmpty) {
    return '#';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

String formatTimestamp(int timestampMillis) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final startOfThatDay = DateTime(date.year, date.month, date.day);
  final difference = startOfToday.difference(startOfThatDay).inDays;

  if (difference == 0) {
    return DateFormat.jm().format(date);
  }
  if (difference == 1) {
    return 'Yesterday';
  }
  if (difference < 7) {
    return DateFormat.E().format(date);
  }
  return DateFormat.MMMd().format(date);
}

String formatDuration(int durationSeconds) {
  if (durationSeconds <= 0) {
    return '0s';
  }
  final minutes = durationSeconds ~/ 60;
  final seconds = durationSeconds % 60;
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;

  if (hours > 0) {
    return '${hours}h ${remainingMinutes}m';
  }
  if (minutes > 0) {
    return '${minutes}m ${seconds}s';
  }
  return '${seconds}s';
}

bool matchesT9(String source, String digits) {
  final cleanedDigits = normalizedDigits(digits);
  if (cleanedDigits.isEmpty) {
    return true;
  }

  final t9 = source
      .toLowerCase()
      .split('')
      .map(_mapCharacterToDigit)
      .join()
      .replaceAll('0', '');

  return t9.contains(cleanedDigits);
}

String _mapCharacterToDigit(String value) {
  if ('abc'.contains(value)) {
    return '2';
  }
  if ('def'.contains(value)) {
    return '3';
  }
  if ('ghi'.contains(value)) {
    return '4';
  }
  if ('jkl'.contains(value)) {
    return '5';
  }
  if ('mno'.contains(value)) {
    return '6';
  }
  if ('pqrs'.contains(value)) {
    return '7';
  }
  if ('tuv'.contains(value)) {
    return '8';
  }
  if ('wxyz'.contains(value)) {
    return '9';
  }
  if (RegExp(r'[0-9]').hasMatch(value)) {
    return value;
  }
  return '0';
}
